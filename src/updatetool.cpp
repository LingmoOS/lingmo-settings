#include <QCoreApplication>
#include <QDebug>
#include <QDialog>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QTextStream>
#include <QSysInfo>
#include <QProcess>

#ifdef Q_OS_LINUX
#include <QStandardPaths>
#include <QFileInfo>
#endif

const QString updateUrl = "https://os.lingmo.org/project/version.json";
const QString downloadUrl = "https://mirrors.packages.lingmo.org/update_f/updap.deb";

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    QNetworkAccessManager manager;
    QNetworkRequest request(updateUrl);
    QNetworkReply *reply = manager.get(request);

    connect(reply, &QNetworkReply::finished, [=](){
        if (reply->error() == QNetworkReply::NoError) {
            QTextStream stream(reply);
            QJsonObject json = QJsonDocument::fromJson(stream.readAll()).object();
            QString version = json["version"].toString();

            QFileInfo fileInfo(downloadUrl);
            QString downloadPath = fileInfo.absolutePath();
            if (!QDir(downloadPath).exists()) {
                QDir().mkpath(downloadPath);
            }

            QNetworkRequest downloadRequest(downloadUrl);
            QNetworkReply *downloadReply = manager.get(downloadRequest);
            connect(downloadReply, &QNetworkReply::finished, [=](){
                if (downloadReply->error() == QNetworkReply::NoError) {
                    QProcess process;
                    #ifdef Q_OS_LINUX
                    process.setWorkingDirectory(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation));
                    #else
                    process.setWorkingDirectory(QCoreApplication::applicationDirPath());
                    #endif
                    process.start("apt", {"install", downloadPath + "/updap.deb"});
                    process.waitForFinished(-1);
                    if (process.exitCode() == 0) {
                        qDebug() << "Update installed successfully.";
                        a.exit(0);
                    } else {
                        qDebug() << "Update installation failed with exit code" << process.exitCode();
                        a.exit(1);
                    }
                } else {
                    qDebug() << "Download failed:" << downloadReply->errorString();
                    a.exit(1);
                }
                downloadReply->deleteLater();
            });
        } else {
            qDebug() << "Request failed:" << reply->errorString();
            a.exit(1);
        }
        reply->deleteLater();
    });

    return a.exec();
}