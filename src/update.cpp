/*
 * Copyright 2023-2024 Lingmo OS Team <lingmo@lingmo.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "net.h"
#include "update.h"
#include <klocalizedstring.h>

QString UpdateTool::settingFileName = "/usr/share/lastCheckedTime.ini" ;

UpdateTool::UpdateTool() {
    myNetworkObject = new MyNetworkObject();
    connect(myNetworkObject , SIGNAL(requestSuccessSignal(QString)) , this , SLOT(readRemoteSuccess(QString)));
    connect(myNetworkObject , SIGNAL(requestFailSignal(QString)) , this , SLOT(readRemoteFailure(QString)));
    QDBusConnection::sessionBus().connect(QString(), "/signals/objects", "com.lingmoos.qaptupdator", "sigEnd", this, SLOT(receiveDbusUpdatorSigEnd()));
}

void UpdateTool::fetchUpdates()
{
    QPointer<PackageKit::Transaction> m_getUpdatesTransaction = PackageKit::Daemon::getUpdates();
    connect(m_getUpdatesTransaction, &PackageKit::Transaction::finished, this, &UpdateTool::getUpdatesFinished);
    connect(m_getUpdatesTransaction, &PackageKit::Transaction::package, this, &UpdateTool::addPackageToUpdate);
    connect(m_getUpdatesTransaction, &PackageKit::Transaction::errorCode, this, &UpdateTool::transactionError);
}

void UpdateTool::getAptUpdates()
{
    loadPackageTime =  QDateTime::currentMSecsSinceEpoch();
    QPointer<PackageKit::Transaction> m_refresher = PackageKit::Daemon::refreshCache(false);

    connect(m_refresher.data(), &PackageKit::Transaction::errorCode, this,[this]() {
        needUpdatePackageCount = 0;
        fetchUpdates();
    });
    connect(m_refresher.data(), &PackageKit::Transaction::finished, this, [this]() {
        needUpdatePackageCount = 0;
        fetchUpdates();
    });
}

void UpdateTool::transactionError(PackageKit::Transaction::Error, const QString& message)
{
    emit checkedFinish(4 , "local fetch update fail" , "");
}

void UpdateTool::addPackageToUpdate(PackageKit::Transaction::Info info, const QString& packageId, const QString& summary)
{
    needUpdatePackageCount ++;
}

void UpdateTool::getUpdatesFinished(PackageKit::Transaction::Exit exitStatus, uint)
{
    int loadNetDataAndCacheEndtime = QDateTime::currentMSecsSinceEpoch();
    if (needUpdatePackageCount <= 0) {
        saveSetting("haveNewVersion" , "false");
        emit checkedFinish(2 , "Current Version is Lastest" , "");
    } else {
        saveSetting("haveNewVersion" , "true");
        emit checkedFinish(5, i18n("Current version %1  found updateable packages",valueVersion.toLocal8Bit().data()), valueVersion);
    }
}

void UpdateTool::launchDistUpgrade(QString v_version)
{
    QProcess process(this);
    process.startDetached("qaptupdator -s "+ v_version);
}

bool UpdateTool::updating()
{
    return m_updating;
}

void UpdateTool::setUpdating(bool updateStatus)
{
    // if (m_updating == updateStatus) {
    //     return;
    // }
    m_updating = updateStatus;
    emit updatingChanged();
}

QString UpdateTool::readLocalVersion()
{
    QString ver1 = "";
    QString dataFromFile;

    QTextCodec * code = QTextCodec::codecForName("utf8");
    QFile file("/usr/share/lingmoosinfo/systeminfo.conf");

    if ( !file.open(QIODevice::ReadOnly | QIODevice::Text) )
        return "";

    QTextStream stream(&file);
    stream.setCodec(code);
    while (stream.atEnd() == 0) {
        ver1 = stream.readAll();
    }
    QString result = "";
    QStringList list = ver1.split("\n");

    QString version= list.at(1);
    result.append(version.remove("version="));
    QString revision= list.at(2);
    result.append(".");
    result.append(revision.remove("revision="));

    return result ;
}

QString UpdateTool::readModelName()
{
    QString ver1 = "";
    QString dataFromFile;

    QTextCodec * code = QTextCodec::codecForName("utf8");
    QFile file("/usr/share/lingmoosinfo/systeminfo.conf");

    if ( !file.open(QIODevice::ReadOnly | QIODevice::Text) )
        return "";

    QTextStream stream(&file);
    stream.setCodec(code);
    while (stream.atEnd() == 0) {
        ver1 = stream.readAll();
    }
    QString result = "";
    QStringList list = ver1.split("\n");
    if(list.size() > 9) {
        QString hwName= list.at(9);
        result.append(hwName.remove("hwname="));
        result.append(" ");
    }
    QString product = list.size() > 8 ? list.at(8) : "";
    result.append(product.remove("product="));
    return result ;
}

double UpdateTool::getStorageTotalSize()
{
    // return storage.bytesTotal();
    QList<QStorageInfo> list = QStorageInfo::mountedVolumes();

    int count = list.size();
    double allTotalSize = 0;

    for(int i = 0; i < count; ++i)
    {
        QStorageInfo diskInfo = list.at(i);
        qDebug() << " diskInfo path ::"<< diskInfo.rootPath();
        if(!diskInfo.rootPath().startsWith("/media")){
            qint64 freeSize = diskInfo.bytesFree();
            qint64 totalSize = diskInfo.bytesTotal();
            allTotalSize += totalSize;
        }
    }
    return allTotalSize;
}

QString UpdateTool::readLocalInfo()
{
    QString ver1 = "";
    QString dataFromFile;
    QTextCodec * code = QTextCodec::codecForName("utf8");
    QFile file("/usr/share/lingmoosinfo/systeminfo.conf");

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit checkedFinish(3 , "Read local info failure" , "");
        return "";
    }

    QTextStream stream(&file);
    stream.setCodec(code);
    while (stream.atEnd() == 0) {
        ver1 = stream.readAll();
    }
    QString result = "?localversion=";
    QStringList list = ver1.split("\n");

    QString version= list.at(1);
    result.append(version.remove("version="));
    QString revision= list.at(2);
    result.append(".");
    result.append(revision.remove("revision="));
    // get local version
    valueVersion = result;
    valueVersion = valueVersion.remove("?localversion=");

    result.append("&platform=");

    QString buildnum= list.at(3);
    QString stage= list.at(4);
    QString architecture= list.at(5);
    result.append(architecture.remove("architecture="));
    QString hwversion= list.at(6);

    QString firmware= list.at(7);
    QString product= list.at(8);
    result.append("&product=");
    QString productVersion = product.remove("product=");
    if (productVersion == "") {
        productVersion = "community";
    }
    result.append(productVersion);
    result.append("&lang=en");

    return result;
}

void UpdateTool::readRemoteVersion()
{
    QString urlStr = "https://os.lingmo.org/project/version";
    QString version = readLocalInfo();
    if(version== ""){
        emit checkedFinish(4 , "" , "");
        return ;
    }
    urlStr.append(version);

    qDebug() << "urlStr:::" << urlStr;
    QUrl url = QUrl(urlStr);
    myNetworkObject->get(url);
}

bool UpdateTool::hasNewVersion()
{
    QString newVersionStr = loadSetting("haveNewVersion" , "false");
    QVariant tempValue = newVersionStr;
    bool tempFinished = tempValue.toBool();
    return tempFinished;
}

void UpdateTool::readRemoteSuccess(QString data)
{
    Parse_Seniverse_Now_Json(data);
}

void UpdateTool::readRemoteFailure(QString error)
{
    if(error == "Timeout") {
        emit checkedFinish(4 , "" , "");
    } else {
        emit checkedFinish(3 , error , "");
    }
}

void UpdateTool::setCheckCycle(int cycle)
{
    saveSetting("check_cycle" , QString::number(cycle));
    QDBusInterface iface("org.lingmoos.info.checkcycle",
        "/services/lingmoos_dbus/settingsdbus",
        "",
        QDBusConnection::sessionBus());

    if (iface.isValid()) {
        QDBusReply<QString> reply = iface.call("setCheckCycle",cycle);
        if (reply.isValid()) {
            return;
        }
    }
}

int UpdateTool::getCheckCycle()
{
    QString value = loadSetting("check_cycle", QString::number(24 * 60 * 60 * 1000 * 2));
    return value.toInt();
}

QString UpdateTool::loadSetting(QString key, QString defaultValue)
{
    KSharedConfigPtr profilesConfig = KSharedConfig::openConfig("update_config" , KConfig::SimpleConfig);
    KConfigGroup acProfile(profilesConfig , "UPDATE");
    QString value = acProfile.readEntry(key, defaultValue);
    return value ;
}

QString UpdateTool::saveSetting(QString key, QString value)
{
    KSharedConfigPtr profilesConfig = KSharedConfig::openConfig("update_config" , KConfig::SimpleConfig);
    KConfigGroup acProfile(profilesConfig, "UPDATE");
    acProfile.writeEntry(key, value);
    profilesConfig->sync();
    return "";
}

int UpdateTool::Parse_Seniverse_Now_Json(QString& seniverse_now_json)
{
    QJsonParseError err_rpt;
    QJsonDocument  root_Doc = QJsonDocument::fromJson(seniverse_now_json.toUtf8(), &err_rpt);//字符串格式化为JSON
    if(err_rpt.error != QJsonParseError::NoError) {
        return -1;
    } else {
        QJsonObject root_Obj = root_Doc.object();
        bool newVersion = root_Obj.value("newVersion").toBool();
        qDebug() << "newVersion:::" << newVersion;

        QString changedLog = "\n" ;
        QJsonValue result_Value = root_Obj.value("versionNodeList");
        if(result_Value.isArray()) {

                QJsonObject result_Obj = result_Value.toArray().at(result_Value.toArray().size()-1).toObject();
                QString versionName = result_Obj.value("versionName").toString();
                qDebug() << "VersionNum::: "<<versionName;
                // if(i == result_Value.toArray().size() -1) {
                    valueVersion = versionName;
                // }
                QJsonValue changloglist = result_Obj.value("changeLogList");
                if(changloglist.isArray()) {
                    for(int j = 0 ; j < changloglist.toArray().size() ; j++) {
                        QJsonObject change_Obj = changloglist.toArray().at(j).toObject();
                        QString changeType = change_Obj.value("type").toString();
                        QString changeInfo = change_Obj.value("info").toString();
                        changedLog.append("<b> " + changeType +"</b> <br>");
                        changedLog.append("" + changeInfo +" <br>");
                        changedLog.append("<br>");
                    }
                }
        }

        if(newVersion) {
            saveSetting("haveNewVersion" , "true");
            emit checkedFinish(1 , changedLog , valueVersion);
        } else {
            getAptUpdates();
        }
    }
    return 0;
}

void UpdateTool::receiveDbusUpdatorSigEnd() {
    setUpdating(false);
}

/*****************************************
2:  qaptupdator is not running
0:  qaptupdator is running
    trans is not over
1:  qaptupdator is running
    trans is over
*****************************************/
int UpdateTool::getQaptupdatorUpdateStatus() {
     int value = false;
    QDBusMessage message = QDBusMessage::createMethodCall("com.lingmoos.qaptupdator",
                           "/signals/objects",
                           "com.lingmoos.startup.updating",
                           "updatingStatus");
    QDBusMessage response = QDBusConnection::sessionBus().call(message);
    if (response.type() == QDBusMessage::ReplyMessage) {
        value = response.arguments().takeFirst().toInt();
    } else {
        value = 2;
    }
    return value;
}
