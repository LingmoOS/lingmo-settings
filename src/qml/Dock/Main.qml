import QtQuick 2.4
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import Lingmo.Settings 1.0
import LingmoUI.CompatibleModule 3.0 as LingmoUI

import "../"

ItemPage {
    headerTitle: qsTr("Dock")

    Appearance {
        id: appearance
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing * 2

            RoundedItem {
                Label {
                    text: qsTr("Style")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2

                    IconCheckBox {
                        source: "qrc:/images/dock_straight.svg"
                        text: qsTr("Full")
                        checked: appearance.dockStyle === 1
                        onClicked: appearance.setDockStyle(1)
                    }

                    IconCheckBox {
                        source: "qrc:/images/dock_bottom.svg"
                        text: qsTr("Center")
                        checked: appearance.dockStyle === 0
                        onClicked: appearance.setDockStyle(0)
                    }
                }
            }

            // Background behind the icons
            RoundedItem {
                Label {
                    text: qsTr("Background")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2

                    IconCheckBox {
                        source: "qrc:/images/dock_bg_solid.svg"
                        text: qsTr("Solid")
                        checked: appearance.dockBackground === 0
                        onClicked: appearance.setDockBackground(0)
                    }

                    IconCheckBox {
                        source: "qrc:/images/dock_bg_glass.svg"
                        text: qsTr("Glass")
                        checked: appearance.dockBackground === 1
                        onClicked: appearance.setDockBackground(1)
                    }

                    IconCheckBox {
                        source: "qrc:/images/dock_bg_none.svg"
                        text: qsTr("No background")
                        checked: appearance.dockBackground === 2
                        onClicked: appearance.setDockBackground(2)
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: appearance.dockBackground !== 0
                    wrapMode: Text.WordWrap
                    color: LingmoUI.Theme.secondaryTextColor
                    text: qsTr("Glass and no background need desktop effects; without them the dock keeps the solid background.")
                }
            }

            // position
           RoundedItem {
               Label {
                   text: qsTr("Position on screen")
                   font.pointSize: LingmoUI.Units.fontSubheading
                   font.weight: Font.DemiBold
               }

               RowLayout {
                   spacing: LingmoUI.Units.largeSpacing * 2

                   IconCheckBox {
                       source: "qrc:/images/dock_left.svg"
                       text: qsTr("Left")
                       checked: appearance.dockDirection === 0
                       onClicked: appearance.setDockDirection(0)
                   }

                   IconCheckBox {
                       source: "qrc:/images/dock_bottom.svg"
                       text: qsTr("Bottom")
                       checked: appearance.dockDirection === 1
                       onClicked: appearance.setDockDirection(1)
                   }

                   IconCheckBox {
                       source: "qrc:/images/dock_right.svg"
                       text: qsTr("Right")
                       checked: appearance.dockDirection === 2
                       onClicked: appearance.setDockDirection(2)
                   }
               }
           }

            // Dock Size
            RoundedItem {
                Label {
                    text: qsTr("Size")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                LingmoUI.SegmentedControl {
                    id: dockSizeTabbar
                    fillWidth: true
                    model: [qsTr("Small"), qsTr("Medium"), qsTr("Large"), qsTr("Huge")]
                    Layout.fillWidth: true
                    Layout.bottomMargin: LingmoUI.Units.smallSpacing
                    onCurrentIndexChanged: {
                        var iconSize = 0

                        switch (currentIndex) {
                        case 0:
                            iconSize = 45
                            break;
                        case 1:
                            iconSize = 53
                            break;
                        case 2:
                            iconSize = 63
                            break;
                        case 3:
                            iconSize = 72
                            break;
                        }

                        appearance.setDockIconSize(iconSize)
                    }
                    // Follows the setting (also after a click, like TabBar did)
                    Binding on currentIndex {
                        value: {
                            var index = 0

                            if (appearance.dockIconSize <= 45)
                                index = 0
                            else if (appearance.dockIconSize <= 53)
                                index = 1
                            else if (appearance.dockIconSize <= 63)
                                index = 2
                            else if (appearance.dockIconSize <= 72)
                                index = 3

                            return index
                        }
                    }
                }
            }

            // Visibility
            RoundedItem {
                Label {
                    text: qsTr("Display mode")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                LingmoUI.SegmentedControl {
                    fillWidth: true
                    model: [qsTr("Always show"), qsTr("Always hide"), qsTr("Smart hide")]
                    Layout.fillWidth: true
                    onCurrentIndexChanged: appearance.setDockVisibility(currentIndex)
                    // Follows the setting (also after a click, like TabBar did)
                    Binding on currentIndex { value: appearance.dockVisibility }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
