#ifndef UPDATESYS_H
#define UPDATESYS_H

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

class UpdateSys : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString changeLog READ changeLog CONSTANT)
    Q_PROPERTY(QString GetWEBlVersion READ GetWEBlVersion CONSTANT)
    Q_PROPERTY(QString GetLocalVersion READ GetLocalVersion CONSTANT)
public:
    explicit UpdateSys(QObject *parent = 0);
    ~UpdateSys();

    bool isLingmoOS();

    void update();
    void checkUpdate();
    bool isUpdate();
    QString getVersion();
    QString getDownloadUrl();
    QString getDownloadPath();
    QString getInstallPath();
    QString getDownloadFileName();
    QString GetLocalVersion();

    QString changeLog();
    QString GetWEBlVersion();

    Q_INVOKABLE void getUpdateInfo();
    Q_INVOKABLE void DownloadPkg();
    Q_INVOKABLE void installPkg();

    Q_INVOKABLE void rebootSys();

public Q_SLOTS:
    void slotCheckUpdate();
    void slotUpdate();
    QString version();

private:
    QString m_downloadurl;
    QString m_savepath;

}