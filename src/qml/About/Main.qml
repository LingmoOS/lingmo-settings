import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0
import Lingmo.System 1.0 as System
import LingmoUI 1.0 as LingmoUI
import Lingmo.Settings 1.0
import "../"

ItemPage {
    id: control
    headerTitle: qsTr("About")

    About {
        id: about
    }

    System.Wallpaper {
        id: wallpaper
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent

            SysItem {
                id: sysinf

                Image {
                    id: logo
                    anchors {
                        // top: parent.top
                        // bottom: parent.bottom
                        verticalCenter: parent.verticalCenter
                        right: lbt.left
                        rightMargin: sysinf.width/30
                    }
                    width: 250
                    sourceSize: Qt.size(width, height)
                    source: LingmoUI.Theme.darkMode ? "qrc:/images/logo.svg" : "qrc:/images/logo.svg"
                }

                Rectangle {
                    id: lbt
                    anchors {
                        centerIn: parent
                        verticalCenter: parent.verticalCenter
                    }
                    height: sysinf.height/1.2
                    width: 2
                    color: LingmoUI.Theme.disabledTextColor
                    opacity: LingmoUI.Theme.darkMode ? 0.7 : 0.5
                }

                Rectangle {
                    id: deviceItem

                    anchors {
                        left: lbt.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: sysinf.width/30
                    }
                    width: logo.width/1.2
                    height: logo.width/2
                    color: LingmoUI.Theme.backgroundColor
                    border.width: 5
                    border.color: LingmoUI.Theme.textColor
                    radius: LingmoUI.Theme.bigRadius

                    Image {
                        id: _image
                        width: deviceItem.width - 5
                        height: deviceItem.height - 5
                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                        }
                        // source: LingmoUI.Theme.darkMode ? "qrc:/images/MundoDark.jpeg" : "qrc:/images/MundoLight.jpeg"
                        source: "file://" + wallpaper.path
                        sourceSize: Qt.size(width, height)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        mipmap: true
                        cache: true
                        smooth: true
                        opacity: 1.0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 100
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

                    Loader {
                        id: bgLoader
                        anchors.fill: parent

                        sourceComponent: {
                            if (background.backgroundType === 0)
                                return wallpaperItem

                            return colorItem
                        }
                    }

                    Rectangle {
                        id: dockItem
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: _image.bottom
                        anchors.bottomMargin: 4
                        width: 128 + dockItem.height
                        height: 10.8
                        color: LingmoUI.Theme.backgroundColor
                        opacity: 0.85
                        border.width: 0.1
                        border.color: LingmoUI.Theme.textColor
                        radius: LingmoUI.Theme.bigRadius/3.5
                    }

                    Rectangle {
                        id: icon1
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: dockItem.left
                        anchors.leftMargin: 2
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#D4D4D4"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon2
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon1.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#DBC81E"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon3
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon2.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#464444"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon4
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon3.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#4891FF"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon5
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon4.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#FD5D93"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon6
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon5.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#0066FF"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon7
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon6.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#A537FF"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon8
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon7.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#FF4995"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon9
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon8.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#862D04"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon10
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon9.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#23A829"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon11
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon10.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#225366"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon12
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon11.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#DD9426"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon13
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon12.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#E74343"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }

                    Rectangle {
                        id: icon14
                        // anchors.horizontalCenter: dockItem.horizontalCenter
                        anchors.verticalCenter: dockItem.verticalCenter
                        anchors.left: icon13.right
                        anchors.leftMargin: 3
                        width: dockItem.height-4
                        height: icon1.width
                        color: "#24B4A1"
                        // opacity: 0.85
                        // border.width: 0.1
                        // border.color: LingmoUI.Theme.textColor
                        radius: 2
                    }
                }
            }

            // RoundedItem {
            //     StandardItem {
            //         key: qsTr("OS Version")
            //         // key: qsTr("System Version")
            //         value: about.version
            //     }

            //     Horizontalabt {}

            //     StandardItem {
            //         key: qsTr("System Release")
            //         value: about.systemrelease
            //     }
            // }

            RoundedItem {
                StandardItem {
                    key: qsTr("PC Name")
                    // key: qsTr("System Version")
                    value: about.hostName
                }

                Horizontalabt {}

                StandardItem {
                    key: qsTr("System Name")
                    value: about.version
                }

                Image {
                    id: editIcon

                    
                }
            }

                Item {
                height: LingmoUI.Units.smallSpacing
            }

            RoundedItem {
                StandardItem {
                    key: qsTr("Desktop Version")
                    value: about.desktopversion
                }

                Horizontalabt {}

                StandardItem {
                    key: qsTr("UI Version")
                    value: about.uiversion
                }

            }

            Item {
                height: LingmoUI.Units.smallSpacing
            }

            RoundedItem {
                StandardItem {
                    key: qsTr("System Type")
                    value: about.architecture
                }

                Horizontalabt {
                    
                }

                StandardItem {
                    key: qsTr("Kernel Version")
                    value: about.kernelVersion
                }

                Horizontalabt {

                }

                StandardItem {
                    key: qsTr("Processor")
                    value: about.cpuInfo
                }

                Horizontalabt {

                }

                StandardItem {
                    key: qsTr("RAM")
                    value: about.memorySize
                }

                Horizontalabt {

                }

                StandardItem {
                    key: qsTr("Internal Storage")
                    value: about.internalStorage
                }
            }

            Item {
                height: LingmoUI.Units.smallSpacing
            }

            StandardButton {
                Layout.fillWidth: true
                //visible: about.isLingmoOS
                text: qsTr("Software Update")
                onClicked: {
                    about.openUpdator()
                }
            }

            Item {
                height: LingmoUI.Units.smallSpacing
            }
        }
    }
}
