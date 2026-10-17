import QtQuick 2.12
import LingmoUI.CompatibleModule 3.0 as LingmoUI

// A small dock that magnifies the way the real one does (lingmo-dock's
// DockItem.qml): the icon under the pointer grows to `zoom` times its size
// and its neighbours a little less. Hover it, or watch the pointer that
// sweeps along it on its own.
Item {
    id: control

    // Magnification on: icons grow; off: they stay still
    property bool active: true
    // 1.25 - 2.0, like Settings › Dock › Zoom size
    property real zoom: 1.5

    readonly property int cell: 40
    readonly property real iconRatio: 0.8
    readonly property var icons: ["system-file-manager", "internet-web-browser", "utilities-terminal",
                                  "accessories-text-editor", "multimedia-photo-viewer",
                                  "preferences-system", "user-trash"]

    // Room for the biggest zoom, so the card doesn't change height with it
    readonly property real maxRoom: cell * (iconRatio * 2.0 - 0.9)

    implicitWidth: _panel.width
    implicitHeight: cell + maxRoom + LingmoUI.Units.largeSpacing

    // Where the pointer is along the panel: the mouse if it's over the
    // preview, else the sweeping one
    property real sweep: 0
    readonly property real pointer: _hover.hovered ? _hover.point.position.x - _panel.x : sweep

    HoverHandler {
        id: _hover
    }

    SequentialAnimation on sweep {
        running: control.active && control.visible && !_hover.hovered
        loops: Animation.Infinite
        NumberAnimation { from: control.cell * 0.5; to: _panel.width - control.cell * 0.5; duration: 2600; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 500 }
        NumberAnimation { from: _panel.width - control.cell * 0.5; to: control.cell * 0.5; duration: 2600; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 500 }
    }

    // The panel, like the dock's solid background
    Rectangle {
        id: _panel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: LingmoUI.Units.smallSpacing
        width: control.icons.length * control.cell
        height: control.cell
        radius: height * 0.35
        color: LingmoUI.Theme.darkMode ? "#2A2A2A" : "#DCDCDC"
        border.width: 1
        border.color: LingmoUI.Theme.darkMode ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)

        Row {
            anchors.fill: parent

            Repeater {
                model: control.icons

                Item {
                    id: _cell
                    width: control.cell
                    height: control.cell
                    z: amount

                    // Same falloff as the dock: two cells each way, smoothstep
                    readonly property real amount: {
                        if (!control.active || control.pointer < 0 || control.pointer > _panel.width)
                            return 0
                        const d = Math.abs((index + 0.5) * control.cell - control.pointer)
                        const t = Math.max(0, 1 - d / (control.cell * 2))
                        return t * t * (3 - 2 * t)
                    }

                    LingmoUI.IconItem {
                        anchors.centerIn: parent
                        width: control.cell * control.iconRatio
                        height: width
                        source: modelData
                        transformOrigin: Item.Bottom
                        scale: 1 + (control.zoom - 1) * _cell.amount

                        Behavior on scale {
                            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
