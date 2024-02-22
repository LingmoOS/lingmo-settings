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
    property bool hasupdate_: true

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LUI.Units.largeSpacing

            // 状态栏
            RoundedItem {
                Layout.fillWidth: true
                height: 100
                RowLayout {
                    spacing: LUI.Units.largeSpacing

                    Item {
                        width: 80
                        height: 80

                        Image {
                            source: LUI.Theme.darkMode ? "qrc:/images/dark/changes-white" : "qrc:/images/light/changes"
                            width: parent.width
                            height: parent.height
                            fillMode: Image.PreserveAspectCrop
                            antialiasing: true
                            smooth: true
                            anchors.centerIn: parent
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Center promote text
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Label {
                                id: updateText
                                text: qsTr("You're up to date")
                                Layout.fillHeight: true
                                width: parent.width
                                font.pointSize: 20
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                            }

                            Label {
                                id: updateCheckTimeText
                                text: "Last checked: Today, 18:37"
                                Layout.fillHeight: true
                                width: parent.width
                                font.pointSize: 10
                                font.bold: false
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                            }
                        }
                    }


                    Button {
                        width: 40
                        text: qsTr("Check for updates")
                    }
                }
            }

            // 更新列表
            RoundedItem {
                id: updateListRoot
                visible: control.hasupdate_ // 有更新才显示列表
                UpdateItemsView {
                    Layout.fillWidth: true
                    // visible: enabledConnections.wirelessHwEnabled
                }
            }
        }

    }
}


