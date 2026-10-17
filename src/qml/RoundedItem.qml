import QtQuick 2.12
import QtQuick.Layouts 1.12
import LingmoUI.CompatibleModule 3.0 as LingmoUI

// The shared LingmoUI.Card, with its children stacked in a column
// (LingmoUI.Card leaves layout to the caller; every Settings group is a column)
LingmoUI.Card {
    id: card

    default property alias content: _mainLayout.data
    property alias spacing: _mainLayout.spacing
    property alias layout: _mainLayout

    Layout.fillWidth: true

    implicitHeight: _mainLayout.implicitHeight +
                    _mainLayout.anchors.topMargin +
                    _mainLayout.anchors.bottomMargin

    ColumnLayout {
        id: _mainLayout
        anchors.fill: parent
        anchors.leftMargin: card.padding
        anchors.rightMargin: card.padding
        anchors.topMargin: LingmoUI.Units.largeSpacing
        anchors.bottomMargin: LingmoUI.Units.largeSpacing
        spacing: LingmoUI.Units.largeSpacing
    }
}
