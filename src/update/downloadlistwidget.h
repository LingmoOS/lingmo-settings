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

#ifndef DOWNLOADLISTWIDGET_H
#define DOWNLOADLISTWIDGET_H

#include <QObject>
#include <QTimer>

#include "download_item.h"
#include "downloadworker.h"

class DownloadListWidget : public QObject {
  Q_OBJECT

 public:
  DownloadItem *addItem(QString name, QString fileName, QString pkgName,
                        QString downloadurl, int index);
  int nowDownload = 0;
  int allDownload = 0;
  int toDownload = 0;
  QList<DownloadItem *> getDIList();
  QList<QString> getUrlList();
  void m_move(int x, int y);
  explicit DownloadListWidget(QObject *parent = nullptr);
  ~DownloadListWidget() override;

  bool isDownloadInProcess();

 private:
  int isdownload = false;
  bool isBusy = false;
  QStringList dlist;
  QList<QString> urList;
  QList<int> indexList;
  QList<DownloadItem *> downloaditemlist;
  DownloadController *downloadController = nullptr;
  int nowdownload = 0;
  QString theSpeed;
  QTimer download_speed;
  long download_size = 0;
  long size1 = 0;
  long size2 = 0;
  void startRequest(QString url, QString fileName, int index);
  void httpFinished(int index);
  void updateDataReadProgress(int index, QString speedInfo, qint64 bytesRead, qint64 totalBytes);
  void clearItem();

 signals:
  void downloadFinished(int index);
  void downloadProgress(int index, int i);
  void downloadError(int index);

 private slots:
  void slotInstallFinished(bool success);
};

#endif  // DOWNLOADLISTWIDGET_H
