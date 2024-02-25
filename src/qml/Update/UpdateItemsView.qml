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
import "../"

import LingmoUI 1.0 as LingmoUI

ColumnLayout {
    id: updateItemsLayout
    spacing: LingmoUI.Units.largeSpacing

    Label {
        id: updateListLabel
        text: qsTr("Available Updates")
        color: LingmoUI.Theme.disabledTextColor
    }

    ListView {
        id: updateListView
        Layout.fillWidth: true
        Layout.preferredHeight: {
            var totalHeight = 0
            for (var i = 0; i < updateListView.visibleChildren.length; ++i) {
                totalHeight += updateListView.visibleChildren[i].height
            }
            return totalHeight
        }
        clip: true
        spacing: 0
        interactive: false
        visible: true

        model: control.updateListModel

        delegate: UpdateItem {
                width: ListView.view.width
            }
    }

    function slotAddedToProcessingQueue(index) {
        control.updateListModel.setProperty(index, "status", qsTr("Processing"));
    }

    function slotItemDownloadError(index) {
        control.updateListModel.setProperty(index, "status", qsTr("Download error"));
        control.processed_updates += 1;
        control.has_error_ = true;
    }

    function slotItemDownloadFinished(index) {
        control.updateListModel.setProperty(index, "status", qsTr("Download finished"));
    }

    function slotStartInstallingPackage(index) {
        control.updateListModel.setProperty(index, "status", qsTr("Start installing"));
    }

    function slotErrorInstallingPackage(index, code) {
        control.updateListModel.setProperty(index, "status", qsTr("Installation error"));
        control.processed_updates += 1;
        control.has_error_ = true;
        console.log("Update error code:" + code + " index: " + index);
    }

    function slotSuccessfullyInstalledPackage(index) {
        control.updateListModel.setProperty(index, "status", qsTr("Successfully installed"));
        control.processed_updates += 1;
    }
}
