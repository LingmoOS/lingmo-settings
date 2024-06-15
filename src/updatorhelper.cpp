/*
 * Copyright (C) 2024 LingmoOS Team.
 *
 * Author:     Kate Leet <kate@lingmoos.com>
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

#include "updatorhelper.h"
#include "upgradeablemodel.h"
#include <QSettings>
#include <QDBusInterface>
#include <QDBusPendingCall>
#include <QTimer>
#include <QDebug>

#include <QLocale>
#include <QFile>
#include <QtNetwork>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>

#include <stdlib.h>

const static QString s_dbusName = "com.lingmo.Session";
const static QString s_pathName = "/Session";
const static QString s_interfaceName = "com.lingmo.Session";

UpdatorHelper::UpdatorHelper(QObject *parent)
    : QObject(parent)
    , m_checkProgress(0)
    , m_backend(new QApt::Backend(this))
    , m_trans(nullptr)
{
    m_backend->init();

    QSettings settings("/etc/os-release",QSettings::IniFormat);
    m_currentVersion = settings.value("PRETTY_NAME").toString();
    
    QSettings lsettings("/var/update/cache/packages.lingmo.org/release/release-notes/20240413225022/zh_CN.UTF-8/changelogs.md",QSettings::IniFormat);
    m_changelogs = lsettings.value("Logs").toString();

    QSettings osbuild("/etc/os-release",QSettings::IniFormat);
    m_versionbuild = settings.value("VERSION_BUILD").toString();

    QLocale locale;
    m_sysLang = QLocale::languageToString(locale.language());

    // QTimer::singleShot(100, this, &UpdatorHelper::checkUpdates);
}

UpdatorHelper::~UpdatorHelper()
{
}

QString UpdatorHelper::buildver()
{
    return m_versionbuild;
}

void UpdatorHelper::checkUpdates()
{
    if (m_trans)
        return;

    m_checkProgress = 0;
    m_trans = m_backend->updateCache();
    m_trans->setLocale(QLatin1String(setlocale(LC_MESSAGES, 0)));

    connect(m_trans, &QApt::Transaction::progressChanged, this, [=] (int progress) {
        m_checkProgress = progress <= 100 ? progress : 100;
        emit checkProgressChanged();
    });

    connect(m_trans, &QApt::Transaction::statusChanged, this, [=] (QApt::TransactionStatus status) {
        switch (status) {
        case QApt::RunningStatus: {
            break;
        }
        
        case QApt::FinishedStatus: {
            m_backend->reloadCache();

            bool success = m_trans->error() == QApt::Success;
            QString errorDetails = m_trans->errorDetails();

            m_trans->cancel();
            m_trans->deleteLater();
            m_trans = nullptr;

            if (success) {
                qDebug() << m_sysLang;
                QUrl url("https://packages.lingmo.org/release/release-notes/" + m_versionbuild + "/" + m_sysLang + "/" + "changelog.html");
                QNetworkRequest request(url);
                QNetworkAccessManager manager;
                QNetworkReply *reply = manager.get(request);

                // 接收服务器的响应
                QObject::connect(reply, &QNetworkReply::finished, [&] {
                    if (reply->error() == QNetworkReply::NoError) {
                        // 保存下载的文件数据
                        QFile file("/var/update/cache/changelog.html");
                        file.open(QIODevice::WriteOnly);
                        file.write(reply->readAll());
                        file.close();

                        qDebug() << "changelog downloaded successfully";
                    } else {
                        qDebug() << "Error downloading file:" << reply->errorString();
                    }
                });
                
                // Add packages.
                for (QApt::Package *package : m_backend->upgradeablePackages()) {
                    if (!package)
                        continue;

                    UpgradeableModel::self()->addPackage(package->name(),
                                                         package->availableVersion(),
                                                         package->downloadSize());
                }

                emit checkUpdateFinished();
            } else {
                emit checkError(errorDetails);
            }

            break;
        }
        default:
            break;
        }
    });

    m_trans->run();
}

/**
 * @brief Starts the upgrade process.
 *
 * This function starts the upgrade process by creating a transaction object and running it.
 * The status of the transaction is monitored using the statusChanged() and statusDetailsChanged() signals.
 * If the upgrade is successful, the system is rebooted using the reboot() function.
 *
 * @return True if the upgrade was successful, false otherwise.
 */
void UpdatorHelper::upgrade()
{
    if (m_trans) {
        return;
    }

    m_statusDetails.clear();
    m_trans = m_backend->upgradeSystem(QApt::FullUpgrade);
    m_trans->setLocale(QLatin1String(setlocale(LC_MESSAGES, 0)));

    connect(m_trans, &QApt::Transaction::statusDetailsChanged, this, [=] (const QString &statusDetails) {
        m_statusDetails.append(statusDetails + "\n");
        emit statusDetailsChanged();
    });

    connect(m_trans, &QApt::Transaction::statusChanged, this, [=] (QApt::TransactionStatus status) {
        switch (status) {
        case QApt::RunningStatus: {
            emit startingUpdate();
            break;
        }
        case QApt::FinishedStatus: {
            bool success = m_trans->error() == QApt::Success;

            m_trans->cancel();
            m_trans->deleteLater();
            m_trans = nullptr;

            if (success) {
                emit updateFinished();
            } else {
                emit updateError();
            }

            break;
        }
        default:
            break;
        }
    });

    m_trans->run();
}

void UpdatorHelper::reboot()
{
    QDBusInterface iface(s_dbusName, s_pathName, s_interfaceName, QDBusConnection::sessionBus());

    if (iface.isValid()) {
        iface.call("reboot");
    }
}

QString UpdatorHelper::version()
{
    return m_currentVersion;
}

QString UpdatorHelper::changelogs()
{
    return m_changelogs;
}

QString UpdatorHelper::statusDetails()
{
    return m_statusDetails;
}

int UpdatorHelper::checkProgress()
{
    return m_checkProgress;
}
