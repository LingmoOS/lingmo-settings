import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import LingmoUI 1.0 as LingmoUI
import Lingmo.Settings 1.0
import "../"

ItemPage {
    id: control
    headerTitle: qsTr("System Update")

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: homePage
    }

    Update {
        id: update
        
        onHaneupdate: {
            stackView.push(readUpdate)
        }

        onNoupdate: {
            stackView.push(noUpdate)
        }

        onDownloaddown: {
            stackView.push(readInstall)
        }

        onInstallDone: {
            stackView.push(installDone)
        }
    }

    Component {
        id: readUpdate

        ReadUpdate { }
    }

    Component {
        id: noUpdate

        UpdatePage {}
    }

    Component {
        id: readInstall

        ReadInstall {}
    }

    Component {
        id: installDone

        InstallDone {}
    }

}