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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Dialogs
import QtCore
import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import "../"

ItemPage {
    headerTitle: qsTr("Camera")

    CameraSettings {
        id: camera
        Component.onCompleted: start()
    }

    MediaDevices {
        id: mediaDevices
    }

    FileDialog {
        id: imageDialog
        title: qsTr("Choose a background image")
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: [qsTr("Images") + " (*.jpg *.jpeg *.png *.webp)", qsTr("All files") + " (*)"]
        onAccepted: camera.backgroundImage = selectedFile.toString()
    }

    // Preview of what the apps get: this page reads "Lingmo Camera" like any app would
    CaptureSession {
        camera: Camera {
            id: previewCamera
            cameraDevice: {
                var inputs = mediaDevices.videoInputs
                for (var i = 0; i < inputs.length; ++i) {
                    if (inputs[i].description === "Lingmo Camera")
                        return inputs[i]
                }
                return mediaDevices.defaultVideoInput
            }
            active: previewButton.checked && camera.available
        }
        videoOutput: preview
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
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Auto framing")
                        }

                        Label {
                            text: qsTr("The camera follows your face and keeps you centred during video calls, even when you move.")
                            color: LingmoUI.Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: camera.framing
                        enabled: camera.running
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        rightPadding: 0
                        onToggled: camera.framing = checked
                    }
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true
                    enabled: camera.running && camera.framing

                    Label {
                        text: qsTr("Zoom")
                    }

                    LingmoUI.SegmentedControl {
                        fillWidth: true
                        model: [qsTr("Wide"), qsTr("Medium"), qsTr("Close")]
                        Layout.fillWidth: true
                        // Follows the setting (also after a click, like TabBar did)
                        Binding on currentIndex { value: camera.zoom === "wide" ? 0 : camera.zoom === "close" ? 2 : 1 }
                        onActivated: (index) => {
                            if (index === 0) { camera.zoom = "wide" }
                            else if (index === 1) { camera.zoom = "medium" }
                            else if (index === 2) { camera.zoom = "close" }
                        }
                    }
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true
                    enabled: camera.running
                    visible: camera.cameras.length > 1

                    Label {
                        text: qsTr("Camera")
                    }

                    ComboBox {
                        Layout.fillWidth: true
                        textRole: "name"
                        valueRole: "device"
                        model: [{ device: "", name: qsTr("Automatic") }].concat(camera.cameras)
                        currentIndex: {
                            for (var i = 0; i < model.length; ++i) {
                                if (model[i].device === camera.source)
                                    return i
                            }
                            return 0
                        }
                        onActivated: camera.source = currentValue
                    }
                }
            }

            RoundedItem {
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Blur background")
                        }

                        Label {
                            text: qsTr("You stay sharp and the room behind you is blurred, in every app.")
                            color: LingmoUI.Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: camera.backgroundBlur
                        enabled: camera.running
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        rightPadding: 0
                        onToggled: camera.backgroundBlur = checked
                    }
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true
                    enabled: camera.running && camera.backgroundBlur && camera.backgroundImage === ""

                    Label {
                        text: qsTr("Strength")
                    }

                    LingmoUI.SegmentedControl {
                        fillWidth: true
                        model: [qsTr("Light", "blur strength"), qsTr("Strong", "blur strength")]
                        Layout.fillWidth: true
                        // Follows the setting (also after a click, like TabBar did)
                        Binding on currentIndex { value: camera.blurStrength === "light" ? 0 : 1 }
                        onActivated: (index) => {
                            if (index === 0) { camera.blurStrength = "light" }
                            else if (index === 1) { camera.blurStrength = "strong" }
                        }
                    }
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true
                    enabled: camera.running && camera.backgroundBlur

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Background image")
                        }

                        Label {
                            text: camera.backgroundImage !== ""
                                  ? camera.backgroundImage.substring(camera.backgroundImage.lastIndexOf("/") + 1)
                                  : qsTr("Optional: shown behind you instead of the blur.")
                            color: LingmoUI.Theme.secondaryTextColor
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        flat: true
                        visible: camera.backgroundImage !== ""
                        text: qsTr("Remove")
                        onClicked: camera.backgroundImage = ""
                    }

                    Button {
                        flat: true
                        text: qsTr("Choose…")
                        onClicked: imageDialog.open()
                    }
                }
            }

            RoundedItem {
                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Preview")
                        color: LingmoUI.Theme.secondaryTextColor
                        Layout.fillWidth: true
                    }

                    Button {
                        id: previewButton
                        checkable: true
                        flat: true
                        enabled: camera.available
                        text: checked ? qsTr("Stop") : qsTr("Test camera")
                    }
                }

                Rectangle {
                    visible: previewButton.checked
                    color: "black"
                    radius: LingmoUI.Theme.mediumRadius
                    clip: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 9 / 16

                    VideoOutput {
                        id: preview
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectFit
                    }
                }
            }

            RoundedItem {
                Label {
                    text: qsTr("How to use")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("In Meet, Zoom, Teams, Discord or your browser, choose \"Lingmo Camera\" as the camera. The framing happens here, so it works in every app.")
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: LingmoUI.Theme.secondaryTextColor
                    text: !camera.running ? qsTr("The camera service is not running.")
                        : !camera.available ? qsTr("The virtual camera is not ready yet. Restart the computer once after installing, or run: sudo modprobe -r v4l2loopback && sudo modprobe v4l2loopback")
                        : camera.active ? qsTr("In use now.")
                        : qsTr("Ready. The camera light only turns on while an app is using it.")
                }
            }

            Item {
                height: LingmoUI.Units.largeSpacing
            }
        }
    }
}
