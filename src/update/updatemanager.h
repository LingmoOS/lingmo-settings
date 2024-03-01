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

#ifndef UPDATEMANAGER_H
#define UPDATEMANAGER_H

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QPointer>

#include "downloadlistwidget.h"

class UpdateManager : public QObject {
  Q_OBJECT
 private:
  /**
   * @brief 是否有更新
   */
  bool has_updates_;

  std::shared_ptr<QNetworkAccessManager> m_manager;
  DownloadListWidget* dw = nullptr;

 public:
  explicit UpdateManager(QObject* parent = nullptr);

  ~UpdateManager();

  void setDownloadWidget(DownloadListWidget* dw_);

  /**
   * @brief 实现检查更新
   */
  Q_INVOKABLE void check_for_update();

  Q_INVOKABLE bool hasUpdate();

  Q_INVOKABLE void handle_update_data(QNetworkReply* reply);

  /**
   * @brief 获取本地安装包版本数据
   * @return
   */
  Q_INVOKABLE QString getLocalPackageData(const QString &packageName);

 signals:
  void updateDataReply(QString data);
  void addedToProcessingQueue(int index);
  void startInstallingPackage(int index);
  void errorInstallingPackage(int index, int error_code);
  void successfullyInstalledPackage(int index);

  void itemDownloadFinished(int index);
  void itemDownloadError(int index);

 public slots:
  void startCheckforUpdate();
  void requestDownloadandInstall(QString name, QString package_name,
                                 QString url, QString filename, int index);

  void onDownloadFinished(int index);
  void onDownloadProgress(int index, int i);
  void onDownloadError(int index);
};

#endif  // UPDATEMANAGER_H
