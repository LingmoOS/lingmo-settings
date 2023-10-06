import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI 1.0 as LingmoUI
import Lingmo.Settings 1.0
import "../"

ItemPage {
    id: control
    headerTitle: qsTr("About LingmoOS")

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
                width: 563
                height: 330
                sourceSize: Qt.size(width, height)
                // For Lingmo OS
                source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/nebula.png" : "qrc:/images/light/nebula.png"
                // For OpenLingmo
                // source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/OpenLingmo.png" : "qrc:/images/light/OpenLingmo.png"
            }

            RoundedItem {
                StandardItem {
                    key: qsTr("LingmoOS Version")
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
                    key: qsTr("OpenLingmo Version")
                    value: about.OpenLingmoVersion
                }
            }

                Item {
                height: LingmoUI.Units.smallSpacing
            }

            RoundedItem {
                StandardItem {
                    key: qsTr("Lingmo Desktop Version")
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

                Rectangle {
                    // anchors.fill: parent
                    Layout.fillWidth: true
                    width: 20
                    height: 1
                    color: LingmoUI.Theme.settingsTextColor
                }

                StandardItem {
                    key: qsTr("Update Type")
                    value: about.updateversion
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
                    // anchors.fill: 
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
