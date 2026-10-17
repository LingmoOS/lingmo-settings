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

#ifndef FACEAUTH_H
#define FACEAUTH_H

#include <QDateTime>
#include <QImage>
#include <QObject>
#include <QQmlParserStatus>
#include <QStringList>

class QProcess;

// Face login of the logged-in user with the webcam: enrollment, test and
// deletion through lingmo-faceauth (lingmo-camera), and the two switches that
// put it in PAM (face-pam helper + pkexec): login and lock screens, and sudo +
// polkit.
//
// The enrolled face is ~/.local/share/lingmoos/face/<user>.dat: a few feature
// vectors computed by lingmo-faceauth, no picture. The camera preview shown
// while enrolling comes over the pipe and is never written to disk.
//
// For tests: LINGMO_FACEAUTH_BIN names lingmo-faceauth, LINGMO_FACEAUTH_ARGS
// adds arguments to it (e.g. "--models dir --image face.jpg"), LINGMO_FACE_STORE
// replaces the enrollment file, LINGMO_FINGERPRINT_ROOT=<dir> makes face-pam
// work on <dir>/etc/pam.d without pkexec, LINGMO_FACE_PAM_HELPER names it.
class FaceAuth : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_PROPERTY(bool ready READ ready NOTIFY stateChanged)
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(bool cameraAvailable READ cameraAvailable NOTIFY stateChanged)
    Q_PROPERTY(bool enrolled READ enrolled NOTIFY enrolledChanged)
    Q_PROPERTY(QDateTime enrolledDate READ enrolledDate NOTIFY enrolledChanged)
    Q_PROPERTY(bool enrolling READ enrolling NOTIFY enrollingChanged)
    Q_PROPERTY(int enrollDone READ enrollDone NOTIFY enrollProgressChanged)
    Q_PROPERTY(int enrollTotal READ enrollTotal NOTIFY enrollProgressChanged)
    Q_PROPERTY(QString enrollHint READ enrollHint NOTIFY enrollProgressChanged)
    Q_PROPERTY(QString preview READ preview NOTIFY previewChanged)
    Q_PROPERTY(bool testing READ testing NOTIFY testingChanged)
    Q_PROPERTY(bool pamHelperAvailable READ pamHelperAvailable CONSTANT)
    Q_PROPERTY(bool pamModuleAvailable READ pamModuleAvailable NOTIFY pamChanged)
    Q_PROPERTY(bool loginEnabled READ loginEnabled NOTIFY pamChanged)
    Q_PROPERTY(bool loginPartial READ loginPartial NOTIFY pamChanged)
    Q_PROPERTY(bool adminEnabled READ adminEnabled NOTIFY pamChanged)
    Q_PROPERTY(bool adminPartial READ adminPartial NOTIFY pamChanged)
    Q_PROPERTY(bool adminCopyPresent READ adminCopyPresent NOTIFY pamChanged)
    Q_PROPERTY(bool pamBusy READ pamBusy NOTIFY pamChanged)

public:
    explicit FaceAuth(QObject *parent = nullptr);
    ~FaceAuth() override;

    void classBegin() override {}
    void componentComplete() override;

    bool ready() const { return m_ready; }
    bool available() const;
    bool cameraAvailable() const { return m_cameraAvailable; }
    bool enrolled() const { return m_enrolled; }
    QDateTime enrolledDate() const { return m_enrolledDate; }
    bool enrolling() const { return m_enrollProcess != nullptr; }
    int enrollDone() const { return m_enrollDone; }
    int enrollTotal() const { return m_enrollTotal; }
    QString enrollHint() const { return m_enrollHint; }
    QString preview() const;
    bool testing() const { return m_testProcess != nullptr; }
    bool pamHelperAvailable() const;
    bool pamModuleAvailable() const { return m_pamModule; }
    bool loginEnabled() const { return m_login == QLatin1String("enabled"); }
    bool loginPartial() const { return m_login == QLatin1String("partial"); }
    bool adminEnabled() const { return m_admin == QLatin1String("enabled"); }
    bool adminPartial() const { return m_admin == QLatin1String("partial"); }
    bool adminCopyPresent() const { return m_copyPresent; }
    bool pamBusy() const { return m_pamProcess != nullptr; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void startEnroll();
    Q_INVOKABLE void stopEnroll();
    Q_INVOKABLE void deleteFace();
    Q_INVOKABLE void test();
    Q_INVOKABLE void setLoginEnabled(bool enabled);
    Q_INVOKABLE void setAdminEnabled(bool enabled);

    // The latest preview frame (for the image provider)
    static QImage previewImage();

Q_SIGNALS:
    void stateChanged();
    void enrolledChanged();
    void enrollingChanged();
    void enrollProgressChanged();
    void previewChanged();
    void testingChanged();
    void pamChanged();

    // error is a code: busy, nocamera, models, timeout, save, cancelled, failed
    void enrollFinished(bool success, const QString &error);
    // result: match, nomatch, liveness, busy, nocamera, noenroll, error
    void testFinished(const QString &result);
    void errorOccurred(const QString &message);

private:
    QString faceauthPath() const;
    QStringList extraArgs() const;
    QString storePath() const;
    QString pamHelperPath() const;
    void refreshEnrolled();
    void refreshCameras();
    void refreshPam();
    void runPam(const QStringList &args);
    void onEnrollOutput();

    bool m_ready = false;
    bool m_cameraAvailable = false;
    bool m_enrolled = false;
    QDateTime m_enrolledDate;

    QProcess *m_enrollProcess = nullptr;
    QByteArray m_enrollBuffer;
    int m_enrollDone = 0;
    int m_enrollTotal = 5;
    QString m_enrollHint;
    QString m_enrollError;
    bool m_enrollSucceeded = false;
    int m_previewSerial = 0;

    QProcess *m_testProcess = nullptr;

    QString m_login;
    QString m_admin;
    bool m_copyPresent = false;
    bool m_pamModule = false;
    QProcess *m_pamProcess = nullptr;
};

#endif // FACEAUTH_H
