import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI 1.0 as LingmoUI
import Lingmo.Settings 1.0
import "../"

ItemPage {
    id: control
    headerTitle: qsTr("Update")

    Update {
        id: update
    }
    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight



    }  

}