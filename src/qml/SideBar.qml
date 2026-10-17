/*
 * Copyright (C) 2024 Lingmo OS Team.
 *
 * Author:     Lingmo OS Team <team@lingmo.org>
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

import QtQuick 2.4
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import Lingmo.NetworkManagement 1.0 as NM

// The shared Settings sidebar, with the module list and a search field that
// matches titles and keywords
LingmoUI.SettingsSideBar {
    id: control

    model: listModel
    sectionRole: "category"
    searchVisible: true
    searchPlaceholder: qsTr("Search")
    // Filtered rows collapse to zero height, so drop the gaps while searching
    view.spacing: searchQuery.length > 0 ? 0 : LingmoUI.Units.smallSpacing

    readonly property string searchQuery: searchText.trim().toLowerCase()
    readonly property int matchCount: {
        var n = 0
        for (var i = 0; i < listModel.count; ++i) {
            if (matches(listModel.get(i)))
                ++n
        }
        return n
    }

    function matches(item) {
        if (searchQuery.length === 0)
            return true
        var text = [item.title, item.keywords, item.name].filter(function (t) { return !!t }).join(",")
        return text.toLowerCase().indexOf(searchQuery) !== -1
    }

    // Sidebar glyphs ship in qrc:/images/sidebar/all; plugins may pass a full url
    function iconUrl(source) {
        if (!source)
            return ""
        return source.indexOf("/") !== -1 ? source : "qrc:/images/sidebar/all/" + source
    }

    // Enter opens the first match
    onSearchAccepted: {
        for (var i = 0; i < listModel.count; ++i) {
            if (matches(listModel.get(i))) {
                currentIndex = i
                break
            }
        }
    }

    view.delegate: LingmoUI.SideBarItem {
        required property int index
        required property var model

        width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
        visible: control.matches(model)
        height: visible ? implicitHeight : 0

        title: model.title
        // As iconName: SideBarItem's hidden plain Image loops on sourceSize when given an iconSource
        iconName: control.iconUrl(model.iconSource)
        tileColor: model.iconColor ? model.iconColor : LingmoUI.Theme.highlightColor
        isCurrent: ListView.view.currentIndex === index
        drawHighlight: false

        onClicked: ListView.view.currentIndex = index
    }

    LingmoUI.EmptyState {
        anchors.centerIn: parent
        width: parent.width - LingmoUI.Units.largeSpacing * 2
        visible: control.matchCount === 0
        iconName: "edit-find"
        iconSize: LingmoUI.Units.iconSizes.large
        title: qsTr("No results")
        text: qsTr("Try a different word.")
    }

    ListModel {
        id: listModel

        ListElement {
            title: qsTr("WLAN")
            name: "wlan"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("Wi-Fi, wireless, network, internet")
            page: "qrc:/qml/WLAN/Main.qml"
            // source: "wlan.svg"
            iconSource: "wlan.svg"
            iconColor: "#0A84FF"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Ethernet")
            name: "ethernet"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("wired, cable, network, LAN, internet")
            page: "qrc:/qml/Wired/Main.qml"
            // source: "network.svg"
            iconSource: "network.svg"
            iconColor: "#32ADE6"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Bluetooth")
            name: "bluetooth"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("devices, pairing, headphones, wireless")
            page: "qrc:/qml/Bluetooth/Main.qml"
            // source: "bluetooth.svg"
            iconSource: "bluetooth.svg"
            iconColor: "#1E6FF0"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Proxy")
            name: "proxy"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("network, HTTP, SOCKS, internet")
            page: "qrc:/qml/Proxy/Main.qml"
            // source: "proxy.svg"
            iconSource: "proxy.svg"
            iconColor: "#8E8E93"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Display")
            name: "display"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("screen, monitor, resolution, brightness, scale, night light, refresh rate")
            page: "qrc:/qml/Display/Main.qml"
            // source: "display.svg"
            iconSource: "display.svg"
            iconColor: "#30B0C7"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Appearance")
            name: "appearance"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("theme, dark mode, light mode, accent color, fonts")
            page: "qrc:/qml/Appearance/Main.qml"
            // source: "appearance.svg"
            iconSource: "appearance.svg"
            iconColor: "#5E5CE6"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Effects")
            name: "effects"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("animations, blur, transparency, windows")
            page: "qrc:/qml/Effects/Main.qml"
            iconSource: "effects.svg"
            iconColor: "#BF5AF2"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Background")
            name: "background"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("wallpaper, desktop, picture")
            page: "qrc:/qml/Wallpaper/Main.qml"
            // source: "wallpaper.svg"
            iconSource: "wallpaper.svg"
            iconColor: "#64B5F6"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Dock")
            name: "dock"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("taskbar, panel, launcher")
            page: "qrc:/qml/Dock/Main.qml"
            // source: "dock.svg"
            iconSource: "dock.svg"
            iconColor: "#48484A"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("User")
            name: "accounts"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("account, password, avatar, login, fingerprint, face")
            page: "qrc:/qml/User/Main.qml"
            // source: "accounts.svg"
            iconSource: "accounts.svg"
            iconColor: "#FF9500"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Notifications")
            name: "notifications"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("alerts, do not disturb, messages")
            page: "qrc:/qml/Notification/Main.qml"
            // source: "notifications.svg"
            iconSource: "notifications.svg"
            iconColor: "#FF3B30"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Sound")
            name: "sound"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("audio, volume, speakers, headphones, microphone")
            page: "qrc:/qml/Sound/Main.qml"
            // source: "sound.svg"
            iconSource: "sound.svg"
            iconColor: "#FF2D55"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Camera")
            name: "camera"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("webcam, video")
            page: "qrc:/qml/Camera/Main.qml"
            iconSource: "camera.svg"
            iconColor: "#30B0C7"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Mouse")
            name: "mouse"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("cursor, pointer, scrolling, speed")
            page: "qrc:/qml/Cursor/Main.qml"
            // source: "cursor.svg"
            iconSource: "cursor.svg"
            iconColor: "#8E8E93"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Touchpad")
            name: "touchpad"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("trackpad, tap to click, scrolling, gestures")
            page: "qrc:/qml/Touchpad/Main.qml"
            // source: "touchpad.svg"
            iconSource: "touchpad.svg"
            iconColor: "#8E8E93"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Date & Time")
            name: "datetime"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("clock, time zone, calendar")
            page: "qrc:/qml/DateTime/Main.qml"
            // source: "datetime.svg"
            iconSource: "datetime.svg"
            iconColor: "#FF9F0A"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Accessibility")
            name: "accessibility"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("zoom, contrast, magnifier, reduce motion")
            page: "qrc:/qml/Accessibility/Main.qml"
            //source: "accessibility.svg"
            iconSource: "accessibility.svg"
            iconColor: "#007AFF"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Keyboard")
            name: "keyboard"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("layout, input, typing, key repeat")
            page: "qrc:/qml/Keyboard/Main.qml"
            iconSource: "keyboard-layout.svg"
            iconColor: "#34AADC"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Shortcuts")
            name: "shortcuts"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("keyboard shortcuts, hotkeys, keys")
            page: "qrc:/qml/Shortcuts/Main.qml"
            iconSource: "keyboard.svg"
            iconColor: "#5856D6"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Startup")
            name: "startup"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("autostart, login, apps")
            page: "qrc:/qml/Autostart/Main.qml"
            iconSource: "startup.svg"
            iconColor: "#FF9F0A"
            category: qsTr("System")
        }
        
        ListElement {
            title: qsTr("Default Applications")
            name: "defaultapps"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("browser, email, file manager, terminal, apps")
            page: "qrc:/qml/DefaultApp/Main.qml"
            //source: "defaultapps.svg"
            iconSource: "defaultapps.svg"
            iconColor: "#AF52DE"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Boxes")
            name: "boxes"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("sandbox, isolation, Windows, Android, AppImage, permissions")
            page: "qrc:/qml/Boxes/Main.qml"
            iconSource: "boxes.svg"
            iconColor: "#30B0C7"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Artificial Intelligence")
            name: "ai"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("AI, assistant, model, LLM, chat")
            page: "qrc:/qml/AI/Main.qml"
            iconSource: "ai.svg"
            iconColor: "#6E56CF"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Language")
            name: "language"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("region, locale, translation")
            page: "qrc:/qml/LanguagePage.qml"
            // source: "language.svg"
            iconSource: "language.svg"
            iconColor: "#0FB5AE"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Battery")
            name: "battery"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("power, charge, energy")
            page: "qrc:/qml/Battery/Main.qml"
            // source: "battery.svg"
            iconColor: "#34C759"
            iconSource: "battery.svg"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Power")
            name: "power"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("energy, sleep, suspend, screen off")
            page: "qrc:/qml/Power/Main.qml"
            iconColor: "#30D158"
            iconSource: "power.svg"
            category: qsTr("System")
        }

        // ListElement {
        //     title: qsTr("System Update")
        //     name: "systemupdate"
        //     page: "qrc:/qml/SystemUpdate/Main.qml"
        //     iconColor: "#2277FF"
        //     iconSource: "update.svg"
        //     category: qsTr("System & Update")
        // }

        ListElement {
            title: qsTr("About")
            name: "about"
            // Extra words the search field matches (comma separated)
            keywords: qsTr("system, version, computer name, hardware")
            page: "qrc:/qml/About/Main.qml"
            iconSource: "info.svg"
            iconColor: "#8E8E93"
            category: qsTr("System & Update")
        }

    }

    function removeItem(name) {
        for (var i = 0; i < listModel.count; ++i) {
            if (name === listModel.get(i).name) {
                listModel.remove(i)
                break
            }
        }
    }

    Battery {
        id: _battery

        Component.onCompleted: {
            if (!_battery.available)
                removeItem("battery")
        }
    }

    NM.EnabledConnections {
        id: nmEnabledConnections

        Component.onCompleted: {
            if (!nmEnabledConnections.wirelessHwEnabled)
                removeItem("wlan")
        }
    }

    Touchpad {
        id: _touchPad

        Component.onCompleted: {
            if (!_touchPad.available)
                removeItem("touchpad")
        }
    }
}
