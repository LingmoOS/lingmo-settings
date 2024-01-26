import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI 1.0 as LingmoUI
import Lingmo.Settings 1.0
import "../"

ItemPage {
    id: control
    headerTitle: qsTr("About")

    About {
        id: about
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent

            // Item {
            //     height: LingmoUI.Units.largeSpacing
            // }

            Image {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                width: 400
                // height: 101
                // Layout.fillWidth: true
                sourceSize: Qt.size(width, height)
                // For Lingmo OS
                source: LingmoUI.Theme.darkMode ? "qrc:/images/logo.svg" : "qrc:/images/logo.svg"
                // For OpenLingmo
                // source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/OpenLingmo.png" : "qrc:/images/light/OpenLingmo.png"
            }

            RoundedItem {
                StandardItem {
                    key: qsTr("OS Version")
                    // key: qsTr("System Version")
                    value: about.version
                }

                Rectangle {
                    // anchors.fill: parent
                    Layout.fillWidth: true
                    width: 20
                    height: 1
                    color: LingmoUI.Theme.settingsTextColor
                }

                StandardItem {
                    key: qsTr("System Release")
                    value: about.systemrelease
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

                Rectangle {
                    // anchors.fill: parent
                    Layout.fillWidth: true
                    width: 20
                    height: 1
                    color: LingmoUI.Theme.settingsTextColor
                }

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

                Rectangle {
                    // anchors.fill: parent
                    Layout.fillWidth: true
                    width: 20
                    height: 1
                    color: LingmoUI.Theme.settingsTextColor
                }

                StandardItem {
                    key: qsTr("Kernel Version")
                    value: about.kernelVersion
                }

                Rectangle {
                    // anchors.fill: parent
                    Layout.fillWidth: true
                    width: 20
                    height: 1
                    color: LingmoUI.Theme.settingsTextColor
                }

                StandardItem {
                    key: qsTr("Processor")
                    value: about.cpuInfo
                }

                Rectangle {
                    // anchors.fill: parent
                    Layout.fillWidth: true
                    width: 20
                    height: 1
                    color: LingmoUI.Theme.settingsTextColor
                }

                StandardItem {
                    key: qsTr("RAM")
                    value: about.memorySize
                }

                Rectangle {
                    // anchors.fill: parent
                    Layout.fillWidth: true
                    width: 20
                    height: 1
                    color: LingmoUI.Theme.settingsTextColor
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
                // visible: about.isLingmofishOS
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
