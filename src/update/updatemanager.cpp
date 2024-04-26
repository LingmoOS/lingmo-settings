/*
 * Copyright (C) 2024 LingmoOS Team.
 *
 * Author:     Elysia <c.elysia@foxmail.com>
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

#include "updatemanager.h"

#include <QSysInfo>
#include <QtConcurrent>

#include "server_config.h"

UpdateManager::UpdateManager(QObject* parent) : QObject{parent} {
  m_manager = std::make_shared<QNetworkAccessManager>();
  setDownloadWidget(new DownloadListWidget);

  // 注册信号槽
  connect(dw, &DownloadListWidget::downloadError, this,
          &UpdateManager::onDownloadError, Qt::QueuedConnection);
  connect(dw, &DownloadListWidget::downloadFinished, this,
          &UpdateManager::onDownloadFinished, Qt::QueuedConnection);
  connect(dw, &DownloadListWidget::downloadProgress, this,
          &UpdateManager::onDownloadProgress, Qt::QueuedConnection);
}

UpdateManager::~UpdateManager() { dw->deleteLater(); }

void UpdateManager::check_for_update() {
  // 替换为真正的处理函数，待处理
  QString url = "https://packages.lingmo.org/update/api/updates.php";
  auto req = new QNetworkRequest(QUrl(url));
  connect(m_manager.get(), SIGNAL(finished(QNetworkReply*)), this,
          SLOT(handle_update_data(QNetworkReply*)));
  m_manager->get(*req);
}

bool UpdateManager::hasUpdate() { return has_updates_; }

void UpdateManager::handle_update_data(QNetworkReply* reply) {
  if (reply->url() == QUrl("https://packages.lingmo.org/update/api/updates.php")) {
    emit updateDataReply(reply->readAll());
  }
  reply->deleteLater();
}

void UpdateManager::startCheckforUpdate() { this->check_for_update(); }

void UpdateManager::requestDownloadandInstall(QString name,
                                              QString package_name, QString url,
                                              QString filename, int index) {
  qDebug() << name << " " << package_name << " " << index << " " << url;

  // 需要按实际修改
  QString downloadUrl = QString(DEFAULTURL) +
                        QSysInfo::currentCpuArchitecture() + "/distroversion" +
                        package_name;

  // addItem 后自动下载安装
  DownloadItem* item = dw->addItem(name, filename, package_name, url, index);

  if (item == nullptr) {
    return;
  }

  connect(item, &DownloadItem::finished, [=, this](int status, int index) {
    if (status) {
      // 安装成功
      emit successfullyInstalledPackage(index);
    } else {
      // 出错了
      emit errorInstallingPackage(index, 0x03);
    }
  });
  connect(item, &DownloadItem::startInstallPackage,
          [=, this](int index_, QString name) {
            emit startInstallingPackage(index_);
          });
  connect(item, &DownloadItem::errorInstallPackage,
          [=, this](int index_, QString name, int error_code) {
            emit errorInstallingPackage(index_, error_code);
          });

  emit addedToProcessingQueue(index);
}

void UpdateManager::setDownloadWidget(DownloadListWidget* dw_) {
  if (dw) {
    dw->deleteLater();
    dw = nullptr;
  }
  dw = dw_;
};

void UpdateManager::onDownloadFinished(int index) {
  emit itemDownloadFinished(index);
}
void UpdateManager::onDownloadProgress(int index, int i) {}
void UpdateManager::onDownloadError(int index) {
  emit itemDownloadError(index);
}

QString UpdateManager::getLocalPackageData(const QString& packageName) {
  QProcess dpkg;
  dpkg.start("dpkg", QStringList() << "-s" << packageName);
  dpkg.waitForFinished();  // 等待命令执行完毕

  int exitCode = dpkg.exitCode();
  QString output = dpkg.readAllStandardOutput();
  QString errorOutput = dpkg.readAllStandardError();

  // 根据返回的退出码判断 dpkg -s 命令是否执行成功
  if (exitCode == 0) {
    // 命令成功执行，解析输出以获取版本信息
    QStringList lines = output.split("\n");
    foreach (const QString& line, lines) {
      if (line.startsWith("Version:")) {
        return line.split(":").at(1).trimmed();  // 提取版本号
      }
    }
  } else {
    // 错误输出中通常包含 "is not installed" 说明软件包未安装
    if (errorOutput.contains("is not installed")) {
      return "inf";  // 软件包未安装
    }
  }

  return "inf";  // 默认返回 inf
}
