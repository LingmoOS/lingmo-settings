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

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import "../"

// The user's face (lingmo-faceauth, webcam) and the switches that let it log
// in and unlock (PAM), and optionally authorize sudo and administrator prompts.
RoundedItem {
    id: control

    property string errorText: ""
    property string testText: ""
    property bool pendingLoginValue: false
    property bool pendingAdminValue: false

    readonly property color warningColor: LingmoUI.Theme.errorColor

    FaceAuth {
        id: face

        onErrorOccurred: function(message) {
            control.errorText = message
            errorTimer.restart()
        }

        onTestFinished: function(result) {
            switch (result) {
            case "match":
                control.testText = qsTr("Recognized: it's you.")
                break
            case "liveness":
                control.testText = qsTr("Your face was found, but it didn't move. Turn or nod your head a little while the camera looks.")
                break
            case "nomatch":
                control.testText = qsTr("Not recognized. Try with more light, or register your face again.")
                break
            case "busy":
                control.testText = qsTr("The camera is being used by another program.")
                break
            case "nocamera":
                control.testText = qsTr("No camera was found.")
                break
            case "noenroll":
                control.testText = qsTr("Register your face first.")
                break
            default:
                control.testText = qsTr("The test couldn't run.")
            }
            testTimer.restart()
        }
    }

    Timer {
        id: errorTimer
        interval: 8000
        onTriggered: control.errorText = ""
    }

    Timer {
        id: testTimer
        interval: 10000
        onTriggered: control.testText = ""
    }

    function openEnrollDialog() {
        var component = Qt.createComponent("FaceEnrollDialog.qml")
        if (component.status === Component.Ready) {
            var dialog = component.createObject(rootWindow, { "face": face })
            dialog.closed.connect(dialog.destroy)
            dialog.open()
        } else {
            console.warn(component.errorString())
        }
    }

    RowLayout {
        spacing: LingmoUI.Units.largeSpacing

        Label {
            text: qsTr("Face recognition")
            color: LingmoUI.Theme.secondaryTextColor
        }

        Item {
            Layout.fillWidth: true
        }

        LingmoUI.Spinner {
            id: busyIndicator
            size: 22
            visible: !face.ready || face.pamBusy || face.testing
            running: busyIndicator.visible
        }
    }

    // lingmo-faceauth missing, or no camera
    RowLayout {
        visible: face.ready && (!face.available || (!face.cameraAvailable && !face.enrolled))
        spacing: LingmoUI.Units.largeSpacing
        Layout.fillWidth: true

        Image {
            source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/face.svg" : "qrc:/images/light/face.svg"
            sourceSize: Qt.size(32, 32)
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            opacity: 0.4
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: LingmoUI.Theme.secondaryTextColor
            text: !face.available
                  ? qsTr("Face recognition is not installed. Install the lingmo-camera package to log in with the webcam.")
                  : qsTr("No camera was found. Connect a webcam and open this page again to log in with your face.")
        }
    }

    // The enrolled face
    ColumnLayout {
        id: enrolledLayout
        visible: face.available && (face.cameraAvailable || face.enrolled)
        spacing: LingmoUI.Units.smallSpacing
        Layout.fillWidth: true

        RowLayout {
            spacing: LingmoUI.Units.largeSpacing
            Layout.fillWidth: true

            Image {
                source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/face.svg" : "qrc:/images/light/face.svg"
                sourceSize: Qt.size(22, 22)
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                opacity: face.enrolled ? 1 : 0.4
            }

            Label {
                text: face.enrolled
                      ? qsTr("Face registered on %1").arg(Qt.formatDate(face.enrolledDate, Qt.DefaultLocaleShortDate))
                      : qsTr("No face registered yet.")
                color: face.enrolled ? LingmoUI.Theme.textColor : LingmoUI.Theme.secondaryTextColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Button {
                text: qsTr("Test")
                visible: face.enrolled
                enabled: !face.testing && !face.enrolling && face.cameraAvailable
                onClicked: {
                    control.testText = qsTr("Look at the camera…")
                    testTimer.stop()
                    face.test()
                }
            }

            Button {
                text: qsTr("Delete")
                visible: face.enrolled
                enabled: !face.testing && !face.enrolling && !face.pamBusy
                onClicked: deleteDialog.open()
            }
        }

        Label {
            visible: control.testText !== ""
            text: control.testText
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Button {
            text: face.enrolled ? qsTr("Register again") : qsTr("Register face")
            flat: true
            enabled: face.cameraAvailable && !face.testing && !face.enrolling && !face.pamBusy
            Layout.topMargin: LingmoUI.Units.smallSpacing
            Layout.fillWidth: true
            onClicked: control.openEnrollDialog()
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: LingmoUI.Theme.secondaryTextColor
            text: qsTr("No photo is kept: only numbers describing your face, in your home folder.")
        }
    }

    // Log in and unlock with the face
    HorizontalDivider {
        visible: pamLayout.visible
    }

    ColumnLayout {
        id: pamLayout
        visible: enrolledLayout.visible || face.loginEnabled || face.loginPartial
        spacing: LingmoUI.Units.smallSpacing
        Layout.fillWidth: true

        RowLayout {
            spacing: LingmoUI.Units.largeSpacing
            Layout.fillWidth: true

            Label {
                text: qsTr("Use your face to log in and unlock the screen")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Switch {
                id: loginSwitch
                leftPadding: 0
                rightPadding: 0
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                checked: face.pamBusy ? control.pendingLoginValue : face.loginEnabled
                enabled: !face.pamBusy && face.pamHelperAvailable
                         && (face.loginEnabled || face.loginPartial || (face.pamModuleAvailable && face.enrolled))

                onToggled: {
                    control.pendingLoginValue = checked
                    control.pendingAdminValue = checked && face.adminEnabled
                    face.setLoginEnabled(checked)
                    checked = Qt.binding(function() {
                        return face.pamBusy ? control.pendingLoginValue : face.loginEnabled
                    })
                }
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: LingmoUI.Theme.secondaryTextColor
            text: {
                if (!face.pamHelperAvailable)
                    return qsTr("The face-pam helper of Lingmo Settings is missing, so this can't be changed here.")
                if (!face.pamModuleAvailable && !face.loginEnabled)
                    return qsTr("The PAM module pam_exec or lingmo-faceauth is missing.")
                if (face.loginPartial)
                    return qsTr("Face recognition is only partly set up. Turn it on again to repair it.")
                if (!face.loginEnabled && !face.enrolled)
                    return qsTr("Register your face first.")
                return qsTr("The login and lock screens look for your face for a few seconds; if it isn't recognized, type your password. Turn or nod your head a little while the camera looks.")
            }
        }

        // sudo and administrator prompts: off by default, with a warning
        RowLayout {
            visible: face.loginEnabled || face.adminEnabled || face.adminPartial
            spacing: LingmoUI.Units.largeSpacing
            Layout.topMargin: LingmoUI.Units.smallSpacing
            Layout.fillWidth: true

            Label {
                text: qsTr("Also for sudo and administrator passwords")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Switch {
                id: adminSwitch
                leftPadding: 0
                rightPadding: 0
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                checked: face.pamBusy ? control.pendingAdminValue : (face.adminEnabled && face.adminCopyPresent)
                enabled: !face.pamBusy && face.pamHelperAvailable
                         && (face.adminEnabled || face.adminPartial || (face.loginEnabled && face.enrolled))

                onToggled: {
                    control.pendingAdminValue = checked
                    control.pendingLoginValue = face.loginEnabled
                    face.setAdminEnabled(checked)
                    checked = Qt.binding(function() {
                        return face.pamBusy ? control.pendingAdminValue : (face.adminEnabled && face.adminCopyPresent)
                    })
                }
            }
        }

        Label {
            visible: face.loginEnabled || face.adminEnabled || face.adminPartial
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: control.warningColor
            text: face.adminEnabled && !face.adminCopyPresent
                  ? qsTr("This is on for this computer, but your face isn't authorized for it yet. Turn it on to authorize it.")
                  : qsTr("Warning: an ordinary webcam can be fooled by a good photo or video of you, and it has no infrared sensor to tell. With this on, whoever has one could get administrator rights on this computer. Keep it off unless you accept that risk.")
        }
    }

    Label {
        visible: control.errorText !== ""
        text: control.errorText
        color: control.warningColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    Dialog {
        id: deleteDialog
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        title: qsTr("Delete your face?")

        ColumnLayout {
            spacing: LingmoUI.Units.largeSpacing * 1.5

            Label {
                text: face.adminEnabled
                      ? qsTr("You will have to register it again to log in with the camera. Face recognition for sudo and administrator passwords will be turned off.")
                      : qsTr("You will have to register it again to log in with the camera.")
                wrapMode: Text.WordWrap
                Layout.maximumWidth: 320
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
                        face.deleteFace()
                    }
                }
            }
        }
    }
}
