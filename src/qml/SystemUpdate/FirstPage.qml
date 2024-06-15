import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Templates 2.12 as T
import QtGraphicalEffects 1.0
import QtWebEngine 1.2
import LingmoUI 1.0 as LingmoUI
import Lingmo.Settings 1.0
import "../"

Item {
    id: control

    property bool check: false
    property bool checked: true

    Connections {
        target: updator
    }

    property color flatHoveredColor: Qt.lighter(LingmoUI.Theme.highlightColor, 1.1)
    property color flatPressedColor: Qt.darker(LingmoUI.Theme.highlightColor, 1.1)

    ColumnLayout {
        anchors.fill: parent
        spacing: LingmoUI.Units.largeSpacing * 2

        Image {
            // visible: _updateInfo.count !== 0
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            width: 200
            sourceSize: Qt.size(width, height)
            source: LingmoUI.Theme.darkMode ? "qrc:/images/logo.png" : "qrc:/images/logo.png"
        }

        Layout.fillWidth: true
        Layout.fillHeight: true

        Item {
            Layout.fillWidth: true
            height: 50

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: LingmoUI.Units.largeSpacing
                anchors.rightMargin: LingmoUI.Units.largeSpacing
                color: LingmoUI.Theme.secondBackgroundColor
                radius: LingmoUI.Theme.mediumRadius
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: LingmoUI.Units.largeSpacing * 1.5
                anchors.rightMargin: LingmoUI.Units.largeSpacing * 1.5
                spacing: LingmoUI.Units.smallSpacing

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Item {
                            Layout.fillHeight: true
                        }
                        
                        Label {
                            visible: !control.check
                            text: "System Update"
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: !control.checked
                            text: "Checking... " + updator.checkProgress + "%"
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: _listView.count !== 0
                            text: qsTr("Has Update")
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: !control.check
                            text: qsTr("Current Version: %1").arg(updator.version)
                            color: LingmoUI.Theme.disabledTextColor
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                Button {
                    visible: !control.check
                    text: qsTr("Check Update")
                    flat: true
                    onClicked: {
                        // stackView.push(homePage)
                        control.check = true
                        control.checked = false
                        // _textArea.clear()
                        updator.checkUpdates()
                    }
                }

                // LingmoUI.BusyIndicator {
                //     width: 50
                //     height: 50
                //     Layout.alignment: Qt.AlignHCenter
                //     visible: control.check
                // }

                Label {
                    visible: control.check
                    Layout.fillWidth: true
                }

                ProgressBar{
                    id: _progressBar
                    visible: !control.checked
                    from: 0
                    to: 100
                    value: updator.checkProgress
                    width: 130
                    height: 5

                    // Text {
                    //     id: _progressbarText
                    //     anchors.left: parent.right;
                    //     anchors.leftMargin: 10
                    //     anchors.verticalCenter: parent.verticalCenter;
                    //     text: "Checking... " + updator.checkProgress + "%"
                    //     color: LingmoUI.Theme.highlightedTextColor
                    //     font: control.font
                    // }

                    background: Rectangle {   
                        implicitWidth: _progressBar.width
                        implicitHeight: _progressBar.height
                        radius: LingmoUI.Theme.hugeRadius
                        color: rootWindow.background.color
                    }

                    contentItem: Item {
                        Rectangle {
                            id: _flatBackground
                            width: _progressBar.visualPosition * _progressBar.width
                            height: _progressBar.height
                            radius: LingmoUI.Theme.hugeRadius

                            color: Qt.rgba(LingmoUI.Theme.highlightColor.r,
                                            LingmoUI.Theme.highlightColor.g,
                                            LingmoUI.Theme.highlightColor.b, 0.1)
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: Qt.rgba(_flatBackground.color.r,
                                                                            _flatBackground.color.g,
                                                                            _flatBackground.color.b, 0.78) }
                                GradientStop { position: 1.0; color: Qt.rgba(_flatBackground.color.r,
                                                                            _flatBackground.color.g,
                                                                            _flatBackground.color.b, 1) }
                            }
                        }
                    }
                }

                // Label {
                //     text: qsTr("Checking for updates...")
                //     Layout.alignment: Qt.AlignHCenter
                //     visible: control.check
                // }
            }

            Rectangle {
                visible: _listView.count !== 0
                anchors.fill: parent
                anchors.leftMargin: LingmoUI.Units.largeSpacing
                anchors.rightMargin: LingmoUI.Units.largeSpacing
                color: LingmoUI.Theme.secondBackgroundColor
                radius: LingmoUI.Theme.mediumRadius
            }

            RowLayout {
                
                anchors.fill: parent
                anchors.leftMargin: LingmoUI.Units.largeSpacing * 1.5
                anchors.rightMargin: LingmoUI.Units.largeSpacing * 1.5
                spacing: LingmoUI.Units.smallSpacing

                Image {
                    visible: _listView.count !== 0
                    height: 32
                    width: 32
                    sourceSize: Qt.size(width, height)
                    source: "image://icontheme/" + "sysytemlogo"
                    smooth: true
                    antialiasing: true
                }

                Item {
                    visible: _listView.count !== 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Item {
                            Layout.fillHeight: true
                        }

                        Label {
                            visible: _listView.count !== 0
                            text: qsTr("Has Update")
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: !control.check
                            text: qsTr("Current Version: %1").arg(updator.version)
                            color: LingmoUI.Theme.disabledTextColor
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
                Button {
                    // visible: _listView.count !== 0
                    text: qsTr("Update now")
                    visible: _listView.count !== 0
                    flat: true
                    onClicked: updator.upgrade()
                }
            }

            // Label {
            //     text: "ChangeLogs: " + updator.changelogs
            //     visible: _listView.count !== 0
            //     Layout.alignment: Qt.AlignHCenter
            // }

            Item {
                height: LingmoUI.Units.largeSpacing
            }

            Rectangle {
                visible: _listView.count !== 0
                // anchors.fill: parent
                // anchors.top: parent.top
                // anchors.topMargin: 100
                anchors.leftMargin: LingmoUI.Units.largeSpacing
                anchors.rightMargin: LingmoUI.Units.largeSpacing
                color: LingmoUI.Theme.secondBackgroundColor
                radius: LingmoUI.Theme.mediumRadius
            }

            RowLayout {
                
                anchors.fill: parent
                anchors.top: parent.top
                anchors.topMargin: 100
                anchors.leftMargin: LingmoUI.Units.largeSpacing * 1.5
                anchors.rightMargin: LingmoUI.Units.largeSpacing * 1.5
                spacing: LingmoUI.Units.smallSpacing
                Item {
                    visible: _listView.count !== 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    WebEngineView {
                        id: sitemonitoryView
                        width:parent.width
                        height:parent.height
                        backgroundColor: "transparent"
                        anchors.centerIn: parent
                        settings.javascriptEnabled : true
                        settings.pluginsEnabled:true
                        url:"file:///var/update/cache/changelog.html"
                    }
                }
            }
        }
        ListView {
            id: _listView
            model: upgradeableModel

            visible: _listView.count !== 0
            spacing: LingmoUI.Units.largeSpacing
            clip: true

            // ScrollBar.vertical: ScrollBar {}

            Layout.fillWidth: true
            Layout.fillHeight: true

            delegate: Item {
                width: ListView.view.width
                height: 50

                // Rectangle {
                //     anchors.fill: parent
                //     anchors.leftMargin: LingmoUI.Units.largeSpacing
                //     anchors.rightMargin: LingmoUI.Units.largeSpacing
                //     color: LingmoUI.Theme.secondBackgroundColor
                //     radius: LingmoUI.Theme.mediumRadius
                // }

                // RowLayout {
                //     anchors.fill: parent
                //     anchors.leftMargin: LingmoUI.Units.largeSpacing * 1.5
                //     anchors.rightMargin: LingmoUI.Units.largeSpacing * 1.5
                //     spacing: LingmoUI.Units.smallSpacing

                //     Image {
                //         height: 32
                //         width: 32
                //         sourceSize: Qt.size(width, height)
                //         source: "image://icontheme/" + model.name
                //         smooth: true
                //         antialiasing: true
                //     }

                //     // Name and version
                //     Item {
                //         Layout.fillWidth: true
                //         Layout.fillHeight: true

                //         ColumnLayout {
                //             anchors.fill: parent
                //             spacing: 0

                //             Item {
                //                 Layout.fillHeight: true
                //             }

                //             Label {
                //                 text: model.name
                //                 Layout.fillWidth: true
                //             }

                //             Label {
                //                 text: model.version
                //                 color: LingmoUI.Theme.disabledTextColor
                //             }

                //             Item {
                //                 Layout.fillHeight: true
                //             }
                //         }
                //     }

                //     // Size
                //     // Label {
                //     //     text: model.downloadSize
                //     //     color: LingmoUI.Theme.disabledTextColor
                //     // }
                // }
            }
        }

        Item {
            Layout.fillHeight: !_listView.visible
        }

        Item {
            height: LingmoUI.Units.smallSpacing
            visible: _listView.visible
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
