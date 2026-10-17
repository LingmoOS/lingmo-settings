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

#include "faceauth.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMutex>
#include <QProcess>
#include <QQmlEngine>
#include <QQuickImageProvider>

#include <pwd.h>
#include <unistd.h>

namespace {
const QString DefaultFaceauth = QStringLiteral("/usr/bin/lingmo-faceauth");
const QString DefaultPamHelper = QStringLiteral("/usr/lib/lingmo-settings/face-pam");
const QString ProviderId = QStringLiteral("lingmoface");

// pkexec exit codes
const int PkexecDismissed = 126;
const int PkexecNotAuthorized = 127;

QMutex previewMutex;
QImage previewFrame;

class PreviewProvider : public QQuickImageProvider
{
public:
    PreviewProvider()
        : QQuickImageProvider(QQuickImageProvider::Image)
    {
    }

    QImage requestImage(const QString &, QSize *size, const QSize &) override
    {
        const QImage image = FaceAuth::previewImage();
        if (size)
            *size = image.size();
        return image;
    }
};

QString userName()
{
    const passwd *pw = ::getpwuid(::getuid());
    return pw ? QString::fromLocal8Bit(pw->pw_name) : QString();
}

QString userHome()
{
    // The path lingmo-faceauth computes (the passwd entry, not $HOME), since
    // the login screen reads it as root
    const passwd *pw = ::getpwuid(::getuid());
    return pw && pw->pw_dir ? QFile::decodeName(pw->pw_dir) : QDir::homePath();
}
}

FaceAuth::FaceAuth(QObject *parent)
    : QObject(parent)
{
    refresh();
}

FaceAuth::~FaceAuth()
{
    // Never leave the camera on
    for (QProcess *p : {m_enrollProcess, m_testProcess}) {
        if (p) {
            p->disconnect(this);
            p->terminate();
            p->waitForFinished(1000);
        }
    }
}

void FaceAuth::componentComplete()
{
    QQmlEngine *engine = qmlEngine(this);
    if (engine && !engine->imageProvider(ProviderId))
        engine->addImageProvider(ProviderId, new PreviewProvider);
}

QImage FaceAuth::previewImage()
{
    QMutexLocker lock(&previewMutex);
    return previewFrame;
}

QString FaceAuth::preview() const
{
    if (!m_enrollProcess || m_previewSerial == 0)
        return QString();
    return QStringLiteral("image://%1/%2").arg(ProviderId).arg(m_previewSerial);
}

QString FaceAuth::faceauthPath() const
{
    const QString path = qEnvironmentVariable("LINGMO_FACEAUTH_BIN");
    return path.isEmpty() ? DefaultFaceauth : path;
}

QStringList FaceAuth::extraArgs() const
{
    return qEnvironmentVariable("LINGMO_FACEAUTH_ARGS").split(QLatin1Char(' '), Qt::SkipEmptyParts);
}

bool FaceAuth::available() const
{
    return QFileInfo(faceauthPath()).isExecutable();
}

QString FaceAuth::storePath() const
{
    const QString path = qEnvironmentVariable("LINGMO_FACE_STORE");
    if (!path.isEmpty())
        return path;
    return userHome() + QStringLiteral("/.local/share/lingmoos/face/") + userName() + QStringLiteral(".dat");
}

void FaceAuth::refresh()
{
    refreshEnrolled();
    refreshCameras();
    refreshPam();
}

void FaceAuth::refreshEnrolled()
{
    const QFileInfo info(storePath());
    const bool enrolled = info.isFile() && info.size() > 0;
    const QDateTime date = enrolled ? info.lastModified() : QDateTime();
    if (enrolled != m_enrolled || date != m_enrolledDate) {
        m_enrolled = enrolled;
        m_enrolledDate = date;
        Q_EMIT enrolledChanged();
    }
}

void FaceAuth::refreshCameras()
{
    if (!available()) {
        m_ready = true;
        m_cameraAvailable = false;
        Q_EMIT stateChanged();
        return;
    }

    auto *process = new QProcess(this);
    connect(process, &QProcess::finished, this, [this, process] {
        const bool found = !process->readAllStandardOutput().trimmed().isEmpty();
        process->deleteLater();
        // Pictures instead of a camera (tests)
        const bool images = extraArgs().contains(QLatin1String("--image"));
        m_cameraAvailable = found || images;
        m_ready = true;
        Q_EMIT stateChanged();
    });
    connect(process, &QProcess::errorOccurred, this, [this, process](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            process->deleteLater();
            m_ready = true;
            Q_EMIT stateChanged();
        }
    });
    process->start(faceauthPath(), {QStringLiteral("cameras")});
}

void FaceAuth::startEnroll()
{
    if (m_enrollProcess || m_testProcess || !available())
        return;

    m_enrollDone = 0;
    m_enrollHint = QStringLiteral("straight");
    m_enrollError.clear();
    m_enrollSucceeded = false;
    m_enrollBuffer.clear();
    m_previewSerial = 0;
    {
        QMutexLocker lock(&previewMutex);
        previewFrame = QImage();
    }

    m_enrollProcess = new QProcess(this);
    m_enrollProcess->setProcessChannelMode(QProcess::SeparateChannels);
    connect(m_enrollProcess, &QProcess::readyReadStandardOutput, this, &FaceAuth::onEnrollOutput);
    connect(m_enrollProcess, &QProcess::readyReadStandardError, this, [this] {
        const QByteArray err = m_enrollProcess->readAllStandardError().trimmed();
        if (!err.isEmpty())
            qDebug() << "lingmo-faceauth:" << err;
    });
    connect(m_enrollProcess, &QProcess::finished, this, [this](int exitCode, QProcess::ExitStatus status) {
        onEnrollOutput();
        const bool success = status == QProcess::NormalExit && exitCode == 0 && m_enrollSucceeded;
        QString error = m_enrollError;
        if (!success && error.isEmpty())
            error = QStringLiteral("failed");

        m_enrollProcess->deleteLater();
        m_enrollProcess = nullptr;
        {
            QMutexLocker lock(&previewMutex);
            previewFrame = QImage();
        }
        Q_EMIT previewChanged();
        Q_EMIT enrollingChanged();

        refreshEnrolled();
        // sudo and polkit use root's copy: bring it up to date
        if (success && (adminEnabled() || m_copyPresent))
            runPam({QStringLiteral("sync")});
        Q_EMIT enrollFinished(success, success ? QString() : error);
    });
    connect(m_enrollProcess, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart && m_enrollProcess) {
            m_enrollProcess->deleteLater();
            m_enrollProcess = nullptr;
            Q_EMIT enrollingChanged();
            Q_EMIT enrollFinished(false, QStringLiteral("failed"));
        }
    });

    QStringList args = {QStringLiteral("enroll"), QStringLiteral("--preview"), QStringLiteral("--out"), storePath()};
    args << extraArgs();
    m_enrollProcess->start(faceauthPath(), args);
    Q_EMIT enrollingChanged();
    Q_EMIT enrollProgressChanged();
    Q_EMIT previewChanged();
}

void FaceAuth::onEnrollOutput()
{
    if (!m_enrollProcess)
        return;
    m_enrollBuffer += m_enrollProcess->readAllStandardOutput();

    bool progress = false, preview = false;
    int newline;
    while ((newline = m_enrollBuffer.indexOf('\n')) >= 0) {
        const QByteArray line = m_enrollBuffer.left(newline);
        m_enrollBuffer.remove(0, newline + 1);

        const int space = line.indexOf(' ');
        const QByteArray key = space < 0 ? line : line.left(space);
        const QByteArray value = space < 0 ? QByteArray() : line.mid(space + 1);

        if (key == "preview") {
            QImage image;
            if (image.loadFromData(QByteArray::fromBase64(value), "JPG")) {
                QMutexLocker lock(&previewMutex);
                previewFrame = image;
                ++m_previewSerial;
                preview = true;
            }
        } else if (key == "progress") {
            const QList<QByteArray> parts = value.split(' ');
            if (parts.size() == 2) {
                m_enrollDone = parts[0].toInt();
                m_enrollTotal = qMax(1, parts[1].toInt());
                progress = true;
            }
        } else if (key == "hint") {
            m_enrollHint = QString::fromLatin1(value);
            progress = true;
        } else if (key == "done") {
            m_enrollSucceeded = true;
        } else if (key == "error") {
            m_enrollError = QString::fromLatin1(value);
        }
    }

    if (progress)
        Q_EMIT enrollProgressChanged();
    if (preview)
        Q_EMIT previewChanged();
}

void FaceAuth::stopEnroll()
{
    if (!m_enrollProcess)
        return;
    m_enrollError = QStringLiteral("cancelled");
    m_enrollProcess->terminate();
}

void FaceAuth::deleteFace()
{
    if (m_enrollProcess)
        return;
    const QString path = storePath();
    if (QFile::exists(path) && !QFile::remove(path))
        Q_EMIT errorOccurred(tr("Couldn't delete %1.").arg(path));
    refreshEnrolled();
    // Root's copy for sudo and polkit goes too: face recognition for
    // administrators is turned off (no face left to recognize)
    if (adminEnabled() || adminPartial())
        runPam({QStringLiteral("disable"), QStringLiteral("admin")});
    else if (m_copyPresent)
        runPam({QStringLiteral("sync")});
}

void FaceAuth::test()
{
    if (m_enrollProcess || m_testProcess || !available())
        return;

    m_testProcess = new QProcess(this);
    connect(m_testProcess, &QProcess::finished, this, [this](int exitCode, QProcess::ExitStatus status) {
        QString result;
        const QList<QByteArray> lines = m_testProcess->readAllStandardOutput().split('\n');
        for (const QByteArray &line : lines) {
            if (line.startsWith("face:") && line != "face:looking")
                result = QString::fromLatin1(line.mid(5));
        }
        if (result.isEmpty())
            result = status == QProcess::NormalExit && exitCode == 0 ? QStringLiteral("match") : QStringLiteral("error");
        m_testProcess->deleteLater();
        m_testProcess = nullptr;
        Q_EMIT testingChanged();
        Q_EMIT testFinished(result);
    });
    connect(m_testProcess, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart && m_testProcess) {
            m_testProcess->deleteLater();
            m_testProcess = nullptr;
            Q_EMIT testingChanged();
            Q_EMIT testFinished(QStringLiteral("error"));
        }
    });

    QStringList args = {QStringLiteral("verify"), QStringLiteral("--machine"), QStringLiteral("--timeout"), QStringLiteral("5")};
    if (qEnvironmentVariableIsSet("LINGMO_FACE_STORE"))
        args << QStringLiteral("--store") << storePath();
    args << extraArgs();
    m_testProcess->start(faceauthPath(), args);
    Q_EMIT testingChanged();
}

// PAM switches

QString FaceAuth::pamHelperPath() const
{
    const QString path = qEnvironmentVariable("LINGMO_FACE_PAM_HELPER");
    return path.isEmpty() ? DefaultPamHelper : path;
}

bool FaceAuth::pamHelperAvailable() const
{
    return QFileInfo(pamHelperPath()).isExecutable();
}

void FaceAuth::refreshPam()
{
    if (!pamHelperAvailable())
        return;

    // "status" only reads, no root needed.
    auto *process = new QProcess(this);
    connect(process, &QProcess::finished, this, [this, process] {
        const QStringList lines = QString::fromUtf8(process->readAllStandardOutput()).split(QLatin1Char('\n'));
        process->deleteLater();

        QString login, admin;
        bool module = false, copy = false;
        for (const QString &line : lines) {
            const QString value = line.section(QLatin1Char(':'), 1).trimmed();
            if (line.startsWith(QLatin1String("login:")))
                login = value;
            else if (line.startsWith(QLatin1String("admin:")))
                admin = value;
            else if (line.startsWith(QLatin1String("module:")))
                module = value == QLatin1String("present");
            else if (line.startsWith(QLatin1String("copy:")))
                copy = value == QLatin1String("present");
        }

        if (login != m_login || admin != m_admin || module != m_pamModule || copy != m_copyPresent) {
            m_login = login;
            m_admin = admin;
            m_pamModule = module;
            m_copyPresent = copy;
            Q_EMIT pamChanged();
        }
    });
    connect(process, &QProcess::errorOccurred, process, [process](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            process->deleteLater();
    });
    process->start(pamHelperPath(), {QStringLiteral("status")});
}

void FaceAuth::runPam(const QStringList &args)
{
    if (m_pamProcess || !pamHelperAvailable())
        return;

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
        if (status == QProcess::NormalExit && (exitCode == 0 || exitCode == PkexecDismissed)) {
            done(QString());
        } else if (status == QProcess::NormalExit && exitCode == PkexecNotAuthorized) {
            done(tr("You are not authorized to change this setting."));
        } else {
            qDebug() << "face-pam failed:" << exitCode << output;
            done(tr("Couldn't change face recognition: %1").arg(output.section(QLatin1Char('\n'), -1)));
        }
    });
    connect(m_pamProcess, &QProcess::errorOccurred, this, [this, done](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            done(tr("Couldn't change face recognition: %1").arg(m_pamProcess->errorString()));
    });

    Q_EMIT pamChanged();

    // Tests point the helper at a copy of /etc and run it without root.
    if (qEnvironmentVariableIsSet("LINGMO_FINGERPRINT_ROOT"))
        m_pamProcess->start(pamHelperPath(), args);
    else
        m_pamProcess->start(QStringLiteral("pkexec"), QStringList{pamHelperPath()} + args);
}

void FaceAuth::setLoginEnabled(bool enabled)
{
    if (enabled == loginEnabled() && !loginPartial())
        return;
    // Turning the login off turns sudo and polkit off too
    runPam(enabled ? QStringList{QStringLiteral("enable"), QStringLiteral("login")}
                   : QStringList{QStringLiteral("disable"), QStringLiteral("all")});
}

void FaceAuth::setAdminEnabled(bool enabled)
{
    if (enabled == (adminEnabled() && m_copyPresent) && !adminPartial())
        return;
    runPam({enabled ? QStringLiteral("enable") : QStringLiteral("disable"), QStringLiteral("admin")});
}
