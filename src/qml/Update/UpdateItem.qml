import QtQuick 2.4
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import QtQuick.Window 2.3
import "../"

import LingmoUI 1.0 as LUI

Item {
    id: updateitem_
    height: _itemLayout.implicitHeight + LUI.Units.largeSpacing

    ColumnLayout {
        id: _itemLayout
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: LUI.Units.smallSpacing
        anchors.bottomMargin: LUI.Units.smallSpacing
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: _topItem.implicitHeight + LUI.Units.largeSpacing

            Rectangle {
                anchors.fill: parent
                radius: LUI.Theme.smallRadius
                color: LUI.Theme.textColor
                opacity: mouseArea.pressed ? 0.15 :  mouseArea.containsMouse ? 0.1 : 0.0
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    additionalInfos.toggle();
                }
            }

            RowLayout {
                id: _topItem
                anchors.fill: parent
                anchors.leftMargin: LUI.Units.smallSpacing
                anchors.rightMargin: LUI.Units.smallSpacing
                spacing: LUI.Units.largeSpacing

                Label {
                    text: package_name
                }

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    text: status
                }
            }

        }

        Hideable {
            id: additionalInfos
            spacing: 0
            Layout.leftMargin: 20

            Item {
                height: LUI.Units.largeSpacing
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: LUI.Units.largeSpacing

                Label {
                    text: qsTr("ChangeLogs")
                }

                Label {
                    text: changelog
                }
            }

            Item {
                height: LUI.Units.smallSpacing
            }

            HorizontalDivider {}
        }

    }
}

