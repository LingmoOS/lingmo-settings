/*
 * Copyright (C) 2026 LingmoOS Team.
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import "../"

// Boxes: programs from outside the system (Windows, .deb/.rpm, AppImage,
// Android) run isolated. See what each box may reach, change it, delete it.
ItemPage {
    id: page
    headerTitle: qsTr("Boxes")

    // The box whose details are open
    property string openBox: ""
    property string folderBox: ""

    Component.onCompleted: {
        BoxesModule.clearError()
        BoxesModule.refresh()
    }

    function shortPath(path) {
        const home = BoxesModule.homePath
        return path.indexOf(home + "/") === 0 ? "~" + path.substring(home.length) : path
    }

    function summary(box) {
        const parts = [box.typeLabel]
        if (box.sizeText.length > 0)
            parts.push(box.sizeText)
        if (box.apps.length > 0)
            parts.push(qsTr("%n program(s)", "", box.apps.length))
        return parts.join(" · ")
    }

    // One permission row: title, explanation, switch (or a fixed value)
    component PermissionRow: RowLayout {
        id: row
        property string title
        property string text
        property bool checked
        property bool changeable: true
        property string fixedText
        signal toggled(bool on)

        spacing: LingmoUI.Units.largeSpacing
        Layout.fillWidth: true

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Label {
                text: row.title
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                visible: row.text.length > 0
                text: row.text
                color: LingmoUI.Theme.disabledTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        Label {
            visible: !row.changeable
            text: row.fixedText
            color: LingmoUI.Theme.disabledTextColor
        }

        Switch {
            visible: row.changeable
            checked: row.checked
            enabled: BoxesModule.busyBox === ""
            onToggled: row.toggled(checked)
        }
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing * 2

            // ---------------------------------------------------------- About boxes
            RoundedItem {
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 1.5
                    Layout.fillWidth: true

                    LingmoUI.IconItem {
                        Layout.preferredWidth: LingmoUI.Units.iconSizes.large
                        Layout.preferredHeight: LingmoUI.Units.iconSizes.large
                        Layout.alignment: Qt.AlignTop
                        source: "security-high-symbolic"
                    }

                    ColumnLayout {
                        spacing: LingmoUI.Units.smallSpacing
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Programs from outside the system run in boxes")
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Windows programs, .deb and .rpm packages, AppImages and Android apps are installed in isolated boxes. A box can't see your files, camera or microphone unless you allow it here, so a bad program can't reach the rest of the system.")
                            color: LingmoUI.Theme.disabledTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            Label {
                visible: !BoxesModule.winrunInstalled
                text: qsTr("Lingmo Install Programs (lingmo-winrun) is not installed: boxes can be seen but not changed.")
                color: LingmoUI.Theme.orangeColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // ---------------------------------------------------------- No boxes
            RoundedItem {
                visible: BoxesModule.boxes.length === 0

                Label {
                    text: qsTr("No boxes yet. When you open a Windows program, a .deb or .rpm package, an AppImage or an Android app (.apk) and install it, its box shows up here.")
                    color: LingmoUI.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // ---------------------------------------------------------- One card per box
            Repeater {
                model: BoxesModule.boxes

                RoundedItem {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property var box: modelData
                    readonly property bool open: page.openBox === box.id || (page.openBox === "" && index === 0)
                    readonly property bool busy: BoxesModule.busyBox === box.id

                    // Header: icon, name, kind · size · programs
                    RowLayout {
                        spacing: LingmoUI.Units.largeSpacing
                        Layout.fillWidth: true

                        Item {
                            Layout.preferredWidth: LingmoUI.Units.iconSizes.medium
                            Layout.preferredHeight: LingmoUI.Units.iconSizes.medium

                            Image {
                                id: fileIcon
                                anchors.fill: parent
                                visible: card.box.icon.indexOf("file:") === 0 && status === Image.Ready
                                source: card.box.icon.indexOf("file:") === 0 ? card.box.icon : ""
                                sourceSize: Qt.size(64, 64)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            LingmoUI.IconItem {
                                anchors.fill: parent
                                visible: !fileIcon.visible
                                source: card.box.icon.indexOf("file:") === 0 ? "application-vnd.appimage" : card.box.icon
                            }
                        }

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            Label {
                                text: card.box.name
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Label {
                                text: page.summary(card.box)
                                color: LingmoUI.Theme.disabledTextColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        LingmoUI.BusyIndicator {
                            visible: card.busy
                            running: visible
                            source: "qrc:/images/view-refresh.svg"
                            width: 22
                            height: width
                        }

                        Button {
                            text: card.open ? qsTr("Hide") : qsTr("Show")
                            onClicked: page.openBox = card.open ? "-" : card.box.id
                        }
                    }

                    // Programs inside
                    Label {
                        visible: card.open
                        text: card.box.apps.length > 0
                              ? qsTr("Inside: %1").arg(card.box.apps.map(function(a) { return a.name }).join(", "))
                              : qsTr("No programs installed in it yet.")
                        color: LingmoUI.Theme.disabledTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    HorizontalDivider { visible: card.open }

                    // ---------- Files
                    PermissionRow {
                        visible: card.open
                        title: qsTr("Personal folders")
                        text: card.box.type === "android"
                              ? qsTr("Android sees none of your folders.")
                              : (card.box.type === "bottles"
                                 ? qsTr("Documents, Downloads, Pictures, Music, Videos and Desktop. It always sees %1.").arg(page.shortPath(card.box.exchange))
                                 : qsTr("Documents, Downloads, Pictures, Music, Videos and Desktop."))
                        checked: card.box.files === "personal"
                        changeable: card.box.changeable
                        fixedText: qsTr("No")
                        onToggled: (on) => BoxesModule.setPermission(card.box.id, "files", on ? "personal" : "none")
                    }

                    // Other folders the user shared
                    ColumnLayout {
                        visible: card.open && card.box.changeable
                        spacing: LingmoUI.Units.smallSpacing
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: LingmoUI.Units.largeSpacing
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Label {
                                    text: qsTr("Other folders")
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: card.box.folders.length === 0
                                          ? qsTr("None. Hidden folders, where settings and passwords live, can't be added.")
                                          : qsTr("The box can read and change the files in these folders.")
                                    color: LingmoUI.Theme.disabledTextColor
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            Button {
                                text: qsTr("Add folder…")
                                enabled: BoxesModule.busyBox === ""
                                onClicked: {
                                    page.folderBox = card.box.id
                                    folderDialog.open()
                                }
                            }
                        }

                        Repeater {
                            model: card.box.folders

                            RowLayout {
                                required property string modelData
                                spacing: LingmoUI.Units.largeSpacing
                                Layout.fillWidth: true

                                LingmoUI.IconItem {
                                    Layout.preferredWidth: LingmoUI.Units.iconSizes.small
                                    Layout.preferredHeight: LingmoUI.Units.iconSizes.small
                                    source: "folder"
                                }

                                Label {
                                    text: page.shortPath(parent.modelData)
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                Button {
                                    text: qsTr("Remove")
                                    enabled: BoxesModule.busyBox === ""
                                    onClicked: BoxesModule.removeFolder(card.box.id, parent.modelData)
                                }
                            }
                        }
                    }

                    // ---------- Network, camera, sound
                    PermissionRow {
                        visible: card.open
                        title: qsTr("Network")
                        text: qsTr("Internet and the local network.")
                        checked: card.box.network
                        changeable: card.box.changeable
                        fixedText: qsTr("Yes")
                        onToggled: (on) => BoxesModule.setPermission(card.box.id, "network", on ? "on" : "off")
                    }

                    PermissionRow {
                        visible: card.open
                        title: qsTr("Camera")
                        text: card.box.type === "android" ? qsTr("Waydroid doesn't support cameras.")
                              : card.box.type === "bottles" ? qsTr("Turning it off keeps the graphics card and game controllers.") : ""
                        checked: card.box.camera
                        changeable: card.box.changeable
                        fixedText: qsTr("No")
                        onToggled: (on) => BoxesModule.setPermission(card.box.id, "camera", on ? "on" : "off")
                    }

                    PermissionRow {
                        visible: card.open
                        title: qsTr("Sound and microphone")
                        text: card.box.type === "android"
                              ? qsTr("Android uses the computer's sound and microphone.")
                              : qsTr("The same connection carries sound and the microphone: turning it off also mutes the programs in this box.")
                        checked: card.box.microphone
                        changeable: card.box.changeable
                        fixedText: qsTr("Yes")
                        onToggled: (on) => BoxesModule.setPermission(card.box.id, "microphone", on ? "on" : "off")
                    }

                    Label {
                        visible: card.open
                        text: card.box.applies
                        color: LingmoUI.Theme.disabledTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        visible: BoxesModule.errorBox === card.box.id && BoxesModule.errorText.length > 0
                        text: BoxesModule.errorText
                        color: LingmoUI.Theme.redColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    HorizontalDivider { visible: card.open }

                    RowLayout {
                        visible: card.open
                        spacing: LingmoUI.Units.largeSpacing
                        Layout.fillWidth: true

                        Button {
                            visible: card.box.type !== "android"
                            text: qsTr("Open Folder")
                            onClicked: BoxesModule.openFolder(card.box.type === "bottles" ? card.box.exchange : card.box.home)
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: qsTr("Delete Box…")
                            enabled: BoxesModule.busyBox === "" && BoxesModule.winrunInstalled
                            onClicked: {
                                deleteDialog.boxId = card.box.id
                                deleteDialog.boxName = card.box.name
                                deleteDialog.deletes = card.box.deletes
                                deleteDialog.open()
                            }
                        }
                    }
                }
            }

            Item {
                height: LingmoUI.Units.largeSpacing
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: qsTr("Choose a folder to share with the box")
        currentFolder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        onAccepted: BoxesModule.addFolder(page.folderBox, selectedFolder)
    }

    Dialog {
        id: deleteDialog
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        title: qsTr("Delete \"%1\"?").arg(deleteDialog.boxName)

        property string boxId: ""
        property string boxName: ""
        property string deletes: ""

        ColumnLayout {
            spacing: LingmoUI.Units.largeSpacing * 1.5

            Label {
                text: deleteDialog.deletes + " " + qsTr("This can't be undone.")
                wrapMode: Text.WordWrap
                Layout.maximumWidth: 340
            }

            RowLayout {
                spacing: LingmoUI.Units.largeSpacing

                Button {
                    text: qsTr("Cancel")
                    Layout.fillWidth: true
                    onClicked: deleteDialog.reject()
                }

                Button {
                    text: qsTr("Delete")
                    flat: true
                    Layout.fillWidth: true
                    onClicked: {
                        deleteDialog.accept()
                        BoxesModule.deleteBox(deleteDialog.boxId)
                    }
                }
            }
        }
    }
}
