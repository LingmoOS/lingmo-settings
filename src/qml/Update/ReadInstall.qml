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

            Item {
                height: LingmoUI.Units.largeSpacing
            }

            Label {
                text: "<b>" + qsTr("System Update ready") + "</b>"
                Layout.alignment: Qt.AlignHCenter
            }

            Button {
                text: qsTr("Update Now")
                Layout.alignment: Qt.AlignHCenter
                onClicked: update.installPkg()
            }

        }
    }
}