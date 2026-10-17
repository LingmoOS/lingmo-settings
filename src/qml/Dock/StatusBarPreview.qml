import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI.CompatibleModule 3.0 as LingmoUI

// The top of a screen with the status bar at its real height (in px), so the
// choice can be judged before it's applied
Item {
    id: control

    property int barHeight: 28
    // Largest height the bar can have: the preview keeps its own height
    property int maxBarHeight: 40

    implicitHeight: maxBarHeight + 44

    Rectangle {
        id: _screen
        anchors.fill: parent
        radius: LingmoUI.Theme.mediumRadius
        clip: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(LingmoUI.Theme.highlightColor, LingmoUI.Theme.darkMode ? 0.9 : 1.35) }
            GradientStop { position: 1.0; color: Qt.darker(LingmoUI.Theme.highlightColor, LingmoUI.Theme.darkMode ? 1.8 : 1.15) }
        }

        // The bar: its top corners follow the screen's (a taller rounded
        // rectangle, cut at the bar's height)
        Item {
            id: _bar
            width: parent.width
            height: control.barHeight
            clip: true

            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Rectangle {
                width: parent.width
                height: parent.height + radius
                radius: _screen.radius
                color: LingmoUI.Theme.darkMode ? Qt.rgba(0.1, 0.1, 0.1, 0.72) : Qt.rgba(1, 1, 1, 0.72)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: LingmoUI.Units.largeSpacing
                anchors.rightMargin: LingmoUI.Units.largeSpacing
                spacing: Math.round(_bar.height * 0.35)

                readonly property real iconSize: Math.round(_bar.height * 0.55)
                readonly property real textSize: Math.max(8, Math.round(_bar.height * 0.45))

                Label {
                    text: qsTr("Files")
                    font.pixelSize: parent.textSize
                    font.weight: Font.DemiBold
                    color: LingmoUI.Theme.textColor
                }

                Item { Layout.fillWidth: true }

                Repeater {
                    model: ["network-wireless-symbolic", "audio-volume-high-symbolic", "battery-full-symbolic"]

                    LingmoUI.IconItem {
                        Layout.preferredWidth: parent.iconSize
                        Layout.preferredHeight: parent.iconSize
                        source: modelData
                    }
                }

                Label {
                    text: Qt.formatTime(new Date(2026, 0, 1, 9, 41), Qt.locale().timeFormat(Locale.ShortFormat))
                    font.pixelSize: parent.textSize
                    color: LingmoUI.Theme.textColor
                }
            }
        }

        Label {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: LingmoUI.Units.smallSpacing
            text: qsTr("%1 px").arg(control.barHeight)
            color: "white"
            opacity: 0.85
            font.pointSize: LingmoUI.Theme.fontSize * 0.85
        }
    }
}
