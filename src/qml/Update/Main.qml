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

        ColumnLayout {
            id: layout
            anchors.fill: parent

            Image {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                width: 400
                height: 101
                // Layout.fillWidth: true
                sourceSize: Qt.size(width, height)
                // For Lingmo OS
                source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/lingmo-logo-g.png" : "qrc:/images/light/lingmo-logo-dark.png"
                // For OpenLingmo
                // source: LingmoUI.Theme.darkMode ? "qrc:/images/dark/OpenLingmo.png" : "qrc:/images/light/OpenLingmo.png"
            }

            Button {
                text: "Check for Update"
                onClicked: {
                    var versionData = download("https://os.lingmo.org/project/version.json");
                    var version = versionData.version;
                    var localVersion = system.getenv("VERSION");
                    if (version > localVersion) {
                        showUpdateDialog(version);
                    } else {
                        showInfoDialog("Your version is up to date.");
                    }
                }
            }

            Dialog {
                id: updateDialog
                title: "Update Available"
                content: Column {
                    Label {
                        text: "A new version of the application is available: " + version
                    }
                    Button {
                        text: "Download and Install"
                        onClicked: {
                            download("https://mirrors.packages.lingmo.org/update_f/updap.deb");
                            system.run("apt install /opt/.update/updap.deb");
                            system.exit(0);
                        }
                    }
                    Button {
                        text: "Remind Me Later"
                        onClicked: close()
                    }
                }
            }

            function download(url) {
                var request = new XMLHttpRequest();
                request.open("GET", url);
                request.send();
                return JSON.parse(request.responseText);
            }

            function showUpdateDialog(version) {
                updateDialog.version = version;
                updateDialog.open();
            }

            function showInfoDialog(message) {
                var infoDialog = Dialog {
                    title: "Info"
                    content: Text {
                        text: message
                    }
                    Button {
                        text: "OK"
                        onClicked: close()
                    }
                }
                infoDialog.open();
            }
        }
    }
}