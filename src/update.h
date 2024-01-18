#ifndef UPDATETOOL_H
#define UPDATETOOL_H

#include <QObject>
#include <QCoreApplication>
#include <QGuiApplication>
#include "net.h"
#include <QException>
#include <BluezQt/InitManagerJob>
#include <BluezQt/Manager>
#include <BluezQt/Adapter>
#include <QPointer>
#include <PackageKit/Transaction>
#include <PackageKit/Daemon>
#include <QProcess>
#include <QFile>
#include <QDebug>
#include <QTextCodec>
#include <QUrl>
#include <QSettings>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <exception>
#include <KSharedConfig>
#include <KConfigGroup>
#include <QDBusInterface>
#include <QDBusReply>
#include <QStorageInfo>

using namespace std;

class UpdateTool : public QObject
{
    Q_OBJECT
public:
    Q_PROPERTY(QString localDeviceName READ localDeviceName NOTIFY localDeviceNameChanged)
    explicit UpdateTool();
    ~UpdateTool(){};

    Q_PROPERTY(bool updating READ updating WRITE setUpdating NOTIFY updatingChanged);

    QString localDeviceName(){ return m_localDeviceName; };
    MyNetworkObject *myNetworkObject;
    static QString settingFileName  ;

    // QString localVersionCode;
    Q_INVOKABLE void launchDistUpgrade(QString version);
    QString valueVersion = "";

    bool updating();
    void setUpdating(bool updateStatus);

    QString readLocalInfo();
    void fetchUpdates();
    int Parse_Seniverse_Now_Json(QString& json);
    Q_INVOKABLE QString readLocalVersion();
    Q_INVOKABLE void readRemoteVersion();
    Q_INVOKABLE bool hasNewVersion();
    Q_INVOKABLE void setCheckCycle(int cycle);
    Q_INVOKABLE int getCheckCycle();
    Q_INVOKABLE double getStorageTotalSize();
    Q_INVOKABLE QString readModelName();
    Q_INVOKABLE void getAptUpdates();
    Q_INVOKABLE int getQaptupdatorUpdateStatus();

    static QString loadSetting( QString key , QString value ) ;
	static QString saveSetting( QString key , QString value ) ;

private:
    QStorageInfo storage = QStorageInfo::root();
    QString m_localDeviceName = "";
    int loadPackageTime = 0;
    int needUpdatePackageCount = 0;
    bool m_updating = false;

public slots:
    void readRemoteSuccess(QString data);
    void readRemoteFailure(QString error);
    void transactionError(PackageKit::Transaction::Error, const QString& message);
    void addPackageToUpdate(PackageKit::Transaction::Info, const QString& pkgid, const QString& summary);
    void getUpdatesFinished(PackageKit::Transaction::Exit,uint);
    void receiveDbusUpdatorSigEnd();

signals:
    void checkedFinish(int status , QString log , QString version);  //1 = remote update , 5 = local update, 2 = no update, 3 = read local fail, 4 = server exception
    void localDeviceNameChanged(const QString localDeviceName);
    void localeCheckedFinish(int needUpdatePackageCount);
    void qaptupdatorFinish();
	void updatingChanged();
};

#endif