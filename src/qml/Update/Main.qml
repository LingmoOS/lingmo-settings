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

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight  // 有些问题

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LUI.Units.largeSpacing

            RoundedItem {
                RowLayout {
                    spacing: LUI.Units.largeSpacing
                    Item{
                        width: 80
                        height: 80

                        Image {
                            source: "qrc:/images/dark/changes-white"
                            width: parent.width
                            height: parent.height
                            fillMode: Image.PreserveAspectCrop
                            antialiasing: true
                            smooth: true
                            anchors.centerIn: parent
                        }
                    }
                }
            }
        }
    }
}
