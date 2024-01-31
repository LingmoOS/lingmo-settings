#ifndef UPDATEMODEL_H
#define UPDATEMODEL_H

#include <QCoreApplication>
#include <QDebug>
#include <QDialog>
#include <QProcess>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QTextStream>
#include <QSysInfo>
#include <QProcess>
#include <QJsonObject>
#include <QEventLoop>
#include <QJsonDocument>
#include <QFile>
#include <QDir>
#include <QRegExp>

#include <memory>

#include <QObject>

#include <QApt/Backend>
#include <QApt/Config>
#include <QApt/Transaction>

class UpdateModel : public QObject
{
    Q_OBJECT

public:
    explicit UpdateModel(const QString& downloadUrl, const QString& savePath, QObject* parent = nullptr);
    ~UpdateModel();

    void startDownloadVer();
    void cancelDownloadVer();

Q_SIGNALS:
    void sigDownloadProgress(qint64 bytesRead, qint64 totalBytes, qreal progress);
    void sigDownloadFinished();

public Q_SLOTS:
    void httpFinished();
    void httpReadyRead();

    void networkReplyProgress(qint64 bytesRead, qint64 totalBytes);

//    void onTransactionStatusChanged(QApt::TransactionStatus status);

private:
    void startRequest(const QUrl& requestedUrl);
    std::unique_ptr<QFile> openFileForWrite(const QString& fileName);
    // QApt::Backend *m_backend;
    // QApt::Package *m_package;
    // QApt::Transaction *m_trans;
private:
    QString m_downloadUrl;
    QString m_savePath

    const QString defaultFileName = "/opt/update/";

    QUrl url;
    QNetworkAccessManager qnam;
    QPointer<QNetworkReply> reply;
    std::unique_ptr<QFile> file;
    bool httpRequestAborted;
};

#endif // UPDATEMODEL_H
