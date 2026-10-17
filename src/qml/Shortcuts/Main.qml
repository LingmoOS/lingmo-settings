import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import "../"

ItemPage {
    headerTitle: qsTr("Shortcuts")

    Shortcuts {
        id: shortcuts
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
                        text: qsTr("Keyboard shortcuts")
                        font.pointSize: LingmoUI.Units.fontSubheading
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("Add shortcut")
                        icon.name: "list-add"
                        flat: true
                        onClicked: editor.edit("", "", "")
                    }
                }

                LingmoUI.EmptyState {
                    visible: listRepeater.count === 0
                    Layout.fillWidth: true
                    Layout.topMargin: LingmoUI.Units.smallSpacing
                    Layout.bottomMargin: LingmoUI.Units.smallSpacing
                    iconName: "preferences-desktop-keyboard-shortcuts"
                    iconSize: LingmoUI.Units.iconSizes.large
                    title: qsTr("No shortcuts yet")
                }

                Repeater {
                    id: listRepeater
                    model: shortcuts

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
                            onDoubleClicked: editor.edit(model.sequence, model.name, model.command)
                        }

                        RowLayout {
                            id: row
                            anchors.fill: parent
                            spacing: LingmoUI.Units.largeSpacing

                            KeyChip {
                                text: model.keys
                                Layout.preferredWidth: 150
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Label {
                                    text: model.name
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: model.command
                                    visible: model.command !== model.name
                                    color: LingmoUI.Theme.secondaryTextColor
                                    font.pointSize: LingmoUI.Units.fontCaption
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                            }

                            ToolButton {
                                icon.name: "document-edit"
                                ToolTip.text: qsTr("Edit")
                                ToolTip.visible: hovered
                                onClicked: editor.edit(model.sequence, model.name, model.command)
                            }

                            ToolButton {
                                icon.name: "edit-delete"
                                ToolTip.text: qsTr("Remove")
                                ToolTip.visible: hovered
                                onClicked: shortcuts.remove(model.sequence)
                            }
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: LingmoUI.Units.largeSpacing
                wrapMode: Text.WordWrap
                color: LingmoUI.Theme.secondaryTextColor
                text: qsTr("Changes apply immediately. Press Super alone to set a shortcut for tapping the Super key.")
            }
        }
    }

    // Key sequence shown as a keycap-like chip
    component KeyChip: Rectangle {
        property alias text: chipLabel.text
        implicitHeight: chipLabel.implicitHeight + LingmoUI.Units.smallSpacing * 1.5
        implicitWidth: chipLabel.implicitWidth + LingmoUI.Units.largeSpacing * 2
        radius: 6
        color: LingmoUI.Theme.hoverColor
        border.width: 1
        border.color: LingmoUI.Theme.borderColor

        Label {
            id: chipLabel
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - LingmoUI.Units.largeSpacing)
            elide: Text.ElideRight
            font.family: "monospace"
            font.weight: Font.DemiBold
        }
    }

    Popup {
        id: editor
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 420
        modal: true
        focus: true
        padding: LingmoUI.Units.largeSpacing * 1.5

        property string oldSequence
        property string sequence
        property bool capturing: false
        property bool metaAlone: false

        function edit(seq, name, command) {
            oldSequence = seq
            sequence = seq
            nameField.text = seq ? name : ""
            commandField.text = command
            errorLabel.text = ""
            capturing = seq === ""
            visible = true
            if (capturing)
                captureArea.forceActiveFocus()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing

            Label {
                text: editor.oldSequence ? qsTr("Edit shortcut") : qsTr("New shortcut")
                font.weight: Font.DemiBold
                font.pointSize: LingmoUI.Units.fontHeading
            }

            // Click, then press the keys
            Rectangle {
                id: captureArea
                Layout.fillWidth: true
                implicitHeight: 64
                radius: LingmoUI.Theme.mediumRadius
                color: editor.capturing ? Qt.rgba(LingmoUI.Theme.highlightColor.r,
                                                  LingmoUI.Theme.highlightColor.g,
                                                  LingmoUI.Theme.highlightColor.b, 0.12)
                                        : LingmoUI.Theme.hoverColor
                border.width: editor.capturing ? 2 : 1
                border.color: editor.capturing ? LingmoUI.Theme.highlightColor
                                               : LingmoUI.Theme.borderColor
                focus: editor.capturing

                KeyChip {
                    anchors.centerIn: parent
                    visible: !editor.capturing && editor.sequence !== ""
                    text: shortcuts.displayText(editor.sequence)
                }

                Label {
                    anchors.centerIn: parent
                    visible: editor.capturing || editor.sequence === ""
                    text: editor.capturing ? qsTr("Press the keys… (Esc to cancel)") : qsTr("Click to set the keys")
                    color: editor.capturing ? LingmoUI.Theme.highlightColor : LingmoUI.Theme.secondaryTextColor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        editor.capturing = true
                        captureArea.forceActiveFocus()
                    }
                }

                Keys.onPressed: (event) => {
                    if (!editor.capturing)
                        return
                    event.accepted = true
                    if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                        editor.capturing = false
                        return
                    }
                    // Super pressed alone: becomes "Meta" if released without another key
                    editor.metaAlone = (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L
                                        || event.key === Qt.Key_Super_R) && event.modifiers === Qt.MetaModifier
                    const seq = shortcuts.sequenceFromKey(event.key, event.modifiers)
                    if (seq !== "") {
                        editor.metaAlone = false
                        editor.sequence = seq
                        editor.capturing = false
                        errorLabel.text = ""
                    }
                }

                Keys.onReleased: (event) => {
                    if (editor.capturing && editor.metaAlone
                            && (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R)) {
                        event.accepted = true
                        editor.metaAlone = false
                        editor.sequence = "Meta"
                        editor.capturing = false
                        errorLabel.text = ""
                    }
                }
            }

            TextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: qsTr("Name (e.g. Screenshot)")
            }

            TextField {
                id: commandField
                Layout.fillWidth: true
                placeholderText: qsTr("Command (e.g. flameshot gui)")
                onAccepted: saveButton.clicked()
            }

            LingmoUI.Banner {
                id: errorLabel
                type: LingmoUI.Banner.Error
                closable: false
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: LingmoUI.Units.largeSpacing

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    onClicked: editor.close()
                }

                Button {
                    id: saveButton
                    text: qsTr("Save")
                    flat: true
                    onClicked: {
                        const error = shortcuts.save(editor.oldSequence, editor.sequence,
                                                     nameField.text, commandField.text)
                        if (error === "")
                            editor.close()
                        else
                            errorLabel.text = error
                    }
                }
            }
        }
    }
}
