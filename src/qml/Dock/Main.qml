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

            // Magnification: icons grow under the pointer
            RoundedItem {
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: qsTr("Magnification")
                            font.pointSize: LingmoUI.Units.fontSubheading
                            font.weight: Font.DemiBold
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Icons grow as the pointer moves over them")
                            color: LingmoUI.Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                        }
                    }

                    Switch {
                        id: _magnificationSwitch
                        Layout.alignment: Qt.AlignVCenter
                        checked: appearance.dockMagnification
                        onClicked: appearance.setDockMagnification(checked)
                    }
                }

                MagnificationPreview {
                    Layout.fillWidth: true
                    active: appearance.dockMagnification
                    zoom: _zoomSlider.value / 100
                    opacity: active ? 1 : 0.6
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: LingmoUI.Units.largeSpacing
                    enabled: appearance.dockMagnification

                    Label {
                        text: qsTr("Zoom size")
                    }

                    Label {
                        text: qsTr("Small")
                        color: LingmoUI.Theme.secondaryTextColor
                        font.pointSize: LingmoUI.Theme.fontSize * 0.9
                    }

                    Slider {
                        id: _zoomSlider
                        Layout.fillWidth: true
                        from: 125
                        to: 200
                        stepSize: 5
                        snapMode: Slider.SnapAlways
                        value: appearance.dockMagnificationSize
                        // The preview follows while dragging; the dock is resized once, on release
                        onPressedChanged: {
                            if (!pressed)
                                appearance.setDockMagnificationSize(Math.round(value))
                        }
                        onMoved: {
                            if (!pressed)
                                appearance.setDockMagnificationSize(Math.round(value))
                        }

                        Connections {
                            target: appearance
                            function onDockMagnificationSizeChanged() {
                                _zoomSlider.value = appearance.dockMagnificationSize
                            }
                        }
                    }

                    Label {
                        text: qsTr("Large")
                        color: LingmoUI.Theme.secondaryTextColor
                        font.pointSize: LingmoUI.Theme.fontSize * 0.9
                    }

                    Label {
                        Layout.preferredWidth: _percentMetrics.advanceWidth
                        horizontalAlignment: Text.AlignRight
                        text: qsTr("%1%").arg(Math.round(_zoomSlider.value))

                        TextMetrics {
                            id: _percentMetrics
                            text: qsTr("%1%").arg(200)
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

            // Status bar at the top of the screen
            RoundedItem {
                Label {
                    text: qsTr("Status bar height")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                StatusBarPreview {
                    Layout.fillWidth: true
                    barHeight: _statusBarSizes.currentIndex >= 0 ? _statusBarSizes.heights[_statusBarSizes.currentIndex]
                                                                 : appearance.statusBarHeight
                    maxBarHeight: appearance.statusBarMaxHeight
                }

                LingmoUI.SegmentedControl {
                    id: _statusBarSizes
                    // 28 is the status bar's default
                    readonly property var heights: [24, 28, 32, 36]
                    fillWidth: true
                    Layout.fillWidth: true
                    Layout.bottomMargin: LingmoUI.Units.smallSpacing
                    model: [qsTr("Compact"), qsTr("Standard"), qsTr("Large"), qsTr("Extra large")]
                    onActivated: function(index) { appearance.setStatusBarHeight(heights[index]) }
                    // Follows the setting; a height set by hand that isn't a preset selects nothing
                    Binding on currentIndex { value: _statusBarSizes.heights.indexOf(appearance.statusBarHeight) }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
