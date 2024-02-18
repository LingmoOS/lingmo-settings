import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI 1.0 as LingmoUI
import Lingmo.Settings 1.0
import "../"

Item {
    id: control

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent

            Image {
                width: 64
                height: 64
                sourceSize: Qt.size(width, height)
                source: "image://icontheme/" + (control.success ? "process-completed-symbolic" : "process-error-symbolic")
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                topPadding: LingmoUI.Units.largeSpacing
                text: qsTr("The update is complete and we recommend that you restart your computer.")
                Layout.alignment: Qt.AlignHCenter
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                spacing: LingmoUI.Units.largeSpacing

                Button {
                    text: qsTr("Done")
                    Layout.fillWidth: true
                    onClicked: Qt.quit()
                }

                Button {
                    visible: success
                    text: qsTr("Reboot")
                    Layout.fillWidth: true
                    flat: true
                    onClicked: update.rebootSys()
                }
            }
        }
    }
}   