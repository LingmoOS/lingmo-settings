/*
 * Copyright (C) 2026 LingmoOS Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "fingerprint.h"

#include <QDBusArgument>
#include <QDBusObjectPath>
#include <QDBusPendingCallWatcher>
#include <QDebug>
#include <QFileInfo>
#include <QProcess>

namespace {
const QString Service = QStringLiteral("net.reactivated.Fprint");
const QString ManagerPath = QStringLiteral("/net/reactivated/Fprint/Manager");
const QString ManagerInterface = QStringLiteral("net.reactivated.Fprint.Manager");
const QString DeviceInterface = QStringLiteral("net.reactivated.Fprint.Device");
const QString ErrorPrefix = QStringLiteral("net.reactivated.Fprint.Error.");
const QString DefaultPamHelper = QStringLiteral("/usr/lib/lingmo-settings/fingerprint-pam");

// Claim and deletion can wait for a polkit prompt.
const int InteractiveTimeout = 120 * 1000;

// pkexec exit codes
const int PkexecDismissed = 126;
const int PkexecNotAuthorized = 127;
}

Fingerprint::Fingerprint(QObject *parent)
    : QObject(parent)
{
    refresh();
}

Fingerprint::~Fingerprint()
{
    // Don't leave the reader claimed; fprintd also releases it when we leave the bus.
    if (m_devicePath.isEmpty() || !m_claimed)
        return;

    auto send = [this](const QString &method) {
        QDBusMessage msg = QDBusMessage::createMethodCall(Service, m_devicePath, DeviceInterface, method);
        bus().call(msg, QDBus::NoBlock);
    };
    if (m_enrollStarted)
        send(QStringLiteral("EnrollStop"));
    send(QStringLiteral("Release"));
}

QDBusConnection Fingerprint::bus() const
{
    if (qEnvironmentVariable("LINGMO_FPRINT_BUS") == QLatin1String("session"))
        return QDBusConnection::sessionBus();
    return QDBusConnection::systemBus();
}

void Fingerprint::callAsync(const QString &path, const QString &interface, const QString &method,
                            const QVariantList &args, const Callback &callback, int timeout)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(Service, path, interface, method);
    msg.setArguments(args);
    // fprintd checks polkit; let it ask for a password when the policy says so.
    msg.setInteractiveAuthorizationAllowed(true);

    auto *watcher = new QDBusPendingCallWatcher(bus().asyncCall(msg, timeout), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [callback](QDBusPendingCallWatcher *w) {
        const QDBusMessage reply = w->reply();
        w->deleteLater();
        if (callback)
            callback(reply);
    });
}

void Fingerprint::deviceCall(const QString &method, const QVariantList &args, const Callback &callback, int timeout)
{
    callAsync(m_devicePath, DeviceInterface, method, args, callback, timeout);
}

void Fingerprint::refresh()
{
    if (m_enrolling || m_busy)
        return;

    const int generation = ++m_generation;

    callAsync(ManagerPath, ManagerInterface, QStringLiteral("GetDefaultDevice"), {},
              [this, generation](const QDBusMessage &reply) {
        if (generation != m_generation)
            return;

        if (reply.type() == QDBusMessage::ErrorMessage) {
            // An fprintd error (NoSuchDevice) means the service runs but there is no reader;
            // anything else (ServiceUnknown, ...) means fprintd isn't there.
            m_serviceAvailable = reply.errorName().startsWith(ErrorPrefix);
            if (!m_serviceAvailable)
                qDebug() << "fprintd not available:" << reply.errorName() << reply.errorMessage();
            m_devicePath.clear();
            m_deviceName.clear();
            m_ready = true;
            Q_EMIT stateChanged();
            setEnrolledFingers({});
            return;
        }

        m_serviceAvailable = true;
        loadDevice(qvariant_cast<QDBusObjectPath>(reply.arguments().value(0)).path());
    });

    refreshPam();
}

void Fingerprint::loadDevice(const QString &path)
{
    m_devicePath = path;

    callAsync(path, QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("GetAll"),
              {DeviceInterface}, [this, path](const QDBusMessage &reply) {
        if (path != m_devicePath)
            return;

        QVariantMap props;
        if (reply.type() == QDBusMessage::ReplyMessage && !reply.arguments().isEmpty())
            props = qdbus_cast<QVariantMap>(reply.arguments().constFirst());

        m_deviceName = props.value(QStringLiteral("name")).toString();
        m_swipe = props.value(QStringLiteral("scan-type")).toString() == QLatin1String("swipe");
        m_enrollStages = props.value(QStringLiteral("num-enroll-stages"), -1).toInt();
        m_ready = true;
        Q_EMIT stateChanged();

        loadEnrolledFingers();
    });
}

void Fingerprint::loadEnrolledFingers()
{
    if (m_devicePath.isEmpty()) {
        setEnrolledFingers({});
        return;
    }

    // An empty user name means the caller.
    deviceCall(QStringLiteral("ListEnrolledFingers"), {QString()}, [this](const QDBusMessage &reply) {
        if (reply.type() == QDBusMessage::ErrorMessage) {
            if (reply.errorName() != ErrorPrefix + QLatin1String("NoEnrolledPrints"))
                qDebug() << "ListEnrolledFingers failed:" << reply.errorName() << reply.errorMessage();
            setEnrolledFingers({});
            return;
        }
        setEnrolledFingers(reply.arguments().value(0).toStringList());
    });
}

void Fingerprint::setEnrolledFingers(const QStringList &fingers)
{
    // Keep our display order.
    QStringList sorted;
    for (const QString &finger : allFingers()) {
        if (fingers.contains(finger))
            sorted << finger;
    }

    if (sorted != m_enrolledFingers) {
        m_enrolledFingers = sorted;
        Q_EMIT enrolledFingersChanged();
    }
}

void Fingerprint::setBusy(bool busy)
{
    if (m_busy != busy) {
        m_busy = busy;
        Q_EMIT busyChanged();
    }
}

void Fingerprint::claimAnd(const std::function<void()> &next, const std::function<void(const QString &)> &failed)
{
    if (m_claimed) {
        next();
        return;
    }

    deviceCall(QStringLiteral("Claim"), {QString()}, [this, next, failed](const QDBusMessage &reply) {
        if (reply.type() == QDBusMessage::ErrorMessage) {
            qDebug() << "Claim failed:" << reply.errorName() << reply.errorMessage();
            failed(errorText(reply));
            return;
        }
        m_claimed = true;
        next();
    }, InteractiveTimeout);
}

void Fingerprint::release(const std::function<void()> &next)
{
    if (!m_claimed) {
        if (next)
            next();
        return;
    }

    deviceCall(QStringLiteral("Release"), {}, [this, next](const QDBusMessage &reply) {
        if (reply.type() == QDBusMessage::ErrorMessage)
            qDebug() << "Release failed:" << reply.errorName() << reply.errorMessage();
        m_claimed = false;
        if (next)
            next();
    });
}

void Fingerprint::connectEnrollSignal(bool connect)
{
    if (m_devicePath.isEmpty())
        return;

    if (connect) {
        bus().connect(Service, m_devicePath, DeviceInterface, QStringLiteral("EnrollStatus"),
                      this, SLOT(onEnrollStatus(QString, bool)));
    } else {
        bus().disconnect(Service, m_devicePath, DeviceInterface, QStringLiteral("EnrollStatus"),
                         this, SLOT(onEnrollStatus(QString, bool)));
    }
}

void Fingerprint::startEnroll(const QString &finger)
{
    if (m_devicePath.isEmpty() || m_enrolling || m_busy || !allFingers().contains(finger))
        return;

    m_enrolling = true;
    m_enrollStarted = false;
    m_enrollFinger = finger;
    m_enrollStagesDone = 0;
    Q_EMIT enrollingChanged();
    Q_EMIT enrollProgressChanged();

    connectEnrollSignal(true);

    claimAnd([this, finger] {
        if (!m_enrolling) {
            // Cancelled while we were waiting for the claim.
            release();
            return;
        }

        deviceCall(QStringLiteral("EnrollStart"), {finger}, [this](const QDBusMessage &reply) {
            if (reply.type() == QDBusMessage::ErrorMessage) {
                qDebug() << "EnrollStart failed:" << reply.errorName() << reply.errorMessage();
                if (m_enrolling)
                    finishEnroll(false, QString(), errorText(reply));
                else
                    release();
                return;
            }

            m_enrollStarted = true;
            if (!m_enrolling) {
                // Cancelled while EnrollStart was on its way.
                m_enrollStarted = false;
                deviceCall(QStringLiteral("EnrollStop"), {}, [this](const QDBusMessage &) {
                    release();
                });
            }
        });
    }, [this](const QString &error) {
        if (m_enrolling)
            finishEnroll(false, QString(), error);
    });
}

void Fingerprint::stopEnroll()
{
    if (!m_enrolling)
        return;

    const bool started = m_enrollStarted;
    m_enrolling = false;
    m_enrollStarted = false;
    connectEnrollSignal(false);
    Q_EMIT enrollingChanged();

    // When Claim or EnrollStart is still pending its callback cleans up.
    if (started) {
        deviceCall(QStringLiteral("EnrollStop"), {}, [this](const QDBusMessage &) {
            release([this] { loadEnrolledFingers(); });
        });
    }
}

void Fingerprint::onEnrollStatus(const QString &result, bool done)
{
    if (!m_enrolling)
        return;

    if (result == QLatin1String("enroll-stage-passed")) {
        ++m_enrollStagesDone;
        Q_EMIT enrollProgressChanged();
    } else if (result == QLatin1String("enroll-completed") && m_enrollStages > m_enrollStagesDone) {
        m_enrollStagesDone = m_enrollStages;
        Q_EMIT enrollProgressChanged();
    }

    Q_EMIT enrollStatus(result, done);

    if (done)
        finishEnroll(result == QLatin1String("enroll-completed"), result, QString());
}

void Fingerprint::finishEnroll(bool success, const QString &result, const QString &error)
{
    const bool started = m_enrollStarted;
    m_enrolling = false;
    m_enrollStarted = false;
    connectEnrollSignal(false);

    auto reload = [this] { loadEnrolledFingers(); };
    if (started) {
        deviceCall(QStringLiteral("EnrollStop"), {}, [this, reload](const QDBusMessage &) {
            release(reload);
        });
    } else {
        release(reload);
    }

    Q_EMIT enrollingChanged();
    Q_EMIT enrollFinished(success, result, error);
}

void Fingerprint::deleteFinger(const QString &finger)
{
    if (m_devicePath.isEmpty() || m_enrolling || m_busy)
        return;

    setBusy(true);
    claimAnd([this, finger] {
        deviceCall(QStringLiteral("DeleteEnrolledFinger"), {finger}, [this](const QDBusMessage &reply) {
            if (reply.type() == QDBusMessage::ErrorMessage) {
                qDebug() << "DeleteEnrolledFinger failed:" << reply.errorName() << reply.errorMessage();
                Q_EMIT errorOccurred(errorText(reply));
            }
            release([this] {
                setBusy(false);
                loadEnrolledFingers();
            });
        }, InteractiveTimeout);
    }, [this](const QString &error) {
        setBusy(false);
        Q_EMIT errorOccurred(error);
    });
}

void Fingerprint::deleteAllFingers()
{
    if (m_devicePath.isEmpty() || m_enrolling || m_busy)
        return;

    setBusy(true);
    claimAnd([this] {
        deviceCall(QStringLiteral("DeleteEnrolledFingers2"), {}, [this](const QDBusMessage &reply) {
            if (reply.type() == QDBusMessage::ErrorMessage) {
                qDebug() << "DeleteEnrolledFingers2 failed:" << reply.errorName() << reply.errorMessage();
                Q_EMIT errorOccurred(errorText(reply));
            }
            release([this] {
                setBusy(false);
                loadEnrolledFingers();
            });
        }, InteractiveTimeout);
    }, [this](const QString &error) {
        setBusy(false);
        Q_EMIT errorOccurred(error);
    });
}

QString Fingerprint::errorText(const QDBusMessage &reply) const
{
    const QString name = reply.errorName();

    if (name == ErrorPrefix + QLatin1String("PermissionDenied")
            || name == QLatin1String("org.freedesktop.DBus.Error.AccessDenied"))
        return tr("You are not allowed to use the fingerprint reader.");
    if (name == ErrorPrefix + QLatin1String("AlreadyInUse"))
        return tr("The fingerprint reader is being used by another program.");
    if (name == ErrorPrefix + QLatin1String("ClaimDevice"))
        return tr("The fingerprint reader couldn't be opened.");
    if (name == ErrorPrefix + QLatin1String("NoSuchDevice"))
        return tr("The fingerprint reader was disconnected.");
    if (name == ErrorPrefix + QLatin1String("PrintsNotDeleted")
            || name == ErrorPrefix + QLatin1String("PrintsNotDeletedFromDevice"))
        return tr("The fingerprints couldn't be deleted.");
    if (name == QLatin1String("org.freedesktop.DBus.Error.NoReply")
            || name == QLatin1String("org.freedesktop.DBus.Error.Timeout"))
        return tr("The fingerprint reader didn't respond.");

    return tr("Fingerprint reader error: %1").arg(reply.errorMessage().isEmpty() ? name : reply.errorMessage());
}

QStringList Fingerprint::allFingers() const
{
    return {
        QStringLiteral("right-index-finger"),
        QStringLiteral("right-thumb"),
        QStringLiteral("right-middle-finger"),
        QStringLiteral("right-ring-finger"),
        QStringLiteral("right-little-finger"),
        QStringLiteral("left-index-finger"),
        QStringLiteral("left-thumb"),
        QStringLiteral("left-middle-finger"),
        QStringLiteral("left-ring-finger"),
        QStringLiteral("left-little-finger"),
    };
}

QString Fingerprint::fingerName(const QString &finger) const
{
    if (finger == QLatin1String("left-thumb"))
        return tr("Left thumb");
    if (finger == QLatin1String("left-index-finger"))
        return tr("Left index finger");
    if (finger == QLatin1String("left-middle-finger"))
        return tr("Left middle finger");
    if (finger == QLatin1String("left-ring-finger"))
        return tr("Left ring finger");
    if (finger == QLatin1String("left-little-finger"))
        return tr("Left little finger");
    if (finger == QLatin1String("right-thumb"))
        return tr("Right thumb");
    if (finger == QLatin1String("right-index-finger"))
        return tr("Right index finger");
    if (finger == QLatin1String("right-middle-finger"))
        return tr("Right middle finger");
    if (finger == QLatin1String("right-ring-finger"))
        return tr("Right ring finger");
    if (finger == QLatin1String("right-little-finger"))
        return tr("Right little finger");
    return finger;
}

// PAM switch

QString Fingerprint::pamHelperPath() const
{
    const QString path = qEnvironmentVariable("LINGMO_FINGERPRINT_PAM_HELPER");
    return path.isEmpty() ? DefaultPamHelper : path;
}

bool Fingerprint::pamHelperAvailable() const
{
    return QFileInfo(pamHelperPath()).isExecutable();
}

void Fingerprint::refreshPam()
{
    if (!pamHelperAvailable())
        return;

    // "status" only reads /etc/pam.d, no root needed.
    auto *process = new QProcess(this);
    connect(process, &QProcess::finished, this, [this, process] {
        const QStringList lines = QString::fromUtf8(process->readAllStandardOutput()).split(QLatin1Char('\n'));
        process->deleteLater();

        QString state;
        bool module = false;
        for (const QString &line : lines) {
            if (line.startsWith(QLatin1String("state: ")))
                state = line.mid(7).trimmed();
            else if (line.startsWith(QLatin1String("module: ")))
                module = line.mid(8).trimmed() == QLatin1String("present");
        }

        if (state != m_pamState || module != m_pamModuleAvailable) {
            m_pamState = state;
            m_pamModuleAvailable = module;
            Q_EMIT pamChanged();
        }
    });
    connect(process, &QProcess::errorOccurred, process, [process](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            process->deleteLater();
    });
    process->start(pamHelperPath(), {QStringLiteral("status")});
}

void Fingerprint::setPamEnabled(bool enabled)
{
    if (m_pamProcess || !pamHelperAvailable() || enabled == pamEnabled())
        return;

    const QString command = enabled ? QStringLiteral("enable") : QStringLiteral("disable");

    m_pamProcess = new QProcess(this);
    m_pamProcess->setProcessChannelMode(QProcess::MergedChannels);

    auto done = [this](const QString &error) {
        m_pamProcess->deleteLater();
        m_pamProcess = nullptr;
        Q_EMIT pamChanged();
        if (!error.isEmpty())
            Q_EMIT errorOccurred(error);
        refreshPam();
    };

    connect(m_pamProcess, &QProcess::finished, this, [this, done](int exitCode, QProcess::ExitStatus status) {
        const QString output = QString::fromUtf8(m_pamProcess->readAll()).trimmed();
        if (status == QProcess::NormalExit && exitCode == 0) {
            done(QString());
        } else if (status == QProcess::NormalExit && exitCode == PkexecDismissed) {
            done(QString());
        } else if (status == QProcess::NormalExit && exitCode == PkexecNotAuthorized) {
            done(tr("You are not authorized to change this setting."));
        } else {
            qDebug() << "fingerprint-pam failed:" << exitCode << output;
            const QString detail = output.section(QLatin1Char('\n'), -1);
            done(tr("Couldn't change fingerprint authentication: %1").arg(detail));
        }
    });
    connect(m_pamProcess, &QProcess::errorOccurred, this, [this, done](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            done(tr("Couldn't change fingerprint authentication: %1").arg(m_pamProcess->errorString()));
    });

    Q_EMIT pamChanged();

    // Tests point the helper at a copy of /etc and run it without root.
    if (qEnvironmentVariableIsSet("LINGMO_FINGERPRINT_ROOT"))
        m_pamProcess->start(pamHelperPath(), {command});
    else
        m_pamProcess->start(QStringLiteral("pkexec"), {pamHelperPath(), command});
}
