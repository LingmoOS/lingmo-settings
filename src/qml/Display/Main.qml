/*
 * Copyright (C) 2024 LingmoOS Team.
 *
 * Author:     LingmoOS Team <team@lingmo.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import Lingmo.Settings 1.0
import Lingmo.Screen 1.0 as CS
import LingmoUI.CompatibleModule 3.0 as LingmoUI

import "../"

ItemPage {
    headerTitle: qsTr("Display")

    Appearance {
        id: appearance
    }

    Brightness {
        id: brightness
    }

    NightLight {
        id: nightLight
    }

    CS.Screen {
        id: screen
    }

    Timer {
        id: brightnessTimer
        interval: 100
        repeat: false

        onTriggered: {
            brightness.setValue(brightnessSlider.value)
        }
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing * 2

            RoundedItem {
                Layout.fillWidth: true
                visible: brightness.enabled

                Label {
                    text: qsTr("Brightness")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                    visible: brightness.enabled
                }

                Item {
                    height: LingmoUI.Units.smallSpacing / 2
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing

                    Image {
                        width: 16
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height
                        Layout.alignment: Qt.AlignVCenter
                        source: "qrc:/images/" + (LingmoUI.Theme.darkMode ? "dark" : "light") + "/display-brightness-low-symbolic.svg"
                    }

                    Slider {
                        id: brightnessSlider
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        value: brightness.value
                        from: 1
                        to: 100
                        stepSize: 1
                        onMoved: brightnessTimer.start()

                        ToolTip {
                            parent: brightnessSlider.handle
                            visible: brightnessSlider.pressed
                            text: brightnessSlider.value.toFixed(0)
                        }
                    }

                    Image {
                        width: 16
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height
                        Layout.alignment: Qt.AlignVCenter
                        source: "qrc:/images/" + (LingmoUI.Theme.darkMode ? "dark" : "light") + "/display-brightness-symbolic.svg"
                    }
                }

                Item {
                    height: LingmoUI.Units.smallSpacing / 2
                }
            }

            // Blue light filter, applied by lingmo-settings-daemon
            RoundedItem {
                visible: nightLight.available

                Label {
                    text: qsTr("Night Light")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: LingmoUI.Units.largeSpacing * 2

                    Label {
                        text: qsTr("Warmer colours on the screen reduce blue light and eye strain at night")
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Switch {
                        checked: nightLight.enabled
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        rightPadding: 0
                        onToggled: nightLight.enabled = checked
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: LingmoUI.Units.largeSpacing * 1.5
                    rowSpacing: LingmoUI.Units.largeSpacing * 1.5
                    enabled: nightLight.enabled
                    opacity: enabled ? 1.0 : 0.5

                    Label {
                        text: qsTr("Temperature")
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: LingmoUI.Units.largeSpacing

                        Label {
                            text: qsTr("Cooler")
                            color: LingmoUI.Theme.secondaryTextColor
                        }

                        Timer {
                            id: temperatureTimer
                            interval: 100
                            onTriggered: nightLight.temperature = temperatureSlider.value
                        }

                        // Warmer to the right
                        Slider {
                            id: temperatureSlider
                            Layout.fillWidth: true
                            // Shrinks with the larger body text instead of pushing "Warmer" out of the card
                            Layout.preferredWidth: 120
                            from: nightLight.maxTemperature
                            to: nightLight.minTemperature
                            stepSize: 100
                            value: nightLight.temperature
                            onMoved: temperatureTimer.start()

                            ToolTip {
                                parent: temperatureSlider.handle
                                visible: temperatureSlider.pressed
                                text: temperatureSlider.value.toFixed(0) + " K"
                            }
                        }

                        Label {
                            text: qsTr("Warmer")
                            color: LingmoUI.Theme.secondaryTextColor
                        }
                    }

                    Label {
                        text: qsTr("Schedule")
                    }

                    LingmoUI.SegmentedControl {
                        fillWidth: true
                        model: [qsTr("Always"), qsTr("Custom hours")]
                        Layout.fillWidth: true
                        // Follows the setting (also after a click, like TabBar did)
                        Binding on currentIndex { value: nightLight.mode }
                        onActivated: (index) => {
                            if (index === 0) { nightLight.mode = 0 }
                            else if (index === 1) { nightLight.mode = 1 }
                        }
                    }

                    Item {
                        width: 1
                        visible: nightLight.mode === 1
                    }

                    RowLayout {
                        visible: nightLight.mode === 1
                        spacing: LingmoUI.Units.largeSpacing

                        function saveSchedule() {
                            if (!nightLight.setSchedule(startField.text, endField.text)) {
                                startField.text = nightLight.startTime
                                endField.text = nightLight.endTime
                            }
                        }

                        Label {
                            text: qsTr("From")
                        }

                        TextField {
                            id: startField
                            text: nightLight.startTime
                            Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignHCenter
                            inputMethodHints: Qt.ImhTime
                            validator: RegularExpressionValidator { regularExpression: /^([01]?\d|2[0-3]):[0-5]\d$/ }
                            onEditingFinished: parent.saveSchedule()
                        }

                        Label {
                            text: qsTr("To")
                        }

                        TextField {
                            id: endField
                            text: nightLight.endTime
                            Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignHCenter
                            inputMethodHints: Qt.ImhTime
                            validator: RegularExpressionValidator { regularExpression: /^([01]?\d|2[0-3]):[0-5]\d$/ }
                            onEditingFinished: parent.saveSchedule()
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            RoundedItem {
                visible: _screenView.count > 0

                Label {
                    text: qsTr("Screen")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                    visible: _screenView.count > 0
                }

                // The monitors as they are arranged: click one to set it up below, drag it
                // to move it
                Item {
                    id: arrangement
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    visible: _screenView.count > 1

                    property int revision: 0
                    readonly property rect bounds: {
                        var x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
                        for (var i = 0; revision >= 0 && i < monitorRepeater.count; ++i) {
                            var item = monitorRepeater.itemAt(i)
                            if (!item)
                                continue
                            x0 = Math.min(x0, item.geo.x)
                            y0 = Math.min(y0, item.geo.y)
                            x1 = Math.max(x1, item.geo.x + item.geo.width)
                            y1 = Math.max(y1, item.geo.y + item.geo.height)
                        }
                        return x1 > x0 ? Qt.rect(x0, y0, x1 - x0, y1 - y0) : Qt.rect(0, 0, 1, 1)
                    }
                    readonly property real factor: Math.min(width / bounds.width, height / bounds.height)
                    readonly property real offsetX: (width - bounds.width * factor) / 2
                    readonly property real offsetY: (height - bounds.height * factor) / 2

                    // Where a monitor dropped with its top-left at (px, py) ends up: touching
                    // another monitor along an edge, aligned to its top/bottom or left/right,
                    // wherever is closest and doesn't overlap anything (like arandr, minus gaps)
                    function snap(index, px, py) {
                        var me = monitorRepeater.itemAt(index).geo
                        var w = me.width, h = me.height
                        var others = []
                        for (var i = 0; i < monitorRepeater.count; ++i) {
                            if (i !== index && monitorRepeater.itemAt(i))
                                others.push(monitorRepeater.itemAt(i).geo)
                        }
                        function overlaps(x, y) {
                            for (var k = 0; k < others.length; ++k) {
                                var o = others[k]
                                if (x < o.x + o.width && x + w > o.x && y < o.y + o.height && y + h > o.y)
                                    return true
                            }
                            return false
                        }
                        var best = null, bestDistance = Infinity
                        for (var j = 0; j < others.length; ++j) {
                            var o = others[j]
                            var spots = [
                                [o.x + o.width, o.y], [o.x + o.width, o.y + o.height - h],
                                [o.x - w, o.y], [o.x - w, o.y + o.height - h],
                                [o.x, o.y - h], [o.x + o.width - w, o.y - h],
                                [o.x, o.y + o.height], [o.x + o.width - w, o.y + o.height]
                            ]
                            for (var n = 0; n < spots.length; ++n) {
                                var d = Math.hypot(spots[n][0] - px, spots[n][1] - py)
                                if (d < bestDistance && !overlaps(spots[n][0], spots[n][1])) {
                                    bestDistance = d
                                    best = Qt.point(Math.round(spots[n][0]), Math.round(spots[n][1]))
                                }
                            }
                        }
                        return best
                    }

                    Repeater {
                        id: monitorRepeater
                        model: screen.outputModel
                        onItemAdded: arrangement.revision++
                        onItemRemoved: arrangement.revision++

                        delegate: Rectangle {
                            id: monitor
                            // Disabled monitors have no size: draw them as 1080p
                            readonly property rect geo: Qt.rect(model.normalizedPosition.x, model.normalizedPosition.y,
                                                                model.size.width > 0 ? model.size.width : 1920,
                                                                model.size.height > 0 ? model.size.height : 1080)
                            readonly property bool current: index === _screenView.currentIndex
                            // The model's name reads "Maker Model (CONNECTOR)"
                            readonly property string connector: {
                                var m = /\(([^)]+)\)$/.exec(model.display)
                                return m ? m[1] : model.display
                            }

                            onGeoChanged: arrangement.revision++

                            // How far it's being dragged, in pixels of the drawing
                            property real dragX: 0
                            property real dragY: 0
                            z: mouseArea.pressed ? 1 : 0

                            x: arrangement.offsetX + (geo.x - arrangement.bounds.x) * arrangement.factor + 3 + dragX
                            y: arrangement.offsetY + (geo.y - arrangement.bounds.y) * arrangement.factor + 3 + dragY
                            width: geo.width * arrangement.factor - 6
                            height: geo.height * arrangement.factor - 6
                            radius: LingmoUI.Theme.smallRadius
                            opacity: model.enabled ? 1 : 0.5
                            color: current ? LingmoUI.Theme.highlightColor : LingmoUI.Theme.secondBackgroundColor
                            border.width: 1
                            border.color: current ? LingmoUI.Theme.highlightColor
                                                  : LingmoUI.Theme.pressedColor

                            Behavior on color {
                                ColorAnimation { duration: LingmoUI.Units.shortDuration }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - LingmoUI.Units.smallSpacing * 2
                                spacing: 0

                                Label {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: monitor.connector
                                    font.bold: true
                                    color: monitor.current ? LingmoUI.Theme.highlightedTextColor : LingmoUI.Theme.textColor
                                }

                                Label {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    visible: model.primary || !model.enabled
                                    text: !model.enabled ? qsTr("Off") : qsTr("Primary")
                                    font.pointSize: LingmoUI.Units.fontCaption
                                    color: monitor.current ? LingmoUI.Theme.highlightedTextColor : LingmoUI.Theme.secondaryTextColor
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                property point start

                                onPressed: (mouse) => {
                                    start = mapToItem(arrangement, mouse.x, mouse.y)
                                    _screenView.currentIndex = index
                                }
                                onPositionChanged: (mouse) => {
                                    var p = mapToItem(arrangement, mouse.x, mouse.y)
                                    // Stay inside the drawing
                                    var baseX = monitor.x - monitor.dragX
                                    var baseY = monitor.y - monitor.dragY
                                    monitor.dragX = Math.max(-baseX, Math.min(arrangement.width - monitor.width - baseX, p.x - start.x))
                                    monitor.dragY = Math.max(-baseY, Math.min(arrangement.height - monitor.height - baseY, p.y - start.y))
                                }
                                onReleased: {
                                    var moved = Math.abs(monitor.dragX) + Math.abs(monitor.dragY) > 4
                                    // Back to the drawing's own coordinates: the whole desktop
                                    var px = monitor.geo.x + monitor.dragX / arrangement.factor
                                    var py = monitor.geo.y + monitor.dragY / arrangement.factor
                                    monitor.dragX = 0
                                    monitor.dragY = 0
                                    if (!moved || !model.enabled)
                                        return
                                    var spot = arrangement.snap(index, px, py)
                                    if (!spot || (spot.x === monitor.geo.x && spot.y === monitor.geo.y))
                                        return
                                    // The model takes positions in its own space, which only
                                    // differs from the drawing's by an offset
                                    var offset = Qt.point(model.position.x - model.normalizedPosition.x,
                                                          model.position.y - model.normalizedPosition.y)
                                    model.position = Qt.point(spot.x + offset.x, spot.y + offset.y)
                                    screen.save()
                                }
                            }
                        }
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    visible: arrangement.visible
                    text: qsTr("Drag the monitors to match how they sit on your desk")
                    color: LingmoUI.Theme.secondaryTextColor
                }

                ListView {
                    id: _screenView
                    Layout.fillWidth: true
                    model: screen.outputModel
                    orientation: ListView.Horizontal
                    interactive: false
                    clip: true

                    Layout.preferredHeight: currentItem ? currentItem.layout.implicitHeight + LingmoUI.Units.largeSpacing : 0

                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: LingmoUI.Units.longDuration
                            easing.type: Easing.OutSine
                        }
                    }

                    delegate: Item {
                        id: screenItem
                        height: ListView.view.height
                        width: ListView.view.width

                        property var element: model
                        property var layout: _mainLayout

                        ColumnLayout {
                            id: _mainLayout
                            anchors.fill: parent

                            GridLayout {
                                columns: 2
                                columnSpacing: LingmoUI.Units.largeSpacing * 1.5
                                rowSpacing: LingmoUI.Units.largeSpacing * 1.5

                                Label {
                                    text: qsTr("Screen Name")
                                    visible: _screenView.count > 1
                                }

                                Label {
                                    text: element.display
                                    color: LingmoUI.Theme.secondaryTextColor
                                    visible: _screenView.count > 1
                                }

                                Label {
                                    text: qsTr("Resolution")
                                }

                                ComboBox {
                                    Layout.fillWidth: true
                                    model: element.resolutions
                                    leftPadding: LingmoUI.Units.largeSpacing
                                    rightPadding: LingmoUI.Units.largeSpacing
                                    topInset: 0
                                    bottomInset: 0
                                    currentIndex: element.resolutionIndex !== undefined ?
                                                      element.resolutionIndex : -1
                                    onActivated: {
                                        element.resolutionIndex = currentIndex
                                        screen.save()
                                    }
                                }

                                Label {
                                    text: qsTr("Refresh rate")
                                }

                                ComboBox {
                                    id: refreshRate
                                    Layout.fillWidth: true
                                    model: element.refreshRates
                                    leftPadding: LingmoUI.Units.largeSpacing
                                    rightPadding: LingmoUI.Units.largeSpacing
                                    topInset: 0
                                    bottomInset: 0
                                    currentIndex: element.refreshRateIndex ?
                                                      element.refreshRateIndex : 0
                                    onActivated: {
                                        element.refreshRateIndex = currentIndex
                                        screen.save()
                                    }
                                }

                                Label {
                                    text: qsTr("Rotation")
                                }

                                Item {
                                    id: rotationItem
                                    Layout.fillWidth: true
                                    height: rotationLayout.implicitHeight

                                    RowLayout {
                                        id: rotationLayout
                                        anchors.fill: parent
                                        spacing: 0
                                        property int current_rot: element.rotation

                                        RotationButton {
                                            value: 0
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        RotationButton {
                                            value: 90
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        RotationButton {
                                            value: 180
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        RotationButton {
                                            value: 270
                                        }
                                    }
                                }

                                Label {
                                    text: qsTr("Enabled")
                                    visible: enabledBox.visible
                                }

                                CheckBox {
                                    id: enabledBox
                                    checked: element.enabled
                                    visible: _screenView.count > 1
                                    onClicked: {
                                        element.enabled = checked
                                        screen.save()
                                    }
                                }

                                // The status bar and the dock live on the primary screen
                                Label {
                                    text: qsTr("Primary display")
                                    visible: primaryBox.visible
                                }

                                RowLayout {
                                    visible: _screenView.count > 1
                                    spacing: LingmoUI.Units.largeSpacing

                                    Switch {
                                        id: primaryBox
                                        checked: element.primary
                                        // There's always one primary screen: pick another one to move it
                                        enabled: !element.primary && element.enabled
                                        onToggled: {
                                            element.primary = true
                                            screen.save()
                                        }
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: element.primary ? qsTr("Status bar and dock are shown here")
                                                              : qsTr("Show the status bar and dock on this display")
                                        color: LingmoUI.Theme.secondaryTextColor
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }
                }

                PageIndicator {
                    id: screenPageIndicator
                    Layout.alignment: Qt.AlignHCenter
                    count: _screenView.count
                    currentIndex: _screenView.currentIndex
                    onCurrentIndexChanged: _screenView.currentIndex = currentIndex
                    interactive: true
                    // The arrangement above picks the monitor
                    visible: false
                }
            }

            RoundedItem {
                Label {
                    text: qsTr("Scale")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                LingmoUI.SegmentedControl {
                    id: dockSizeTabbar
                    fillWidth: true
                    model: ["100%", "125%", "150%", "175%", "200%"]
                    Layout.fillWidth: true
                    onCurrentIndexChanged: {
                        var value = 1.0

                        switch (currentIndex) {
                        case 0:
                            value = 1.0
                            break;
                        case 1:
                            value = 1.25
                            break;
                        case 2:
                            value = 1.50
                            break;
                        case 3:
                            value = 1.75
                            break;
                        case 4:
                            value = 2.0
                            break;
                        }

                        if (appearance.devicePixelRatio !== value) {
                            appearance.setDevicePixelRatio(value)
                        }
                    }
                    // Follows the setting (also after a click, like TabBar did)
                    Binding on currentIndex {
                        value: {
                            var index = 0

                            if (appearance.devicePixelRatio <= 1.0)
                                index = 0
                            else if (appearance.devicePixelRatio <= 1.25)
                                index = 1
                            else if (appearance.devicePixelRatio <= 1.50)
                                index = 2
                            else if (appearance.devicePixelRatio <= 1.75)
                                index = 3
                            else if (appearance.devicePixelRatio <= 2.0)
                                index = 4

                            return index
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
