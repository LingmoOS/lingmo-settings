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

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI 1.0 as LUI
import Lingmo.Settings 1.0
import "../"

ItemPage {
    id: control
    headerTitle: qsTr("System Update")

    // Whether updates are available
    property bool hasupdate_: false

    property bool isupdating: false

    property bool ischeckingupdate: false

    property int processed_updates: 0

    property int available_updates: 0

    property bool has_error_: false

    property var mUpdateManager: UpdateManager {}

    property var updateListModel: ListModel {}

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LUI.Units.largeSpacing

            // 状态栏
            RoundedItem {
                UpdateTitleBar {
                    id: updateTitlebar
                    Layout.fillWidth: true
                    height: 100
                }
            }

            // 更新列表
            RoundedItem {
                id: updateListRoot
                visible: control.hasupdate_ || control.has_error_ // 有更新或错误才显示列表
                UpdateItemsView {
                    id: updateItemsView
                    Layout.fillWidth: true
                }
            }
        }

    }

    onProcessed_updatesChanged: {
        if (control.processed_updates >= control.available_updates) {
            control.isupdating = false;
            control.available_updates = 0;
            control.processed_updates = 0;
            control.hasupdate_ = false;
        }
    }

    Component.onCompleted: {
        // 注册信号槽
        updateTitlebar.onSendCheckUpdate.connect(control.mUpdateManager.startCheckforUpdate);
        updateTitlebar.onRequestDownloadandInstall.connect(control.mUpdateManager.requestDownloadandInstall);

        control.mUpdateManager.onAddedToProcessingQueue.connect(updateItemsView.slotAddedToProcessingQueue);
        control.mUpdateManager.onItemDownloadError.connect(updateItemsView.slotItemDownloadError);
        control.mUpdateManager.onItemDownloadFinished.connect(updateItemsView.slotItemDownloadFinished);
        control.mUpdateManager.onSuccessfullyInstalledPackage.connect(updateItemsView.slotSuccessfullyInstalledPackage);
        control.mUpdateManager.onErrorInstallingPackage.connect(updateItemsView.slotErrorInstallingPackage)
    }


    function handle_update_data(data) {
        control.mUpdateManager.onUpdateDataReply.disconnect(control.handle_update_data);
        // 解析版本信息
        let update_info = JSON.parse(data);
        let update_list = compare_version(update_info);

        // 初始化ListModel，清空旧数据
        control.updateListModel.clear();
        control.updateListModel.append(update_list);
        control.hasupdate_ = true;
        control.ischeckingupdate = false;
    }

    function compare_version(json_data) {
        let data_root = json_data.data;

        let update_list = [];
        // ToDo: 进行版本信息比较
        // for ....
        data_root.forEach((element) => {
            // 调用C++中的方法比较远程中的版本号和本地的
            // 先跳过

            // 初始化状态信息
            element.status = "Queued";
            update_list.push(element);
        });

        control.available_updates = update_list.length;
        return update_list;
    }
}


