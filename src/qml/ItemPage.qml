import QtQuick 2.4
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import LingmoUI.CompatibleModule 3.0 as LingmoUI


Page {
    id: page

    property string headerTitle
    // The module's sidebar glyph and tile colour, set by main.qml when it opens the page
    property url headerIconSource: ""
    property color headerIconColor: LingmoUI.Theme.highlightColor

    // Body text one step above the default size; captions set their own
    font.pointSize: LingmoUI.Units.fontBody

    background: Rectangle {
        color: rootWindow.background.color
    }

    header: Item {
        implicitHeight: Math.max(rootWindow.header.height, headerRow.implicitHeight + LingmoUI.Units.largeSpacing)

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: LingmoUI.Units.largeSpacing * 2
            anchors.rightMargin: LingmoUI.Units.largeSpacing * 2
            anchors.topMargin: LingmoUI.Units.smallSpacing
            spacing: LingmoUI.Units.smallSpacing * 1.5

            // Same tile as the sidebar (PageHeader only draws plain icons)
            Rectangle {
                id: tile
                visible: page.headerIconSource.toString().length > 0
                Layout.preferredWidth: LingmoUI.Units.iconTileSize + 4
                Layout.preferredHeight: LingmoUI.Units.iconTileSize + 4
                Layout.alignment: Qt.AlignVCenter
                radius: LingmoUI.Units.iconTileRadius + 1
                readonly property color base: LingmoUI.Theme.darkMode ? Qt.lighter(page.headerIconColor, 1.12)
                                                                      : Qt.darker(page.headerIconColor, 1.04)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(tile.base, LingmoUI.Theme.darkMode ? 1.18 : 1.12) }
                    GradientStop { position: 1.0; color: tile.base }
                }
                border.width: 1
                border.color: LingmoUI.Theme.borderColor

                Image {
                    anchors.centerIn: parent
                    width: LingmoUI.Units.iconSizes.small + 2
                    height: width
                    source: page.headerIconSource
                    sourceSize: Qt.size(width * 2, height * 2)
                    smooth: true
                }
            }

            LingmoUI.PageHeader {
                Layout.fillWidth: true
                title: page.headerTitle
                opacity: rootWindow.active ? 1.0 : 0.7

                Behavior on opacity {
                    NumberAnimation { duration: LingmoUI.Units.shortDuration }
                }
            }
        }
    }
}
