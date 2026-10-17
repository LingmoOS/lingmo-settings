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
import Qt5Compat.GraphicalEffects

import LingmoUI.CompatibleModule 3.0 as LingmoUI

// Registers the user's face: lingmo-faceauth looks through the camera (shown
// here, mirrored) and keeps a few views of the face as numbers.
Dialog {
    id: control

    property var face

    // "intro", "enroll" or "done"
    property string phase: "intro"
    property bool succeeded: false
    property string resultText: ""

    parent: Overlay.overlay
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 420
    modal: true
    closePolicy: Popup.CloseOnEscape
    title: qsTr("Register face")

    onClosed: {
        if (face && face.enrolling)
            face.stopEnroll()
    }

    function start() {
        succeeded = false
        resultText = ""
        phase = "enroll"
        face.startEnroll()
    }

    function hintText(hint) {
        switch (hint) {
        case "straight":
            return qsTr("Look straight at the camera")
        case "turn":
            return qsTr("Now turn your head slowly a little to each side")
        case "noface":
            return qsTr("No face found: sit in front of the camera")
        case "toofar":
            return qsTr("Come a little closer")
        case "toomany":
            return qsTr("Only you should be in front of the camera")
        case "blurry":
            return qsTr("Hold still for a moment")
        case "dark":
            return qsTr("It's too dark: turn on a light or face a window")
        default:
            return qsTr("Look at the camera")
        }
    }

    function errorText(error) {
        switch (error) {
        case "busy":
            return qsTr("The camera is being used by another program, a video call perhaps. Close it and try again.")
        case "nocamera":
            return qsTr("The camera couldn't be opened.")
        case "models":
            return qsTr("The face recognition models are missing. Reinstall lingmo-camera.")
        case "timeout":
            return qsTr("Your face couldn't be seen well enough. Try again facing the camera, with more light.")
        case "save":
            return qsTr("Your face couldn't be saved.")
        case "cancelled":
            return qsTr("Cancelled.")
        default:
            return qsTr("Face recognition failed. Try again.")
        }
    }

    Connections {
        target: control.face

        function onEnrollFinished(success, error) {
            if (control.phase !== "enroll")
                return
            control.succeeded = success
            control.resultText = success
                    ? qsTr("You can now turn on face login below. If it's already on, the new registration is used right away.")
                    : control.errorText(error)
            control.phase = "done"
        }
    }

    ColumnLayout {
        id: mainLayout
        width: control.availableWidth
        spacing: LingmoUI.Units.largeSpacing * 1.5

        // Camera picture, or the face icon before and after
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 320
            Layout.preferredHeight: 240
            radius: LingmoUI.Theme.mediumRadius
            color: LingmoUI.Theme.alternateBackgroundColor
            clip: true

            Image {
                id: previewImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: false
                source: control.face && control.phase === "enroll" ? control.face.preview : ""
                visible: status === Image.Ready && control.phase === "enroll"
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: previewImage.width
                        height: previewImage.height
                        radius: LingmoUI.Theme.mediumRadius
                    }
                }
            }

            Image {
                id: faceIcon
                anchors.centerIn: parent
                width: 72
                height: 72
                sourceSize: Qt.size(72, 72)
                source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/face.svg" : "qrc:/images/light/face.svg"
                visible: false
            }

            ColorOverlay {
                anchors.fill: faceIcon
                source: faceIcon
                visible: !previewImage.visible
                color: control.phase === "done" && !control.succeeded ? control.warningColor
                       : control.phase === "done" ? LingmoUI.Theme.highlightColor
                       : LingmoUI.Theme.textColor
                opacity: control.phase === "intro" ? 0.6 : 1
            }

            LingmoUI.Spinner {
                anchors.centerIn: parent
                size: 32
                visible: control.phase === "enroll" && !previewImage.visible
                running: visible
            }
        }

        // Before starting
        Label {
            visible: control.phase === "intro"
            text: qsTr("Sit in front of the camera in good light. It takes a few seconds: look at the camera, then turn your head slowly a little to each side. No photo is kept.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // Enrolling
        ColumnLayout {
            visible: control.phase === "enroll"
            spacing: LingmoUI.Units.smallSpacing
            Layout.fillWidth: true

            Label {
                text: control.face ? control.hintText(control.face.enrollHint) : ""
                font.pointSize: LingmoUI.Units.fontSubheading
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            ProgressBar {
                from: 0
                to: control.face ? control.face.enrollTotal : 1
                value: control.face ? control.face.enrollDone : 0
                Layout.fillWidth: true
            }
        }

        // Finished
        ColumnLayout {
            visible: control.phase === "done"
            spacing: LingmoUI.Units.smallSpacing
            Layout.fillWidth: true

            Label {
                text: control.succeeded ? qsTr("Face registered") : qsTr("Registration failed")
                font.pointSize: LingmoUI.Units.fontSubheading
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Label {
                text: control.resultText
                color: LingmoUI.Theme.secondaryTextColor
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        RowLayout {
            spacing: LingmoUI.Units.largeSpacing
            Layout.fillWidth: true

            Button {
                text: control.phase === "done" ? qsTr("Close") : qsTr("Cancel")
                Layout.fillWidth: true
                // equal halves whatever the text
                Layout.preferredWidth: 1
                onClicked: control.close()
            }

            Button {
                visible: control.phase === "intro" || (control.phase === "done" && !control.succeeded)
                text: control.phase === "done" ? qsTr("Try again") : qsTr("Start")
                flat: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                onClicked: control.start()
            }
        }
    }

    readonly property color warningColor: LingmoUI.Theme.errorColor
}
