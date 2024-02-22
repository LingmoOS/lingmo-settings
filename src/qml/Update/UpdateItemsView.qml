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

        model: ListModel {
            id: updateListModel
        }

        delegate: UpdateItem {
                width: ListView.view.width
            }
    }

    Component.onCompleted: {
        let data = [
                {
                    name: "LingmoOS Insider Preview 3.0",
                    status: "Pending install",
                    additional_info: "This update improves user experience and system stablity."
                },
                {
                    name: "LingmoOS Insider Preview 3.0",
                    status: "Pending install",
                    additional_info: "This update improves user experience and system stablity."
                },
                {
                    name: "LingmoOS Insider Preview 3.0",
                    status: "Pending install",
                    additional_info: "This update improves user experience and system stablity."
                }
        ];
        updateListModel.append(data);
    }
}
