import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

import QtQuick.Dialogs
import QtCore
import Lingmo.Settings 1.0
import LingmoUI.CompatibleModule 3.0 as LingmoUI


import "../"

ItemPage {
    headerTitle: qsTr("Background")

    Background {
        id: background
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing

            FileDialog {
                id: fileDialog
                title: qsTr("Add images")
                fileMode: FileDialog.OpenFiles
                currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
                nameFilters: [qsTr("Images") + " (*.jpg *.jpeg *.png *.webp)", qsTr("All files") + " (*)"]
                onAccepted: background.addCustomBackgrounds(selectedFiles)
            }

            DesktopPreview {
               Layout.alignment: Qt.AlignHCenter
               // Qt 6 layouts size children from Layout.* hints, not width/height
               Layout.preferredWidth: 500
               Layout.preferredHeight: 300
            }

            RoundedItem {
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2

                    Label {
                        text: qsTr("Background type")
                        leftPadding: LingmoUI.Units.smallSpacing
                    }

                    LingmoUI.SegmentedControl {
                        id: tabBar
                        Layout.fillWidth: true
                        fillWidth: true
                        model: [qsTr("Picture"), qsTr("Color"), qsTr("Custom Images")]

                        // Pictures and custom images both are "picture" wallpapers (type 0)
                        onCurrentIndexChanged: {
                            const type = currentIndex === 1 ? 1 : 0
                            if (background.backgroundType !== type)
                                background.backgroundType = type
                        }

                        Component.onCompleted: {
                            currentIndex = background.backgroundType === 1 ? 1
                                         : background.isCustomBackground(background.currentBackgroundPath) ? 2 : 0
                        }
                    }
                }

                WallpaperGrid {
                    Layout.fillWidth: true
                    visible: tabBar.currentIndex === 0
                    paths: background.backgrounds
                }

                // The user's own pictures: ~/Pictures/Wallpapers
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: tabBar.currentIndex === 2
                    spacing: LingmoUI.Units.largeSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: LingmoUI.Units.largeSpacing

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            Label {
                                text: qsTr("Folder")
                                color: LingmoUI.Theme.secondaryTextColor
                            }

                            Label {
                                text: background.customFolder
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                        }

                        Button {
                            text: qsTr("Open folder")
                            icon.name: "folder-open"
                            onClicked: background.openCustomFolder()
                        }

                        Button {
                            text: qsTr("Add images")
                            icon.name: "list-add"
                            flat: true
                            onClicked: fileDialog.open()
                        }
                    }

                    WallpaperGrid {
                        Layout.fillWidth: true
                        visible: count > 0
                        paths: background.customBackgrounds
                        removable: true
                    }

                    LingmoUI.EmptyState {
                        Layout.fillWidth: true
                        Layout.topMargin: LingmoUI.Units.largeSpacing
                        Layout.bottomMargin: LingmoUI.Units.largeSpacing
                        visible: background.customBackgrounds.length === 0
                        iconName: "folder-pictures"
                        iconSize: LingmoUI.Units.iconSizes.large
                        text: qsTr("No images yet. Add images, or copy them into the folder above.")
                    }
                }

                Item {
                    visible: tabBar.currentIndex === 1
                    height: LingmoUI.Units.smallSpacing
                }

                Loader {
                    Layout.fillWidth: true
                    height: item ? item.height : 0
                    visible: tabBar.currentIndex === 1
                    sourceComponent: colorView
                }
            }

            Item {
                height: LingmoUI.Units.largeSpacing
            }
        }
    }

    Component {
        id: colorView

        GridView {
            id: _colorView
            Layout.fillWidth: true

            property int rowCount: _colorView.width / cellWidth

            implicitHeight: Math.ceil(_colorView.count / _colorView.rowCount) * cellHeight + LingmoUI.Units.largeSpacing

            cellWidth: 50
            cellHeight: 50

            interactive: false
            model: ListModel {}

            property var itemSize: 32

            Component.onCompleted: {
                model.append({"bgColor": "#2B8ADA"})
                model.append({"bgColor": "#4DA4ED"})
                model.append({"bgColor": "#FF5795"})
                model.append({"bgColor": "#FF8695"})
                model.append({"bgColor": "#008484"})
                model.append({"bgColor": "#B7E786"})
                model.append({"bgColor": "#F2BB73"})
                model.append({"bgColor": "#EE72EB"})
                model.append({"bgColor": "#F0905A"})
                model.append({"bgColor": "#C6C6C6"})
                model.append({"bgColor": "#595959"})
                model.append({"bgColor": "#000000"})
            }

            delegate: Rectangle {
                property bool checked: Qt.colorEqual(background.backgroundColor, bgColor)
                property color currentColor: bgColor

                width: _colorView.itemSize + LingmoUI.Units.largeSpacing
                height: width
                color: "transparent"
                radius: width / 2
                border.color: _mouseArea.pressed ? Qt.rgba(currentColor.r,
                                                           currentColor.g,
                                                           currentColor.b, 0.6)
                                                 : Qt.rgba(currentColor.r,
                                                           currentColor.g,
                                                           currentColor.b, 0.4)
                border.width: checked ? 3 : _mouseArea.containsMouse ? 2 : 0

                MouseArea {
                    id: _mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: background.backgroundColor = bgColor
                }

                Rectangle {
                    width: 32
                    height: width
                    anchors.centerIn: parent
                    color: currentColor
                    radius: width / 2
                }
            }
        }
    }

    // Grid of wallpaper thumbnails; a click sets the wallpaper
    component WallpaperGrid: GridView {
        id: grid

        property var paths: []
        property bool removable: false

        // At least one row, or the height below is NaN before the first layout pass
        property int rowCount: Math.max(1, Math.floor(grid.width / itemWidth))
        property int itemWidth: 180
        property int itemHeight: 127

        implicitHeight: Math.ceil(grid.count / rowCount) * cellHeight + LingmoUI.Units.largeSpacing
        clip: true
        model: paths
        currentIndex: -1
        interactive: false

        cellHeight: itemHeight
        cellWidth: calcExtraSpacing(itemWidth, grid.width) + itemWidth

        function calcExtraSpacing(cellSize, containerSize) {
            var availableColumns = Math.floor(containerSize / cellSize)
            var extraSpacing = 0
            if (availableColumns > 0) {
                var allColumnSize = availableColumns * cellSize
                var extraSpace = Math.max(containerSize - allColumnSize, 0)
                extraSpacing = extraSpace / availableColumns
            }
            return Math.floor(extraSpacing)
        }

        delegate: Item {
            id: item

            property bool isSelected: background.backgroundType === 0 && modelData === background.currentBackgroundPath

            width: GridView.view.cellWidth
            height: GridView.view.cellHeight
            scale: 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: LingmoUI.Units.shortDuration
                    easing.type: Easing.OutSine
                }
            }

            // Preload background
            Rectangle {
                anchors.fill: parent
                anchors.margins: LingmoUI.Units.largeSpacing
                radius: LingmoUI.Theme.bigRadius + LingmoUI.Units.smallSpacing / 2
                color: LingmoUI.Theme.backgroundColor
                visible: _image.status !== Image.Ready
            }

            // Preload image
            Image {
                anchors.centerIn: parent
                width: 32
                height: width
                sourceSize: Qt.size(width, height)
                source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/picture.svg"
                                              : "qrc:/images/light/picture.svg"
                visible: _image.status !== Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: LingmoUI.Units.smallSpacing
                color: "transparent"
                radius: LingmoUI.Theme.bigRadius + LingmoUI.Units.smallSpacing / 2

                border.color: LingmoUI.Theme.highlightColor
                border.width: _image.status == Image.Ready & isSelected ? 3 : 0

                Image {
                    id: _image
                    anchors.fill: parent
                    anchors.margins: LingmoUI.Units.smallSpacing
                    source: "file://" + modelData
                    sourceSize: Qt.size(width, height)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    mipmap: true
                    cache: true
                    smooth: true
                    opacity: 1.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: LingmoUI.Units.veryShortDuration
                            easing.type: Easing.InOutCubic
                        }
                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Item {
                            width: _image.width
                            height: _image.height

                            Rectangle {
                                anchors.fill: parent
                                radius: LingmoUI.Theme.bigRadius
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true

                    onClicked: {
                        if (background.backgroundType !== 0)
                            background.backgroundType = 0
                        background.setBackground(modelData)
                    }

                    onEntered: _image.opacity = 0.7
                    onExited: _image.opacity = 1.0
                    onPressedChanged: item.scale = pressed ? 0.97 : 1.0
                }

                // Remove (custom images only): the file goes to the trash
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: LingmoUI.Units.smallSpacing * 1.5
                    width: 22
                    height: 22
                    radius: 11
                    visible: grid.removable && (itemMouse.containsMouse || removeMouse.containsMouse)
                    color: removeMouse.containsMouse ? LingmoUI.Theme.redColor : Qt.rgba(0, 0, 0, 0.55)

                    Label {
                        anchors.centerIn: parent
                        text: "\u2715"
                        color: "white"
                        font.pointSize: LingmoUI.Units.fontCaption
                    }

                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: background.removeCustomBackground(modelData)
                    }
                }
            }
        }
    }
}
