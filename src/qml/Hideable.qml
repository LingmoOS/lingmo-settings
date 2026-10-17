import QtQuick 2.4
import QtQuick.Layouts 1.3
import Qt5Compat.GraphicalEffects
import LingmoUI.CompatibleModule 3.0 as LingmoUI


Item {
    id: _root
    implicitHeight: shown ? _contentLayout.implicitHeight : 0
    Layout.fillWidth: true
    clip: true

    default property alias content: _contentLayout.data
    property bool shown: false
    property alias spacing: _contentLayout.spacing

    Behavior on implicitHeight {
        NumberAnimation {
            duration: LingmoUI.Units.shortDuration
            easing.type: Easing.OutSine
        }
    }

    ColumnLayout {
        id: _contentLayout
        anchors.fill: parent
    }

    function show() {
        shown = true
    }

    function hide() {
        shown = false
    }

    function toggle() {
        shown = !shown
    }
}
