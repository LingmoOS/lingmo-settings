import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import CuteUI

LingmoScrollablePage{

    launchMode: LingmoPageType.SingleTask
    animDisabled: true

    ListModel{
        id:model_header
        ListElement{
            icon:"qrc:/srng/res/image/ic_home_github.png"
            title:"LingmoOS Web"
            desc:"The latest LingmoUI controls and styles for your applications."
            url:"https://lingmo.org"
        }
    }

    Item{
        Layout.fillWidth: true
        height: 320
        Image {
            id: bg
            fillMode:Image.PreserveAspectCrop
            anchors.fill: parent
            verticalAlignment: Qt.AlignTop
            source: "qrc:/srng/res/image/bg_home_header.png"
        }
        Rectangle{
            anchors.fill: parent
            gradient: Gradient{
                GradientStop { position: 0.8; color: LingmoTheme.dark ? Qt.rgba(0,0,0,0) : Qt.rgba(1,1,1,0) }
                GradientStop { position: 1.0; color: LingmoTheme.dark ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1) }
            }
        }
        LingmoText{
            text:"LingmoUI Gallery"
            font: LingmoTextStyle.TitleLarge
            anchors{
                top: parent.top
                left: parent.left
                topMargin: 20
                leftMargin: 20
            }
        }

        ListView{
            id: list
            anchors{
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            orientation: ListView.Horizontal
            height: 240
            model: model_header
            header: Item{height: 10;width: 10}
            footer: Item{height: 10;width: 10}
            ScrollBar.horizontal: LingmoScrollBar{
                id: scrollbar_header
            }
            clip: false
            delegate:Item{
                id: control
                width: 220
                height: 240
                LingmoItem{
                    radius: [8,8,8,8]
                    width: 200
                    height: 220
                    anchors.centerIn: parent
                    LingmoAcrylic{
                        anchors.fill: parent
                        tintColor: LingmoTheme.dark ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1)
                        target: bg
                        targetRect: Qt.rect(list.x-list.contentX+10+(control.width)*index,list.y+10,width,height)
                    }
                    Rectangle{
                        anchors.fill: parent
                        radius: 8
                        color:{
                            if(LingmoTheme.dark){
                                if(item_mouse.containsMouse){
                                    return Qt.rgba(1,1,1,0.03)
                                }
                                return Qt.rgba(0,0,0,0)
                            }else{
                                if(item_mouse.containsMouse){
                                    return Qt.rgba(0,0,0,0.03)
                                }
                                return Qt.rgba(0,0,0,0)
                            }
                        }
                    }
                    ColumnLayout{
                        Image {
                            Layout.topMargin: 20
                            Layout.leftMargin: 20
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 50
                            source: model.icon
                        }
                        LingmoText{
                            text: model.title
                            font: LingmoTextStyle.Body
                            Layout.topMargin: 20
                            Layout.leftMargin: 20
                        }
                        LingmoText{
                            text: model.desc
                            Layout.topMargin: 5
                            Layout.preferredWidth: 160
                            Layout.leftMargin: 20
                            color: LingmoColors.Grey120
                            font.pixelSize: 12
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                    LingmoIcon{
                        iconSource: LingmoentIcons.OpenInNewWindow
                        iconSize: 15
                        anchors{
                            bottom: parent.bottom
                            right: parent.right
                            rightMargin: 10
                            bottomMargin: 10
                        }
                    }
                    MouseArea{
                        id:item_mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onWheel: (wheel)=>{
                            if (wheel.angleDelta.y > 0) scrollbar_header.decrease()
                            else scrollbar_header.increase()
                        }
                        onClicked: {
                            Qt.openUrlExternally(model.url)
                        }
                    }
                }
            }
        }
    }

    Component{
        id:com_item
        Item{
            width: 320
            height: 120
            LingmoArea{
                radius: 8
                width: 300
                height: 100
                anchors.centerIn: parent
                Rectangle{
                    anchors.fill: parent
                    radius: 8
                    color:{
                        if(LingmoTheme.dark){
                            if(item_mouse.containsMouse){
                                return Qt.rgba(1,1,1,0.03)
                            }
                            return Qt.rgba(0,0,0,0)
                        }else{
                            if(item_mouse.containsMouse){
                                return Qt.rgba(0,0,0,0.03)
                            }
                            return Qt.rgba(0,0,0,0)
                        }
                    }
                }
                Image{
                    id:item_icon
                    height: 40
                    width: 40
                    source: modelData.image
                    anchors{
                        left: parent.left
                        leftMargin: 20
                        verticalCenter: parent.verticalCenter
                    }
                }

                LingmoText{
                    id:item_title
                    text:modelData.title
                    font: LingmoTextStyle.BodyStrong
                    anchors{
                        left: item_icon.right
                        leftMargin: 20
                        top: item_icon.top
                    }
                }

                LingmoText{
                    id:item_desc
                    text:modelData.desc
                    color:LingmoColors.Grey120
                    wrapMode: Text.WrapAnywhere
                    elide: Text.ElideRight
                    font: LingmoTextStyle.Caption
                    maximumLineCount: 2
                    anchors{
                        left: item_title.left
                        right: parent.right
                        rightMargin: 20
                        top: item_title.bottom
                        topMargin: 5
                    }
                }

                Rectangle{
                    height: 12
                    width: 12
                    radius:  6
                    color: LingmoTheme.primaryColor.dark
                    anchors{
                        right: parent.right
                        top: parent.top
                        rightMargin: 14
                        topMargin: 14
                    }
                }

                MouseArea{
                    id:item_mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        ItemsOriginal.startPageByItem(modelData)
                    }
                }
            }
        }
    }

    LingmoText{
        text: "Recently added samples"
        font: LingmoTextStyle.Title
        Layout.topMargin: 20
        Layout.leftMargin: 20
    }

    GridView{
        Layout.fillWidth: true
        implicitHeight: contentHeight
        cellHeight: 120
        cellWidth: 320
        model:ItemsOriginal.getRecentlyAddedData()
        interactive: false
        delegate: com_item
    }

    LingmoText{
        text: "Recently updated samples"
        font: LingmoTextStyle.Title
        Layout.topMargin: 20
        Layout.leftMargin: 20
    }

    GridView{
        Layout.fillWidth: true
        implicitHeight: contentHeight
        cellHeight: 120
        cellWidth: 320
        interactive: false
        model: ItemsOriginal.getRecentlyUpdatedData()
        delegate: com_item
    }

}
