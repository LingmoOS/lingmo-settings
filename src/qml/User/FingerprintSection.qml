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

// Fingerprints of the logged-in user (fprintd) and the switch that lets them
// log in, unlock and authorize with a finger (PAM).
RoundedItem {
    id: control

    property string errorText: ""
    property bool pendingPamValue: false

    Fingerprint {
        id: fingerprint

        onErrorOccurred: function(message) {
            control.errorText = message
            errorTimer.restart()
        }
    }

    Timer {
        id: errorTimer
        interval: 8000
        onTriggered: control.errorText = ""
    }

    function openEnrollDialog() {
        var component = Qt.createComponent("FingerprintEnrollDialog.qml")
        if (component.status === Component.Ready) {
            var dialog = component.createObject(rootWindow, { "fingerprint": fingerprint })
            dialog.closed.connect(dialog.destroy)
            dialog.open()
        } else {
            console.warn(component.errorString())
        }
    }

    RowLayout {
        spacing: LingmoUI.Units.largeSpacing

        Label {
            text: qsTr("Fingerprints")
            color: LingmoUI.Theme.secondaryTextColor
        }

        Item {
            Layout.fillWidth: true
        }

        Label {
            text: fingerprint.deviceName
            visible: fingerprint.deviceAvailable
            color: LingmoUI.Theme.secondaryTextColor
            elide: Text.ElideRight
            Layout.maximumWidth: control.width / 2
        }

        LingmoUI.Spinner {
            id: busyIndicator
            size: 22
            visible: !fingerprint.ready || fingerprint.busy || fingerprint.pamBusy
            running: busyIndicator.visible
        }
    }

    // No fprintd or no reader
    RowLayout {
        visible: fingerprint.ready && !fingerprint.deviceAvailable
        spacing: LingmoUI.Units.largeSpacing
        Layout.fillWidth: true

        Image {
            source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/fingerprint.svg" : "qrc:/images/light/fingerprint.svg"
            sourceSize: Qt.size(32, 32)
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            opacity: 0.4
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: LingmoUI.Theme.secondaryTextColor
            text: fingerprint.serviceAvailable
                  ? qsTr("No fingerprint reader was found. Connect a reader and open this page again.")
                  : qsTr("Fingerprint support is not installed. Install the fprintd package to use a fingerprint reader.")
        }
    }

    // Enrolled fingers
    ColumnLayout {
        visible: fingerprint.deviceAvailable
        spacing: LingmoUI.Units.smallSpacing
        Layout.fillWidth: true

        Label {
            visible: fingerprint.enrolledFingers.length === 0
            text: qsTr("No fingerprint registered yet.")
            color: LingmoUI.Theme.secondaryTextColor
        }

        Repeater {
            model: fingerprint.enrolledFingers

            RowLayout {
                spacing: LingmoUI.Units.largeSpacing
                Layout.fillWidth: true

                Image {
                    source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/fingerprint.svg" : "qrc:/images/light/fingerprint.svg"
                    sourceSize: Qt.size(22, 22)
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                }

                Label {
                    text: fingerprint.fingerName(modelData)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Button {
                    text: qsTr("Delete")
                    enabled: !fingerprint.busy && !fingerprint.enrolling
                    onClicked: fingerprint.deleteFinger(modelData)
                }
            }
        }

        RowLayout {
            spacing: LingmoUI.Units.largeSpacing
            Layout.topMargin: LingmoUI.Units.smallSpacing
            Layout.fillWidth: true

            Button {
                text: qsTr("Add fingerprint")
                flat: true
                enabled: !fingerprint.busy && !fingerprint.enrolling
                         && fingerprint.enrolledFingers.length < fingerprint.allFingers().length
                Layout.fillWidth: true
                onClicked: control.openEnrollDialog()
            }

            Button {
                text: qsTr("Delete all")
                visible: fingerprint.enrolledFingers.length > 1
                enabled: !fingerprint.busy && !fingerprint.enrolling
                Layout.fillWidth: true
                onClicked: deleteAllDialog.open()
            }
        }
    }

    // Log in / unlock / authorize with the finger
    HorizontalDivider {
        visible: pamLayout.visible
    }

    ColumnLayout {
        id: pamLayout
        visible: fingerprint.deviceAvailable || fingerprint.pamEnabled || fingerprint.pamPartial
        spacing: LingmoUI.Units.smallSpacing
        Layout.fillWidth: true

        RowLayout {
            spacing: LingmoUI.Units.largeSpacing
            Layout.fillWidth: true

            Label {
                text: qsTr("Use fingerprint to log in, unlock and authorize")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Switch {
                id: pamSwitch
                leftPadding: 0
                rightPadding: 0
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                checked: fingerprint.pamBusy ? control.pendingPamValue : fingerprint.pamEnabled
                enabled: !fingerprint.pamBusy
                         && fingerprint.pamHelperAvailable
                         && (fingerprint.pamEnabled || fingerprint.pamPartial
                             || (fingerprint.pamModuleAvailable && fingerprint.enrolledFingers.length > 0))

                onToggled: {
                    control.pendingPamValue = checked
                    fingerprint.setPamEnabled(checked)
                    checked = Qt.binding(function() {
                        return fingerprint.pamBusy ? control.pendingPamValue : fingerprint.pamEnabled
                    })
                }
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: LingmoUI.Theme.secondaryTextColor
            text: {
                if (!fingerprint.pamHelperAvailable)
                    return qsTr("The fingerprint-pam helper of Lingmo Settings is missing, so this can't be changed here.")
                if (!fingerprint.pamModuleAvailable && !fingerprint.pamEnabled)
                    return qsTr("The PAM module pam_fprintd is missing. Install the fprintd package.")
                if (fingerprint.pamPartial)
                    return qsTr("Fingerprint authentication is only partly set up. Turn it on again to repair it.")
                if (!fingerprint.pamEnabled && fingerprint.enrolledFingers.length === 0)
                    return qsTr("Register a fingerprint first.")
                return qsTr("The login screen, the lock screen, administrator prompts and sudo will accept your fingerprint. Your password keeps working.")
            }
        }
    }

    LingmoUI.Banner {
        type: LingmoUI.Banner.Error
        closable: false
        text: control.errorText
        Layout.fillWidth: true
    }

    Dialog {
        id: deleteAllDialog
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        title: qsTr("Delete all fingerprints?")

        ColumnLayout {
            spacing: LingmoUI.Units.largeSpacing * 1.5

            Label {
                text: qsTr("You will have to register them again to use the fingerprint reader.")
                wrapMode: Text.WordWrap
                Layout.maximumWidth: 320
            }

            RowLayout {
                spacing: LingmoUI.Units.largeSpacing

                Button {
                    text: qsTr("Cancel")
                    Layout.fillWidth: true
                    onClicked: deleteAllDialog.reject()
                }

                Button {
                    text: qsTr("Delete all")
                    flat: true
                    Layout.fillWidth: true
                    onClicked: {
                        deleteAllDialog.accept()
                        fingerprint.deleteAllFingers()
                    }
                }
            }
        }
    }
}
