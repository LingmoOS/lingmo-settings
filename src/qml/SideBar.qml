/*
 * Copyright (C) 2024 Lingmo OS Team.
 *
 * Author:     Lingmo OS Team <team@lingmo.org>
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

import QtQuick 2.4
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import Qt5Compat.GraphicalEffects

import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import Lingmo.NetworkManagement 1.0 as NM

Item {
    implicitWidth: 230

    property int itemRadiusV: 8

    property alias view: listView
    property alias model: listModel
    property alias currentIndex: listView.currentIndex

    Rectangle {
        anchors.fill: parent
        // Own tone per theme: a cool light grey (light) or a deeper Dracula-like panel (dark)
        color: LingmoUI.Theme.darkMode ? Qt.rgba(0.11, 0.11, 0.15, 0.55) : "#EDEEF2"

        Behavior on color {
            ColorAnimation {
                duration: 250
                easing.type: Easing.Linear
            }
        }
    }

    ListModel {
        id: listModel

        ListElement {
            title: qsTr("WLAN")
            name: "wlan"
            page: "qrc:/qml/WLAN/Main.qml"
            // source: "wlan.svg"
            iconSource: "wlan.svg"
            iconColor: "#0A84FF"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Ethernet")
            name: "ethernet"
            page: "qrc:/qml/Wired/Main.qml"
            // source: "network.svg"
            iconSource: "network.svg"
            iconColor: "#32ADE6"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Bluetooth")
            name: "bluetooth"
            page: "qrc:/qml/Bluetooth/Main.qml"
            // source: "bluetooth.svg"
            iconSource: "bluetooth.svg"
            iconColor: "#1E6FF0"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Proxy")
            name: "proxy"
            page: "qrc:/qml/Proxy/Main.qml"
            // source: "proxy.svg"
            iconSource: "proxy.svg"
            iconColor: "#8E8E93"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Display")
            name: "display"
            page: "qrc:/qml/Display/Main.qml"
            // source: "display.svg"
            iconSource: "display.svg"
            iconColor: "#30B0C7"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Appearance")
            name: "appearance"
            page: "qrc:/qml/Appearance/Main.qml"
            // source: "appearance.svg"
            iconSource: "appearance.svg"
            iconColor: "#5E5CE6"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Effects")
            name: "effects"
            page: "qrc:/qml/Effects/Main.qml"
            iconSource: "effects.svg"
            iconColor: "#BF5AF2"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Background")
            name: "background"
            page: "qrc:/qml/Wallpaper/Main.qml"
            // source: "wallpaper.svg"
            iconSource: "wallpaper.svg"
            iconColor: "#64B5F6"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Dock")
            name: "dock"
            page: "qrc:/qml/Dock/Main.qml"
            // source: "dock.svg"
            iconSource: "dock.svg"
            iconColor: "#48484A"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("User")
            name: "accounts"
            page: "qrc:/qml/User/Main.qml"
            // source: "accounts.svg"
            iconSource: "accounts.svg"
            iconColor: "#FF9500"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Notifications")
            name: "notifications"
            page: "qrc:/qml/Notification/Main.qml"
            // source: "notifications.svg"
            iconSource: "notifications.svg"
            iconColor: "#FF3B30"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Sound")
            name: "sound"
            page: "qrc:/qml/Sound/Main.qml"
            // source: "sound.svg"
            iconSource: "sound.svg"
            iconColor: "#FF2D55"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Camera")
            name: "camera"
            page: "qrc:/qml/Camera/Main.qml"
            iconSource: "camera.svg"
            iconColor: "#30B0C7"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Mouse")
            name: "mouse"
            page: "qrc:/qml/Cursor/Main.qml"
            // source: "cursor.svg"
            iconSource: "cursor.svg"
            iconColor: "#8E8E93"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Touchpad")
            name: "touchpad"
            page: "qrc:/qml/Touchpad/Main.qml"
            // source: "touchpad.svg"
            iconSource: "touchpad.svg"
            iconColor: "#8E8E93"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Date & Time")
            name: "datetime"
            page: "qrc:/qml/DateTime/Main.qml"
            // source: "datetime.svg"
            iconSource: "datetime.svg"
            iconColor: "#FF9F0A"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Accessibility")
            name: "accessibility"
            page: "qrc:/qml/Accessibility/Main.qml"
            //source: "accessibility.svg"
            iconSource: "accessibility.svg"
            iconColor: "#007AFF"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Keyboard")
            name: "keyboard"
            page: "qrc:/qml/Keyboard/Main.qml"
            iconSource: "keyboard-layout.svg"
            iconColor: "#34AADC"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Shortcuts")
            name: "shortcuts"
            page: "qrc:/qml/Shortcuts/Main.qml"
            iconSource: "keyboard.svg"
            iconColor: "#5856D6"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Startup")
            name: "startup"
            page: "qrc:/qml/Autostart/Main.qml"
            iconSource: "startup.svg"
            iconColor: "#FF9F0A"
            category: qsTr("System")
        }
        
        ListElement {
            title: qsTr("Default Applications")
            name: "defaultapps"
            page: "qrc:/qml/DefaultApp/Main.qml"
            //source: "defaultapps.svg"
            iconSource: "defaultapps.svg"
            iconColor: "#AF52DE"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Boxes")
            name: "boxes"
            page: "qrc:/qml/Boxes/Main.qml"
            iconSource: "boxes.svg"
            iconColor: "#30B0C7"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Artificial Intelligence")
            name: "ai"
            page: "qrc:/qml/AI/Main.qml"
            iconSource: "ai.svg"
            iconColor: "#6E56CF"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Language")
            name: "language"
            page: "qrc:/qml/LanguagePage.qml"
            // source: "language.svg"
            iconSource: "language.svg"
            iconColor: "#0FB5AE"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Battery")
            name: "battery"
            page: "qrc:/qml/Battery/Main.qml"
            // source: "battery.svg"
            iconColor: "#34C759"
            iconSource: "battery.svg"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Power")
            name: "power"
            page: "qrc:/qml/Power/Main.qml"
            iconColor: "#30D158"
            iconSource: "power.svg"
            category: qsTr("System")
        }

        // ListElement {
        //     title: qsTr("System Update")
        //     name: "systemupdate"
        //     page: "qrc:/qml/SystemUpdate/Main.qml"
        //     iconColor: "#2277FF"
        //     iconSource: "update.svg"
        //     category: qsTr("System & Update")
        // }

        ListElement {
            title: qsTr("About")
            name: "about"
            page: "qrc:/qml/About/Main.qml"
            iconSource: "info.svg"
            iconColor: "#8E8E93"
            category: qsTr("System & Update")
        }

    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // The window's traffic-light buttons sit in this strip, like macOS
        Item {
            Layout.preferredHeight: rootWindow.header.height
        }

        Label {
            text: rootWindow.title
            color: rootWindow.active ? LingmoUI.Theme.textColor : LingmoUI.Theme.disabledTextColor
            leftPadding: LingmoUI.Units.largeSpacing + LingmoUI.Units.smallSpacing
            rightPadding: LingmoUI.Units.largeSpacing + LingmoUI.Units.smallSpacing
            topPadding: 2
            bottomPadding: LingmoUI.Units.smallSpacing * 1.5
            font.pointSize: 17
            font.bold: true
        }

        ListView {
            id: listView
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            model: listModel

            spacing: LingmoUI.Units.smallSpacing
            leftMargin: LingmoUI.Units.largeSpacing
            rightMargin: LingmoUI.Units.largeSpacing
            topMargin: 0
            bottomMargin: LingmoUI.Units.largeSpacing

            ScrollBar.vertical: ScrollBar {}

            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0
            highlightResizeDuration : 0
            highlight: Rectangle {
                radius: LingmoUI.Theme.mediumRadius
                color: LingmoUI.Theme.highlightColor
                smooth: true
            }

            section.property: "category"
            section.delegate: Item {
                width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                height: LingmoUI.Units.fontMetrics.height + LingmoUI.Units.largeSpacing + LingmoUI.Units.smallSpacing

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: LingmoUI.Units.smallSpacing
                    anchors.rightMargin: LingmoUI.Units.largeSpacing
                    anchors.topMargin: LingmoUI.Units.largeSpacing
                    anchors.bottomMargin: LingmoUI.Units.smallSpacing
                    color: LingmoUI.Theme.disabledTextColor
                    text: section
                }
            }

            // highlightFollowsCurrentItem: true
            // highlightMoveDuration: 0
            // highlightResizeDuration : 0
            // highlight: Rectangle {
            //     radius: LingmoUI.Theme.mediumRadius
            //     color: Qt.rgba(LingmoUI.Theme.textColor.r,
            //                    LingmoUI.Theme.textColor.g,
            //                    LingmoUI.Theme.textColor.b, 0.05)
            //     // color: "#4DA4ED"
            //     smooth: true
            // }

            // section.property: "category"
            // section.delegate: Item {
            //     width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
            //     height: LingmoUI.Units.fontMetrics.height + LingmoUI.Units.largeSpacing + LingmoUI.Units.smallSpacing

            //     Text {
            //         anchors.left: parent.left
            //         anchors.top: parent.top
            //         anchors.leftMargin: Qt.application.layoutDirection === Qt.RightToLeft ? 0 : LingmoUI.Units.smallSpacing
            //         anchors.rightMargin: LingmoUI.Units.smallSpacing
            //         anchors.topMargin: LingmoUI.Units.largeSpacing
            //         anchors.bottomMargin: LingmoUI.Units.smallSpacing
            //         color: LingmoUI.Theme.disabledTextColor
            //         font.pointSize: 8
            //         text: section
            //     }
            // }

            LingmoUI.WheelHandler {
                target: listView
            }

            delegate: Item {
                id: item
                width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                height: LingmoUI.Units.fontMetrics.height + LingmoUI.Units.largeSpacing * 1.5

                property bool isCurrent: listView.currentIndex === index

                Rectangle {
                    anchors.fill: parent

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        onClicked: listView.currentIndex = index
                    }

                    radius: LingmoUI.Theme.mediumRadius
                    color: mouseArea.containsMouse && !isCurrent ? Qt.rgba(LingmoUI.Theme.textColor.r,
                                                                           LingmoUI.Theme.textColor.g,
                                                                           LingmoUI.Theme.textColor.b,
                                                                   0.1) : "transparent"

                    smooth: true
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: LingmoUI.Units.largeSpacing
                    spacing: LingmoUI.Units.smallSpacing * 1.5

                    // Image {
                    //     id: icon
                    //     width: 16
                    //     height: width
                    //     source: LingmoUI.Theme.darkMode || isCurrent ? "qrc:/images/sidebar/dark/" + model.iconSource
                    //                                                : "qrc:/images/sidebar/light/" + model.iconSource
                    //     sourceSize: Qt.size(width, height)
                    //     Layout.alignment: Qt.AlignVCenter
                    // }

                    // macOS-style tile: a rounded square in the item's own colour
                    Rectangle {
                        id: iconRect
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        Layout.alignment: Qt.AlignVCenter
                        radius: 7
                        // Same hue in both themes, tuned per theme: deeper on light
                        // backgrounds so the tile doesn't wash out, brighter on dark ones
                        readonly property color tileColor: {
                            var c = model.iconColor || LingmoUI.Theme.highlightColor
                            return LingmoUI.Theme.darkMode ? Qt.lighter(c, 1.12) : Qt.darker(c, 1.04)
                        }
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.lighter(iconRect.tileColor, LingmoUI.Theme.darkMode ? 1.18 : 1.12) }
                            GradientStop { position: 1.0; color: iconRect.tileColor }
                        }
                        border.width: 1
                        border.color: LingmoUI.Theme.darkMode ? Qt.rgba(1, 1, 1, isCurrent ? 0.55 : 0.18)
                                                              : Qt.rgba(0, 0, 0, isCurrent ? 0.0 : 0.10)

                        Image {
                            id: icon
                            anchors.centerIn: parent
                            width: 16
                            height: width
                            source: "qrc:/images/sidebar/all/" + model.iconSource
                            sourceSize: Qt.size(width * 2, height * 2)
                            smooth: true
                            antialiasing: true
                        }
                    }

                    // Rectangle {
                    //     id: iconRect
                    //     width: 24
                    //     height: 24
                    //     Layout.alignment: Qt.AlignVCenter
                    //     radius: 20
                    //     color: model.iconColor

                    //     // gradient: Gradient {
                    //     //     GradientStop { position: 0.0; color: Qt.lighter(model.iconColor, 1.15) }
                    //     //     GradientStop { position: 1.0; color: model.iconColor }
                    //     // }

                    //     Image {
                    //         id: icon
                    //         anchors.centerIn: parent
                    //         width: 12
                    //         height: width
                    //         source: "qrc:/images/sidebar/all/" + model.iconSource
                    //         sourceSize: Qt.size(width, height)
                    //         Layout.alignment: Qt.AlignVCenter
                    //         antialiasing: false
                    //         smooth: false
                    //     }
                    // }

                    Label {
                        id: itemTitle
                        text: model.title
                        color: isCurrent ? LingmoUI.Theme.highlightedTextColor : LingmoUI.Theme.textColor
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }



            // delegate: Item {
            //     id: item
            //     width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
            //     height: 35

            //     property bool isCurrent: listView.currentIndex === index

            //     Rectangle {
            //         anchors.fill: parent

            //         // DropShadow{
            //         //     anchors.fill: parent
            //         //     radius: 10
            //         //     samples: 10
            //         //     horizontalOffset: 5
            //         //     verticalOffset: 5
            //         //     color: LingmoUI.Theme.darkMode ? LingmoUI.Theme.textColor : "#363636"                        
            //         // }

            //         MouseArea {
            //             id: mouseArea
            //             anchors.fill: parent
            //             hoverEnabled: true
            //             acceptedButtons: Qt.LeftButton
            //             onClicked: listView.currentIndex = index
            //         }

            //         radius: LingmoUI.Theme.mediumRadius
            //         // color: mouseArea.pressed ? Qt.rgba(LingmoUI.Theme.textColor.r,
            //         //                                     LingmoUI.Theme.textColor.g,
            //         //                                     LingmoUI.Theme.textColor.b, LingmoUI.Theme.darkMode ? 0.05 : 0.1) :
            //         //        mouseArea.containsMouse || isCurrent ? "#2277FF" :
            //         //                                               "transparent"
            //         color: mouseArea.pressed ? Qt.rgba(LingmoUI.Theme.textColor.r,
            //                                            LingmoUI.Theme.textColor.g,
            //                                            LingmoUI.Theme.textColor.b, LingmoUI.Theme.darkMode ? 0.05 : 0.1) :
            //                mouseArea.containsMouse || isCurrent ? Qt.rgba(LingmoUI.Theme.textColor.r,
            //                                                               LingmoUI.Theme.textColor.g,
            //                                                               LingmoUI.Theme.textColor.b, LingmoUI.Theme.darkMode ? 0.1 : 0.05) :
            //                                                       "transparent"

            //         smooth: true
            //     }

            //     RowLayout {
            //         anchors.fill: parent
            //         anchors.leftMargin: LingmoUI.Units.smallSpacing
            //         spacing: LingmoUI.Units.smallSpacing

            //         Rectangle {
            //             id: iconRect
            //             width: 24
            //             height: 24
            //             Layout.alignment: Qt.AlignVCenter
            //             radius: 20
            //             color: model.iconColor

            //             // gradient: Gradient {
            //             //     GradientStop { position: 0.0; color: Qt.lighter(model.iconColor, 1.15) }
            //             //     GradientStop { position: 1.0; color: model.iconColor }
            //             // }

            //             Image {
            //                 id: icon
            //                 anchors.centerIn: parent
            //                 width: 12
            //                 height: width
            //                 source: "qrc:/images/sidebar/all/" + model.iconSource
            //                 sourceSize: Qt.size(width, height)
            //                 Layout.alignment: Qt.AlignVCenter
            //                 antialiasing: false
            //                 smooth: false
            //             }
            //         }

            //         Label {
            //             id: itemTitle
            //             text: model.title
            //             color: LingmoUI.Theme.darkMode ? LingmoUI.Theme.textColor : "#363636"
            //             font.pointSize: 9
            //         }

            //         Item {
            //             Layout.fillWidth: true
            //         }
            //     }
            // }
        }
    }

    function removeItem(name) {
        for (var i = 0; i < listModel.count; ++i) {
            if (name === listModel.get(i).name) {
                listModel.remove(i)
                break
            }
        }
    }

    Battery {
        id: _battery

        Component.onCompleted: {
            if (!_battery.available)
                removeItem("battery")
        }
    }

    NM.EnabledConnections {
        id: nmEnabledConnections

        Component.onCompleted: {
            if (!nmEnabledConnections.wirelessHwEnabled)
                removeItem("wlan")
        }
    }

    Touchpad {
        id: _touchPad

        Component.onCompleted: {
            if (!_touchPad.available)
                removeItem("touchpad")
        }
    }
}
