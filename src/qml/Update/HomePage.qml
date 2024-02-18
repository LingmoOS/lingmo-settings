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

            UpdateView {
               Layout.alignment: Qt.AlignHCenter
               width: 200
               height: 120
            }

            Item {
                height: LingmoUI.Units.largeSpacing
            }

            Label {
                text: qsTr("Current Version: %1").arg(update.version)
                Layout.alignment: Qt.AlignHCenter
            }

            Item {
                height: LingmoUI.Units.largeSpacing
            }

            Button {
                text: qsTr("Check Update")
                Layout.alignment: Qt.AlignHCenter
                onClicked: update.getUpdateInfo()
            }

        }
    }
}