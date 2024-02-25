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

#include "download_item.h"

#include <QDebug>
#include <QProcess>
#include <QtConcurrent>

DownloadItem::DownloadItem(int index, QString package_name, QObject *parent)
    : QObject{parent},
      index_{index},
      package_name_{package_name},
      isInstall_{false},
      downloadCancelled_{false} {}

DownloadItem::~DownloadItem() = default;

void DownloadItem::setValue(int value) {
  emit changePercentValue(index_, value);
};

void DownloadItem::setMax(int max) { emit changePercentValue(index_, max); };

void DownloadItem::setName(int index, QString name) { this->name_ = name; };

void DownloadItem::setPkgName(int index, QString name) {
  this->package_name_ = name;
};

void DownloadItem::setFileName(QString name) { filename_ = name; }

void DownloadItem::closeDownload() {
  downloadStatus_ = 2;
  downloadCancelled_ = true;
}

int DownloadItem::readyInstall() {
  // 检查是否正在安装，如果是返回错误 -1
  if (isInstall_) {
    return -1;
  }

  if (!downloadCancelled_) {
    DownloadItem::install(0);
    return 1;
  }

  return 0;
}

void DownloadItem::install(int t) {
  if (!isInstall_) {
    isInstall_ = true;
    qDebug() << "/tmp/lingmo-settings/" + this->filename_;
    startInstallPackage(index_, this->package_name_);
    QtConcurrent::run([=, this]() { slotAsyncInstall(t); });
  }
}

void DownloadItem::slotAsyncInstall(int t) {
  QProcess installer;
  switch (t) {
    case 0:
      installer.start(
          "pkexec",
          QStringList()
              << "/usr/share/lingmo-settings/tools/lminstall/lminstall"
              << "/tmp/lingmo-settings/" + filename_
              << "--delete-after-install");
      break;
    case 1:
      installer.start("lingmo-debinstaller",
                      QStringList() << "/tmp/lingmo-settings/" + filename_);
      break;
    case 2:
      installer.start("pkexec", QStringList()
                                    << "gdebi"
                                    << "-n"
                                    << "/tmp/lingmo-settings/" + filename_);
      break;
  }

  bool haveError = false;
  bool notRoot = false;
  installer.waitForFinished(-1);  // 不设置超时
  out = installer.readAllStandardOutput();

  QStringList everyOut = out.split("\n");
  QString tempOutput;
  for (int i = 0; i < everyOut.size(); i++) {
    tempOutput = everyOut[i];
    if (everyOut[i].left(2) == tempOutput.contains("OMG-IT-GOES-WRONG")) {
      haveError = true;
    }
    if (tempOutput.contains("Not authorized")) {
      notRoot = true;
    }
  }

  // 检查是否安装了
  QProcess isInstall;
  // 如果获取软件包名称的方法更改，这里也要改
  isInstall.start("dpkg", QStringList() << "-s" << package_name_);
  isInstall.waitForFinished(180 * 1000);  // 默认超时 3 分钟
  int error =
      QString::fromStdString(isInstall.readAllStandardError().toStdString())
          .length();
  if (error == 0 && !haveError) {
    // 成功完成安装
    emit finishedInstallPackage(index_, package_name_);
    downloadStatus_ = 3;
  } else {
    // 出错了，可以重试
    downloadStatus_ = 1;
    emit errorInstallPackage(index_, package_name_, 0x01);
  }

  if (notRoot) {
    // 没有Root权限
    emit errorInstallPackage(index_, package_name_, 0x02);
  }

  isInstall_ = false;

  installer.deleteLater();
  isInstall.deleteLater();

  emit finished(error == 0 && !haveError && !notRoot, index_);
}
