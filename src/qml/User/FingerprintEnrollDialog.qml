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

// Registers one finger: choose it, then touch the reader until fprintd
// reports enroll-completed. Progress comes from EnrollStatus signals.
Dialog {
    id: control

    property var fingerprint

    // "choose", "enroll" or "done"
    property string phase: "choose"
    property bool succeeded: false
    property string instruction: ""
    property string retryText: ""
    property string resultText: ""
    property var freeFingers: []

    readonly property int stages: fingerprint ? fingerprint.enrollStages : -1
    readonly property int stagesDone: fingerprint ? fingerprint.enrollStagesDone : 0
    readonly property real progress: phase === "done" && succeeded ? 1
                                     : stages > 0 ? Math.min(stagesDone / stages, 1) : 0

    parent: Overlay.overlay
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 400
    modal: true
    closePolicy: Popup.CloseOnEscape
    title: qsTr("Add fingerprint")

    Component.onCompleted: {
        var enrolled = fingerprint.enrolledFingers
        var all = fingerprint.allFingers()
        var free = []
        for (var i = 0; i < all.length; ++i) {
            if (enrolled.indexOf(all[i]) < 0)
                free.push(all[i])
        }
        freeFingers = free
    }

    onClosed: {
        if (fingerprint && fingerprint.enrolling)
            fingerprint.stopEnroll()
    }

    function start() {
        var finger = freeFingers[fingerCombo.currentIndex]
        if (!finger)
            return
        succeeded = false
        retryText = ""
        resultText = ""
        instruction = fingerprint.swipe ? qsTr("Swipe your finger across the reader")
                                        : qsTr("Place your finger on the reader")
        phase = "enroll"
        fingerprint.startEnroll(finger)
    }

    function nextInstruction() {
        if (fingerprint.swipe)
            return qsTr("Swipe your finger again")
        if (stages > 0 && stagesDone >= Math.ceil(stages / 2))
            return qsTr("Now touch the reader with the edges of your finger")
        return qsTr("Lift your finger and place it on the reader again")
    }

    function resultMessage(result, error) {
        if (error !== "")
            return error
        switch (result) {
        case "enroll-completed":
            return qsTr("You can now use this finger to log in, unlock and authorize.")
        case "enroll-failed":
            return qsTr("The fingerprint couldn't be registered. Try again.")
        case "enroll-data-full":
            return qsTr("The reader has no room for another fingerprint. Delete one first.")
        case "enroll-duplicate":
            return qsTr("This fingerprint is already registered.")
        case "enroll-disconnected":
            return qsTr("The fingerprint reader was disconnected.")
        default:
            return qsTr("The fingerprint reader reported an unknown error.")
        }
    }

    Connections {
        target: control.fingerprint

        function onEnrollStatus(result, done) {
            if (control.phase !== "enroll" || done)
                return

            switch (result) {
            case "enroll-stage-passed":
                control.retryText = ""
                control.instruction = control.nextInstruction()
                break
            case "enroll-retry-scan":
                control.retryText = qsTr("The reading wasn't clear. Try again.")
                break
            case "enroll-swipe-too-short":
                control.retryText = qsTr("The swipe was too short. Try again.")
                break
            case "enroll-finger-not-centered":
                control.retryText = qsTr("Your finger wasn't centered on the reader. Try again.")
                break
            case "enroll-remove-and-retry":
                control.retryText = qsTr("Remove your finger and try again.")
                break
            }
        }

        function onEnrollFinished(success, result, error) {
            if (control.phase !== "enroll")
                return
            control.succeeded = success
            control.retryText = ""
            control.resultText = control.resultMessage(result, error)
            control.phase = "done"
        }
    }

    ColumnLayout {
        id: mainLayout
        width: control.availableWidth
        spacing: LingmoUI.Units.largeSpacing * 1.5

        // Fingerprint with a progress ring
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 132
            Layout.preferredHeight: 132

            Canvas {
                id: ring
                anchors.fill: parent

                property real value: control.progress
                property color trackColor: LingmoUI.Theme.pressedColor
                property color valueColor: control.phase === "done" && !control.succeeded
                                           ? LingmoUI.Theme.errorColor : LingmoUI.Theme.highlightColor

                Behavior on value {
                    NumberAnimation {
                        duration: LingmoUI.Units.longDuration
                        easing.type: Easing.OutCubic
                    }
                }

                onValueChanged: requestPaint()
                onValueColorChanged: requestPaint()
                onTrackColorChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    var lineWidth = 6
                    var r = Math.min(width, height) / 2 - lineWidth
                    ctx.reset()
                    ctx.lineWidth = lineWidth
                    ctx.lineCap = "round"

                    ctx.strokeStyle = trackColor
                    ctx.beginPath()
                    ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI)
                    ctx.stroke()

                    if (value > 0) {
                        ctx.strokeStyle = valueColor
                        ctx.beginPath()
                        ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * value)
                        ctx.stroke()
                    }
                }
            }

            Image {
                id: fingerprintIcon
                anchors.centerIn: parent
                width: 72
                height: 72
                sourceSize: Qt.size(72, 72)
                source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/fingerprint.svg" : "qrc:/images/light/fingerprint.svg"
                visible: false
            }

            // Pulses while waiting for the finger
            Item {
                anchors.fill: fingerprintIcon

                SequentialAnimation on opacity {
                    running: control.phase === "enroll"
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { from: 1; to: 0.45; duration: 900; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.45; to: 1; duration: 900; easing.type: Easing.InOutQuad }
                }

                ColorOverlay {
                    anchors.fill: parent
                    source: fingerprintIcon
                    color: control.phase === "choose" ? LingmoUI.Theme.textColor
                           : control.phase === "done" && !control.succeeded ? LingmoUI.Theme.errorColor
                           : LingmoUI.Theme.highlightColor
                    opacity: control.phase === "choose" ? 0.6 : 1
                }
            }
        }

        // Choose the finger
        ColumnLayout {
            visible: control.phase === "choose"
            spacing: LingmoUI.Units.largeSpacing
            Layout.fillWidth: true

            Label {
                text: qsTr("Choose the finger you want to register. You will touch the reader several times.")
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            ComboBox {
                id: fingerCombo
                model: control.freeFingers.map(function(f) { return control.fingerprint.fingerName(f) })
                Layout.fillWidth: true
                topInset: 0
                bottomInset: 0
            }
        }

        // Enrolling
        ColumnLayout {
            visible: control.phase === "enroll"
            spacing: LingmoUI.Units.smallSpacing
            Layout.fillWidth: true

            Label {
                text: control.instruction
                font.pointSize: LingmoUI.Units.fontSubheading
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Label {
                text: control.retryText !== "" ? control.retryText
                      : control.stages > 0 ? qsTr("%1 of %2 touches").arg(control.stagesDone).arg(control.stages)
                      : ""
                color: control.retryText !== "" ? LingmoUI.Theme.errorColor : LingmoUI.Theme.secondaryTextColor
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        // Finished
        ColumnLayout {
            visible: control.phase === "done"
            spacing: LingmoUI.Units.smallSpacing
            Layout.fillWidth: true

            Label {
                text: control.succeeded ? qsTr("Fingerprint registered") : qsTr("Registration failed")
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
                visible: control.phase === "choose" || (control.phase === "done" && !control.succeeded)
                text: control.phase === "done" ? qsTr("Try again") : qsTr("Start")
                enabled: control.freeFingers.length > 0
                flat: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                onClicked: control.start()
            }
        }
    }
}
