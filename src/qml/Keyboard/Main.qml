/*
 * Copyright (C) 2026 LingmoOS Team.
 *
 * Author:     devalexandre <alexandre@dev2learn.com>
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import "../"

ItemPage {
    headerTitle: qsTr("Keyboard")

    KeyboardLayouts {
        id: keyboard
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing * 2

            RoundedItem {
                RowLayout {
                    Label {
                        text: qsTr("Input layouts")
                        font.pointSize: LingmoUI.Units.fontSubheading
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("Add layout")
                        icon.name: "list-add"
                        flat: true
                        // XKB holds at most four layouts
                        enabled: keyboard.available && keyboard.layouts.length < 4
                        onClicked: addDialog.show()
                    }
                }

                Label {
                    visible: !keyboard.available
                    text: qsTr("The settings service is not running")
                    color: LingmoUI.Theme.secondaryTextColor
                }

                Repeater {
                    id: layoutRepeater
                    model: keyboard.layouts

                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: row.implicitHeight + LingmoUI.Units.smallSpacing * 2

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: -LingmoUI.Units.smallSpacing
                            anchors.rightMargin: -LingmoUI.Units.smallSpacing
                            radius: LingmoUI.Theme.mediumRadius
                            color: rowMouse.containsMouse ? LingmoUI.Theme.hoverColor : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: LingmoUI.Units.veryShortDuration }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        RowLayout {
                            id: row
                            anchors.fill: parent
                            spacing: LingmoUI.Units.largeSpacing

                            // Short name, as shown in the status bar
                            Rectangle {
                                implicitWidth: 44
                                implicitHeight: codeLabel.implicitHeight + LingmoUI.Units.smallSpacing * 1.5
                                radius: 6
                                color: LingmoUI.Theme.hoverColor
                                border.width: 1
                                border.color: LingmoUI.Theme.borderColor

                                Label {
                                    id: codeLabel
                                    anchors.centerIn: parent
                                    text: keyboard.shortNames[index] || modelData
                                    font.weight: Font.DemiBold
                                }
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Label {
                                    text: keyboard.descriptions[index]
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: index === 0 ? qsTr("Default") : modelData
                                    color: LingmoUI.Theme.secondaryTextColor
                                    font.pointSize: LingmoUI.Units.fontCaption
                                    Layout.fillWidth: true
                                }
                            }

                            ToolButton {
                                icon.name: "go-up"
                                enabled: index > 0
                                ToolTip.text: qsTr("Move up")
                                ToolTip.visible: hovered
                                onClicked: keyboard.move(index, index - 1)
                            }

                            ToolButton {
                                icon.name: "go-down"
                                enabled: index < layoutRepeater.count - 1
                                ToolTip.text: qsTr("Move down")
                                ToolTip.visible: hovered
                                onClicked: keyboard.move(index, index + 1)
                            }

                            ToolButton {
                                icon.name: "edit-delete"
                                enabled: layoutRepeater.count > 1
                                ToolTip.text: qsTr("Remove")
                                ToolTip.visible: hovered
                                onClicked: keyboard.remove(index)
                            }
                        }
                    }
                }
            }

            RoundedItem {
                Label {
                    text: qsTr("Switch layouts with")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                ComboBox {
                    id: switchCombo
                    Layout.fillWidth: true
                    model: keyboard.switchOptions
                    textRole: "name"
                    leftPadding: LingmoUI.Units.largeSpacing
                    rightPadding: LingmoUI.Units.largeSpacing
                    topInset: 0
                    bottomInset: 0
                    currentIndex: {
                        for (var i = 0; i < keyboard.switchOptions.length; ++i)
                            if (keyboard.switchOptions[i].id === keyboard.switchOption)
                                return i
                        return -1
                    }
                    onActivated: keyboard.setSwitchOption(keyboard.switchOptions[currentIndex].id)
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: LingmoUI.Theme.secondaryTextColor
                    text: qsTr("With more than one layout, the status bar shows the current one: click it to switch, or right click to pick one.")
                }
            }

            Item {
                height: LingmoUI.Units.largeSpacing
            }
        }
    }

    Popup {
        id: addDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 440
        height: 460
        modal: true
        focus: true
        padding: LingmoUI.Units.largeSpacing * 1.5

        function show() {
            searchField.text = ""
            results.model = keyboard.search("")
            visible = true
            searchField.forceActiveFocus()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing

            Label {
                text: qsTr("Add layout")
                font.weight: Font.DemiBold
                font.pointSize: LingmoUI.Units.fontHeading
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("Search (e.g. Portuguese, us)")
                onTextChanged: results.model = keyboard.search(text)
            }

            ListView {
                id: results
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                ScrollBar.vertical: ScrollBar {}

                delegate: ItemDelegate {
                    width: ListView.view.width
                    text: modelData.description
                    onClicked: {
                        keyboard.add(modelData.id)
                        addDialog.close()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    onClicked: addDialog.close()
                }
            }
        }
    }
}
