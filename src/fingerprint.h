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

#ifndef FINGERPRINT_H
#define FINGERPRINT_H

#include <QDBusConnection>
#include <QDBusMessage>
#include <QObject>
#include <QStringList>

#include <functional>

class QProcess;

// Fingerprints of the logged-in user, through fprintd (net.reactivated.Fprint
// on the system bus), and the switch that turns pam_fprintd on for the login
// screen, the lock screen, polkit and sudo (fingerprint-pam helper + pkexec).
//
// For tests: LINGMO_FPRINT_BUS=session talks to a fprintd mock on the session
// bus; LINGMO_FINGERPRINT_ROOT=<dir> makes the helper work on <dir>/etc/pam.d
// (run without pkexec); LINGMO_FINGERPRINT_PAM_HELPER overrides its path.
class Fingerprint : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY stateChanged)
    Q_PROPERTY(bool serviceAvailable READ serviceAvailable NOTIFY stateChanged)
    Q_PROPERTY(bool deviceAvailable READ deviceAvailable NOTIFY stateChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY stateChanged)
    Q_PROPERTY(bool swipe READ swipe NOTIFY stateChanged)
    Q_PROPERTY(int enrollStages READ enrollStages NOTIFY stateChanged)
    Q_PROPERTY(QStringList enrolledFingers READ enrolledFingers NOTIFY enrolledFingersChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool enrolling READ enrolling NOTIFY enrollingChanged)
    Q_PROPERTY(QString enrollFinger READ enrollFinger NOTIFY enrollingChanged)
    Q_PROPERTY(int enrollStagesDone READ enrollStagesDone NOTIFY enrollProgressChanged)
    Q_PROPERTY(bool pamHelperAvailable READ pamHelperAvailable CONSTANT)
    Q_PROPERTY(bool pamModuleAvailable READ pamModuleAvailable NOTIFY pamChanged)
    Q_PROPERTY(bool pamEnabled READ pamEnabled NOTIFY pamChanged)
    Q_PROPERTY(bool pamPartial READ pamPartial NOTIFY pamChanged)
    Q_PROPERTY(bool pamBusy READ pamBusy NOTIFY pamChanged)

public:
    explicit Fingerprint(QObject *parent = nullptr);
    ~Fingerprint() override;

    bool ready() const { return m_ready; }
    bool serviceAvailable() const { return m_serviceAvailable; }
    bool deviceAvailable() const { return !m_devicePath.isEmpty(); }
    QString deviceName() const { return m_deviceName; }
    bool swipe() const { return m_swipe; }
    int enrollStages() const { return m_enrollStages; }
    QStringList enrolledFingers() const { return m_enrolledFingers; }
    bool busy() const { return m_busy; }
    bool enrolling() const { return m_enrolling; }
    QString enrollFinger() const { return m_enrollFinger; }
    int enrollStagesDone() const { return m_enrollStagesDone; }
    bool pamHelperAvailable() const;
    bool pamModuleAvailable() const { return m_pamModuleAvailable; }
    bool pamEnabled() const { return m_pamState == QLatin1String("enabled"); }
    bool pamPartial() const { return m_pamState == QLatin1String("partial"); }
    bool pamBusy() const { return m_pamProcess != nullptr; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void startEnroll(const QString &finger);
    Q_INVOKABLE void stopEnroll();
    Q_INVOKABLE void deleteFinger(const QString &finger);
    Q_INVOKABLE void deleteAllFingers();
    Q_INVOKABLE void setPamEnabled(bool enabled);

    // fprintd finger ids, in display order, and their translated names.
    Q_INVOKABLE QStringList allFingers() const;
    Q_INVOKABLE QString fingerName(const QString &finger) const;

Q_SIGNALS:
    void stateChanged();
    void enrolledFingersChanged();
    void busyChanged();
    void enrollingChanged();
    void enrollProgressChanged();
    void pamChanged();

    // Every EnrollStatus signal of fprintd (result is e.g. "enroll-stage-passed").
    void enrollStatus(const QString &result, bool done);
    // The enrollment ended: success, or an error text for the user.
    void enrollFinished(bool success, const QString &result, const QString &error);
    void errorOccurred(const QString &message);

private Q_SLOTS:
    void onEnrollStatus(const QString &result, bool done);

private:
    using Callback = std::function<void(const QDBusMessage &reply)>;

    QDBusConnection bus() const;
    void callAsync(const QString &path, const QString &interface, const QString &method,
                   const QVariantList &args, const Callback &callback, int timeout = 25000);
    void deviceCall(const QString &method, const QVariantList &args, const Callback &callback,
                    int timeout = 25000);
    void loadDevice(const QString &path);
    void loadEnrolledFingers();
    void claimAnd(const std::function<void()> &next, const std::function<void(const QString &)> &failed);
    void release(const std::function<void()> &next = nullptr);
    void finishEnroll(bool success, const QString &result, const QString &error);
    void setBusy(bool busy);
    void setEnrolledFingers(const QStringList &fingers);
    void connectEnrollSignal(bool connect);
    QString errorText(const QDBusMessage &reply) const;

    void refreshPam();
    QString pamHelperPath() const;

    bool m_ready = false;
    bool m_serviceAvailable = false;
    QString m_devicePath;
    QString m_deviceName;
    bool m_swipe = false;
    int m_enrollStages = -1;
    QStringList m_enrolledFingers;
    bool m_busy = false;
    bool m_claimed = false;
    bool m_enrolling = false;
    bool m_enrollStarted = false;
    QString m_enrollFinger;
    int m_enrollStagesDone = 0;
    int m_generation = 0;

    QString m_pamState;
    bool m_pamModuleAvailable = false;
    QProcess *m_pamProcess = nullptr;
};

#endif // FINGERPRINT_H
