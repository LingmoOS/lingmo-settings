/*
 * Copyright (C) 2024 LingmoOS Team.
 *
 * Modifier: Elysia <c.elysia@foxmail.com>
 *
 * Original Author: Copyright (C) 2023 The Spark Community
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

#ifndef DOWNLOADWORKER_H
#define DOWNLOADWORKER_H

#include <QObject>
#include <QProcess>
#include <QVector>

class DownloadController : public QObject {
  Q_OBJECT

 public:
  explicit DownloadController(QObject *parent = nullptr);

  void setFilename(QString filename);
  void startDownload(const QString &url, int index);
  void stopDownload();
  void restartDownload(QProcess &cmd, const QStringList &command);
  qint64 getFileSize(const QString &url);
  QString replaceDomain(QString url, const QString domain);

 signals:
  void errorOccur(int index, const QString &msg);
  void downloadProcess(int, QString, qint64, qint64);
  void downloadFinished(int);

 private:
  int threadNum;
  qint64 pidNumber = -1;
  QString filename;
  qint64 fileSize;
  QVector<QPair<qint64, qint64>> ranges;
  bool finished = false;
  QVector<QString> domains;
};

#endif  // FILEDOWNLOADWORKER_H
