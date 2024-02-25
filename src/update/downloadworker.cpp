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

#include "downloadworker.h"

#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QThread>
#include <QtConcurrent>

#include "server_config.h"
#define MAXWAITTIME 200000

DownloadController::DownloadController(QObject *parent) {
  Q_UNUSED(parent)

  // 初始化默认域名
  domains.clear();
  domains.append(DEFAULTURL);

  this->threadNum = domains.size();
}

void DownloadController::setFilename(QString filename) {
  this->filename = filename;
}

void gennerateDomain(QVector<QString> &domains) {
  // ToDo: 目前没有做选择软件源功能
  //  QFile serverList(
  //      QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) +
  //      "/server.list");
  //  if (serverList.open(QFile::ReadOnly)) {
  //    QStringList list = QString(serverList.readAll()).trimmed().split("\n");
  //    qDebug() << list << list.size();
  domains.clear();

  //    for (int i = 0; i < list.size(); i++) {
  //      if (list.at(i).contains("镜像源 Download only") && i + 1 <
  //      list.size()) {
  //        for (int j = i + 1; j < list.size(); j++) {
  //          domains.append(list.at(j));
  //        }
  //        break;
  //      }
  //    }
  //    if (domains.size() == 0) {
  //      domains.append(DEFAULTURL);
  //    }
  //  } else {
  domains.append(DEFAULTURL);
  //  }
}

/**
 * @brief 开始下载
 */
void DownloadController::startDownload(const QString &url, int index) {
  // 获取下载任务信息
  fileSize = getFileSize(url);
  if (fileSize == 0) {
    emit errorOccur(index, "文件大小获取失败");
    return;
  }

  QtConcurrent::run([=, this]()  {
    gennerateDomain(domains);
    qDebug() << domains << domains.size();

    QString aria2Command = "-d";                          // 下载目录
    QString aria2Urls = "";                               // 下载地址
    QString aria2Verbose = "--summary-interval=1";        // 显示下载速度
    QString aria2SizePerThreads = "--min-split-size=1M";  // 最小分片大小
    QString aria2NoConfig = "--no-conf";     // 不使用配置文件
    QString aria2NoSeeds = "--seed-time=0";  // 不做种

    QStringList command;

    QString downloadDir = "/tmp/lingmo-settings/";  // 下载目录
    QString aria2ConnectionPerServer =
        "--max-connection-per-server=1";  // 每个服务器最大连接数
    QString aria2ConnectionMax =
        "--max-concurrent-downloads=16";  // 最大同时下载数

    // command.append(metaUrl.toUtf8());

    for (const auto & domain : domains) {  // 遍历域名
      command.append(replaceDomain(url, domain)
                         .replace("+", "%2B")
                         .toUtf8());  // 对+进行转译，避免oss出错
    }

    qint64 downloadSizeRecord = 0;  // 下载大小记录
    qint8 failDownloadTimes = 0;    // 记录重试次数
    const qint8 maxRetryTimes = 3;  // 最大重试次数
    QString speedInfo = "";         // 显示下载速度
    QString percentInfo = "";       // 显示下载进度
    command.append(aria2Command.toUtf8());
    command.append(downloadDir.toUtf8());
    command.append(aria2Verbose.toUtf8());
    command.append(aria2NoConfig.toUtf8());
    command.append(aria2SizePerThreads.toUtf8());
    command.append(aria2ConnectionPerServer.toUtf8());
    command.append(aria2ConnectionMax.toUtf8());

    qDebug() << command;

    bool downloadSuccess = true;
    QProcess cmd;
    cmd.setProcessChannelMode(QProcess::MergedChannels);
    cmd.setProgram("aria2c");
    cmd.setArguments(command);
    //cmd.start();
    cmd.waitForStarted(-1);  // 等待启动完成

    // Timer
    auto timeoutTimer = new QTimer();
    timeoutTimer->setSingleShot(true);  // 单次触发
    connect(timeoutTimer, &QTimer::timeout, [&]() {
      if (failDownloadTimes < maxRetryTimes) {
        qDebug() << "Download timeout, restarting...";
        // 重新启动下载任务的代码
        restartDownload(cmd, command);  // 调用重新启动下载任务的函数
        failDownloadTimes += 1;
        timeoutTimer->start(MAXWAITTIME);  // 重新启动定时器
      } else {
        emit errorOccur(index, tr("Download Failed, please retry :("));  // 下载失败
        downloadSuccess = false;
        cmd.close();
        cmd.terminate();        // 终止当前的下载进程
        cmd.waitForFinished();  // 等待进程结束
      }
    });


    connect(&cmd, &QProcess::readyReadStandardOutput, [&]() {
      timeoutTimer->start(MAXWAITTIME);  // 重置超时计时器，15秒超时
      // 通过读取输出计算下载速度
      QString message = cmd.readAllStandardOutput().data();
      message = message.replace(" ", "");
      QStringList list;
      qint64 downloadSize = 0;
      int downloadSizePlace1 = message.indexOf("(");
      int downloadSizePlace2 = message.indexOf(")");
      int speedPlace1 = message.indexOf("DL:");
      int speedPlace2 = message.indexOf("ETA");
      if (downloadSizePlace1 != -1 && downloadSizePlace2 != -1) {
        percentInfo = message
                          .mid(downloadSizePlace1 + 1,
                               downloadSizePlace2 - downloadSizePlace1 - 1)
                          .replace("%", "");
        if (percentInfo != "s") {
          int percentInfoNumber = percentInfo.toUInt();

          downloadSize = percentInfoNumber * fileSize / 100;
        }
      }
      if (speedPlace1 != -1 && speedPlace2 != -1 &&
          speedPlace2 - speedPlace1 <= 15) {
        speedInfo = message.mid(speedPlace1 + 3, speedPlace2 - speedPlace1 - 3);
        speedInfo += "/s";
      }
      if (downloadSize >= downloadSizeRecord) {
        downloadSizeRecord = downloadSize;
        timeoutTimer->stop();  // 如果有进度，停止超时计时器
      }
      if (percentInfo == "OK") {
        finished = true;
        emit downloadProcess(index, "", fileSize, fileSize);
        qDebug() << "finished:" << finished;
      } else {
        emit downloadProcess(index, speedInfo, downloadSizeRecord, fileSize);
      }
    });
    connect(&cmd, &QProcess::readyReadStandardError, [&]() {
      emit errorOccur(index, cmd.readAllStandardError().data());
      downloadSuccess = false;
      cmd.close();
    });

    connect(&cmd, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), [&](int exitCode, QProcess::ExitStatus exitStatus) {
      if (exitCode) {
        emit errorOccur(index, "下载程序异常退出");
        downloadSuccess = false;
        cmd.close();
      }
    });

    cmd.start();

    pidNumber = cmd.processId();

    cmd.waitForFinished(-1);
    cmd.close();

    if (!downloadSuccess) {
      return;
    }

    emit downloadFinished(index);
  });
}

/**
 * @brief 停止下载
 */
void DownloadController::stopDownload() {
  if (pidNumber < 0) {
    return;
  }

  // 实现下载进程退出
  QString killCmd = QString("kill -9 %1").arg(pidNumber);
  system(killCmd.toUtf8());
  qDebug() << "kill aria2!";
  pidNumber = -1;
}

void DownloadController::restartDownload(QProcess &cmd,
                                         const QStringList &command) {
  cmd.terminate();            // 终止当前的下载进程
  cmd.waitForFinished();      // 等待进程结束
  cmd.setArguments(command);  // 重新设置参数
  cmd.start();                // 重新启动下载
  cmd.waitForStarted(-1);     // 等待启动完成
}

qint64 DownloadController::getFileSize(const QString &url) {
  // 已经无需使用 qtnetwork 再获取 filesize，完全交给 aria2 来计算进度。
  // 为保证兼容性，故保留此函数。
  qDebug() << "Begin download:" << url;
  qint64 fileSize = 10000;
  return fileSize;
}

QString DownloadController::replaceDomain(QString url,
                                          const QString domain) {
  QRegularExpression regex(
      R"((?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9])");
  if (regex.match(url).hasMatch()) {
    return QString(url).replace(regex.match(url).captured(), domain);
  }
  return url;
}
