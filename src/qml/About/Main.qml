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

            Item {
                height: LingmoUI.Units.largeSpacing
            }

            Image {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                width: 400
                // height: 101
                // Layout.fillWidth: true
                sourceSize: Qt.size(width, height)
                // For Lingmo OS
                source: LingmoUI.Theme.darkMode ? "qrc:/images/logo.png" : "qrc:/images/logo.png"
                // For OpenLingmo
                // source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/OpenLingmo.png" : "qrc:/images/light/OpenLingmo.png"
            }

            Item {
                height: LingmoUI.Units.largeSpacing
            }

            RoundedItem {
                StandardItem {
                    key: qsTr("OS Version")
                    // key: qsTr("System Version")
                    value: about.version
                }

                Horizontalabt {}

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
        }
    }
}
