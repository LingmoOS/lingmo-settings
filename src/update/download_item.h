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

#ifndef DOWNLOADITEM_H
#define DOWNLOADITEM_H

#include <QObject>

class DownloadItem : public QObject {
  Q_OBJECT
 public:
  /**
   * @brief DownloadItem - 负责下载和安装一个软件包
   * @param index - 项目在ListModel中的索引
   * @param package_name - 软件包名称
   * @param parent
   */
  explicit DownloadItem(int index, QString package_name,
                        QObject *parent = nullptr);

  ~DownloadItem() override;

  /**
   * @brief setValue - 设置下载显示进度
   * @param index - 下载项目在ListModel中的索引
   * @param value - 进度百分比
   */
  void setValue(int value);

  /**
   * @brief setValue - 设置下载显示进度为100%
   * @param index - 下载项目在ListModel中的索引
   */
  void setMax(int max);

  /**
   * @brief setName - 设置项目的显示名称（即name）
   * @param index - 下载项目在ListModel中的索引
   * @param name - 需要设置的项目名称
   */
  void setName(int index, QString name);

  /**
   * @brief setPkgName - 设置项目的包名称（即package_name）
   * @param index - 下载项目在ListModel中的索引
   * @param name - 需要设置的项目名称
   */
  void setPkgName(int index, QString name);

  /**
   * @brief setFileName - 设置下载文件名
   * @param name
   */
  void setFileName(QString name);

  /**
   * @brief getFileName - 获取下载文件名
   */
  inline QString getFileName() { return filename_; }

  /**
   * @brief 检测是否准备好安装软件包
   * @note 如果正在安装，返回-1
   */
  int readyInstall();

  /**
   * @brief closeDownload - 取消下载
   */
  void closeDownload();

  /**
   * @brief install - 安装当前应用
   * @param t - 安装方式，可以为 0,1,2
   * @note
   * 请不要直接调用此函数！请调用readyInstall。
   * 执行这个函数时，需要已经检查是否可以安装，但该函数仍然会再检测一次！
   * @example: DownloadItem::install(0);
   */
  void install(int t);

  /**
   *  @brief slotAsyncInstall - 实际安装应用
   *  @param t - t为安装方式，可以为 0,1,2
   *  @example: slotAsyncInstall(0);
   */
  void slotAsyncInstall(int t);

  /**
   * @brief speed - 下载速度
   */
  QString speed;

  bool free;

  /**
   * @brief downloadCancelled_ - 下载是否被取消
   */
  bool downloadCancelled_;

  bool downloadStatus_;

 private:
  /**
   * @brief index_ - 在ListModel中的序号
   */
  int index_;

  /**
   * @brief package_name_ - 软件包名
   */
  QString name_;

  /**
   * @brief package_name_ - 软件包名
   */
  QString package_name_;

  /**
   * @brief isInstall_ - 是否正在安装
   */
  bool isInstall_;

  /**
   * @brief out - 安装输出
   */
  QString out;

  /**
   * @brief filename_ - 下载文件名
   */
  QString filename_;

 signals:
  /**
   * @brief changePercentValue - 下载进度改变信号
   * @param index - 下载项目在ListModel中的索引
   * @param value - 进度百分比值
   */
  void changePercentValue(int index, int value);

  /**
   * @brief startInstallPackage - 开始安装软件包信号
   * @param index - 下载项目在ListModel中的索引
   * @param name - 项目名称
   */
  void startInstallPackage(int index, QString name);

  /**
   * @brief finishedInstallPackage - 成功完成安装信号
   */
  void finishedInstallPackage(int index, QString name);

  /**
   * @brief errorInstallPackage - 安装出错信号
   * @note 允许发送重试信号
   * @param error_code - 错误代码
   */
  void errorInstallPackage(int index, QString name, int error_code = 0);

  /**
   * @brief finished - 成功结束信号
   * @param status
   */
  void finished(int status, int index);
};

#endif  // DOWNLOADITEM_H
