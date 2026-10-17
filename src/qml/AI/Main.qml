/*
 * Copyright (C) 2026 LingmoOS Team.
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import LingmoUI.CompatibleModule 3.0 as LingmoUI

import Lingmo.Settings 1.0
import "../"

// The system AI: which local model Spotlight and Automator use (~/.config/lingmoos/ai.conf),
// the Ollama server that runs it and the models llmfit says fit this computer.
ItemPage {
    id: page
    headerTitle: qsTr("Artificial Intelligence")

    // Which card shows the result of the last action
    property string messageArea: ""
    // Which part of the page started the download in progress
    property string pullArea: "download"
    property bool showAllRecommendations: false
    readonly property bool running: AIModule.ollamaState === AIModule.Running
    readonly property int collapsedCount: 6
    property string folderError: ""
    property bool showBlockedAreas: false
    property bool showAllWhisper: false

    // subtitle_language values (ISO 639-1, as whisper takes them)
    readonly property var subtitleLanguages: [
        { value: "auto", text: qsTr("Detect automatically") },
        { value: "pt", text: qsTr("Portuguese") },
        { value: "en", text: qsTr("English") },
        { value: "es", text: qsTr("Spanish") },
        { value: "fr", text: qsTr("French") },
        { value: "de", text: qsTr("German") },
        { value: "it", text: qsTr("Italian") },
        { value: "nl", text: qsTr("Dutch") },
        { value: "pl", text: qsTr("Polish") },
        { value: "ru", text: qsTr("Russian") },
        { value: "uk", text: qsTr("Ukrainian") },
        { value: "tr", text: qsTr("Turkish") },
        { value: "ar", text: qsTr("Arabic") },
        { value: "hi", text: qsTr("Hindi") },
        { value: "ja", text: qsTr("Japanese") },
        { value: "ko", text: qsTr("Korean") },
        { value: "zh", text: qsTr("Chinese") }
    ]

    // docs/assistant-contract.md: tool ids, groups and what each one does
    readonly property var readTools: [
        { id: "system_info", name: qsTr("System information"), text: qsTr("Hardware and system: processor, memory, disks, battery and uptime.") },
        { id: "shell_read", name: qsTr("Terminal read commands"), text: qsTr("A fixed list of commands that only read, run in a sandbox without network.") },
        { id: "read_files", name: qsTr("Read files"), text: qsTr("Opens text, Markdown, PDF, DOCX and ODT files in the folders below.") },
        { id: "search_files", name: qsTr("Search files"), text: qsTr("Finds files by name and content in the folders below.") },
        { id: "notes_read", name: qsTr("Read notes"), text: qsTr("Lists, searches and reads pages in Lingmo Notes.") },
        { id: "calendar_read", name: qsTr("Read calendar"), text: qsTr("Reads events and tasks from the Lingmo Mail calendar.") },
        { id: "web", name: qsTr("Internet (search and pages)"), text: qsTr("Searches the web and reads pages."),
          warning: qsTr("What it searches for leaves this computer.") }
    ]
    readonly property var writeTools: [
        { id: "notes_write", name: qsTr("Write notes"), text: qsTr("Creates pages in Lingmo Notes or adds text to a page.") },
        { id: "calendar_write", name: qsTr("Add to calendar"), text: qsTr("Creates events, reminders and tasks in the Lingmo Mail calendar.") },
        { id: "files_write", name: qsTr("Write files"), text: qsTr("Creates files or adds text to files in the folders below. Overwriting shows what changes first.") }
    ]

    function fitColor(level) {
        if (level === "Perfect" || level === "Good")
            return LingmoUI.Theme.greenColor
        if (level === "Marginal")
            return LingmoUI.Theme.orangeColor
        if (level === "Too Tight")
            return LingmoUI.Theme.redColor
        return LingmoUI.Theme.secondaryTextColor
    }

    function tagColor(id) {
        switch (id) {
        case "tools": return LingmoUI.Theme.blueColor
        case "thinking": return LingmoUI.Theme.purpleColor
        case "highlights": return LingmoUI.Theme.orangeColor
        case "fast": return LingmoUI.Theme.greenColor
        case "accurate": return LingmoUI.Theme.pinkColor
        }
        return LingmoUI.Theme.highlightColor
    }

    function joinParts(parts) {
        return parts.filter(function(p) { return p !== undefined && p !== "" }).join(" · ")
    }

    function download(name, area) {
        page.messageArea = area || "download"
        page.pullArea = page.messageArea
        AIModule.pull(name)
    }

    Component.onCompleted: {
        AIModule.clearMessages()
        AIModule.refresh()
        AIModule.loadRecommendations()
        sectionTimer.start()
    }

    // Notice when Ollama gets installed or started outside this page
    Timer {
        interval: 4000
        repeat: true
        running: !page.running
        onTriggered: AIModule.refresh()
    }

    // Capability chips of a model ({ id, text } from AIModule)
    component TagRow: Flow {
        id: tagRow
        property var tags: []

        spacing: LingmoUI.Units.smallSpacing / 2
        visible: tags.length > 0
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.bottomMargin: 2

        Repeater {
            model: tagRow.tags

            LingmoUI.Badge {
                text: modelData.text
                tone: page.tagColor(modelData.id)
            }
        }
    }

    // Progress and result of a download, shown next to where it was started
    component PullStatus: ColumnLayout {
        property string area

        spacing: LingmoUI.Units.smallSpacing
        visible: (AIModule.pulling && page.pullArea === area)
                 || (!AIModule.pulling && page.messageArea === area && (AIModule.errorText !== "" || AIModule.infoText !== ""))
        Layout.fillWidth: true

        RowLayout {
            visible: AIModule.pulling
            spacing: LingmoUI.Units.largeSpacing
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                Label {
                    text: qsTr("Downloading %1").arg(AIModule.pullModel)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Label {
                    text: AIModule.pullDetail
                    color: LingmoUI.Theme.secondaryTextColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Button {
                text: qsTr("Cancel")
                onClicked: AIModule.cancelPull()
            }
        }

        ProgressBar {
            visible: AIModule.pulling
            Layout.fillWidth: true
            from: 0
            to: 1
            indeterminate: AIModule.pullProgress < 0
            value: Math.max(0, AIModule.pullProgress)
        }

        Label {
            visible: !AIModule.pulling && (AIModule.errorText !== "" || AIModule.infoText !== "")
            text: AIModule.errorText !== "" ? AIModule.errorText : AIModule.infoText
            color: AIModule.errorText !== "" ? LingmoUI.Theme.redColor : LingmoUI.Theme.secondaryTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    // "lingmo-settings -m ai/transcription" opens the page at the subtitles section
    Timer {
        id: sectionTimer
        interval: 150
        onTriggered: {
            // Pages can be pushed twice in a row on start; only the shown one takes the section
            if (typeof rootWindow === "undefined" || rootWindow.pageSection !== "transcription"
                    || page.StackView.status !== StackView.Active)
                return
            rootWindow.pageSection = ""
            scroller.contentY = Math.max(-scroller.topMargin,
                                         Math.min(transcriptionCard.y - LingmoUI.Units.largeSpacing,
                                                  scroller.contentHeight - scroller.height + scroller.bottomMargin))
        }
    }

    Scrollable {
        id: scroller
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: LingmoUI.Units.largeSpacing * 2

            // ---------------------------------------------------------- Ollama
            RoundedItem {
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing

                    Label {
                        text: qsTr("Ollama")
                        font.pointSize: LingmoUI.Units.fontSubheading
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    LingmoUI.Spinner {
                        id: ollamaBusy
                        size: 22
                        visible: AIModule.ollamaState === AIModule.Checking
                                 || AIModule.ollamaState === AIModule.Starting
                                 || (AIModule.busy && page.messageArea === "ollama")
                        running: ollamaBusy.visible
                    }
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing
                    Layout.fillWidth: true

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: (statusTitle.implicitHeight - height) / 2
                        color: {
                            switch (AIModule.ollamaState) {
                            case AIModule.Running: return LingmoUI.Theme.greenColor
                            case AIModule.Starting: return LingmoUI.Theme.orangeColor
                            case AIModule.Stopped: return LingmoUI.Theme.orangeColor
                            case AIModule.NotInstalled: return LingmoUI.Theme.redColor
                            }
                            return LingmoUI.Theme.secondaryTextColor
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: LingmoUI.Units.shortDuration
                                easing.type: Easing.Linear
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            id: statusTitle
                            text: {
                                switch (AIModule.ollamaState) {
                                case AIModule.Running: return qsTr("Running")
                                case AIModule.Starting: return qsTr("Starting…")
                                case AIModule.Stopped: return AIModule.remoteServer || AIModule.serviceActive
                                                              ? qsTr("Not reachable")
                                                              : qsTr("Installed, but not running")
                                case AIModule.NotInstalled: return qsTr("Not installed")
                                }
                                return qsTr("Checking…")
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: LingmoUI.Theme.secondaryTextColor
                            visible: text !== ""
                            text: {
                                switch (AIModule.ollamaState) {
                                case AIModule.Running:
                                    return AIModule.remoteServer
                                            ? qsTr("Version %1 on %2").arg(AIModule.ollamaVersion).arg(AIModule.serverAddress)
                                            : qsTr("Version %1").arg(AIModule.ollamaVersion)
                                case AIModule.Starting:
                                    return qsTr("Waiting for Ollama to answer.")
                                case AIModule.Stopped:
                                    return AIModule.remoteServer || AIModule.serviceActive
                                            ? qsTr("Could not reach the Ollama server at %1.").arg(AIModule.serverAddress)
                                            : qsTr("Ollama runs the AI models. Start it to use and download models.")
                                case AIModule.NotInstalled:
                                    return qsTr("Ollama runs the AI models on this computer. Install it in a terminal with “sudo pacman -S ollama” (or ollama-cuda for NVIDIA and ollama-rocm for AMD graphics) and come back to this page.")
                                }
                                return ""
                            }
                        }
                    }

                    Button {
                        text: qsTr("Start")
                        flat: true
                        visible: AIModule.canStartOllama
                        enabled: !AIModule.busy
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        onClicked: {
                            page.messageArea = "ollama"
                            AIModule.startOllama()
                        }
                    }
                }

                Label {
                    visible: page.messageArea === "ollama" && AIModule.errorText !== ""
                    text: AIModule.errorText
                    color: LingmoUI.Theme.redColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // ---------------------------------------------------------- Model in use
            RoundedItem {
                Label {
                    text: qsTr("Model in use")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("The default model for the whole system. Spotlight and Automator answer with it.")
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: page.running && AIModule.model !== "" && !AIModule.modelInstalled
                    color: LingmoUI.Theme.orangeColor
                    text: qsTr("“%1” is chosen but not installed. Download it below or choose another model.").arg(AIModule.model)
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: LingmoUI.Theme.secondaryTextColor
                    visible: text !== ""
                    text: {
                        if (!page.running)
                            return AIModule.model !== "" ? qsTr("Chosen: %1. Start Ollama to see the installed models.").arg(AIModule.model)
                                                         : qsTr("Start Ollama to see the installed models.")
                        if (AIModule.installedModels.length === 0)
                            return qsTr("No models installed yet. Download one below.")
                        if (AIModule.model === "")
                            return qsTr("No model chosen yet. Pick one of the installed models.")
                        return ""
                    }
                }

                ColumnLayout {
                    spacing: LingmoUI.Units.smallSpacing
                    Layout.fillWidth: true
                    visible: page.running && AIModule.installedModels.length > 0

                    Repeater {
                        model: page.running ? AIModule.installedModels : []

                        RowLayout {
                            spacing: LingmoUI.Units.largeSpacing
                            Layout.fillWidth: true

                            RadioButton {
                                checked: modelData.inUse
                                enabled: !modelData.embedding
                                Layout.alignment: Qt.AlignVCenter
                                onClicked: AIModule.setDefaultModel(modelData.name)
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                TapHandler {
                                    enabled: !modelData.embedding
                                    onTapped: AIModule.setDefaultModel(modelData.name)
                                }

                                Label {
                                    text: modelData.name
                                    elide: Text.ElideRight
                                    color: modelData.embedding ? LingmoUI.Theme.secondaryTextColor : LingmoUI.Theme.textColor
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: modelData.embedding
                                          ? page.joinParts([modelData.details, qsTr("Embeddings for search, not for chat")])
                                          : modelData.details
                                    color: LingmoUI.Theme.secondaryTextColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                TagRow {
                                    tags: modelData.tags
                                }

                                Label {
                                    visible: modelData.fitLevel !== ""
                                    text: modelData.fitLevel === "Too Tight"
                                          ? qsTr("Too heavy for this computer: answers will be slow.")
                                          : page.joinParts([modelData.fitText, modelData.runMode, modelData.speed])
                                    color: modelData.fitLevel === "Too Tight" ? LingmoUI.Theme.orangeColor
                                                                              : LingmoUI.Theme.secondaryTextColor
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            Label {
                                visible: modelData.inUse
                                text: qsTr("In use")
                                color: LingmoUI.Theme.highlightColor
                            }

                            Button {
                                text: qsTr("Remove")
                                enabled: !AIModule.busy && AIModule.pullModel !== modelData.name
                                onClicked: {
                                    removeDialog.modelName = modelData.name
                                    removeDialog.inUse = modelData.inUse
                                    removeDialog.open()
                                }
                            }
                        }
                    }
                }

                // Reasoning ("think"): reasoning models think before answering
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true
                    Layout.topMargin: LingmoUI.Units.smallSpacing

                    ColumnLayout {
                        spacing: LingmoUI.Units.smallSpacing
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Think before answering")
                        }

                        Label {
                            text: qsTr("Reasoning models work the problem out first: better answers to hard questions, but slower. Off, they answer right away.")
                            color: LingmoUI.Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: page.running && AIModule.model !== "" && AIModule.modelInstalled && !AIModule.modelCanThink
                            text: qsTr("“%1” can't reason, so it always answers right away. Models marked “Thinking” can.").arg(AIModule.model)
                            color: LingmoUI.Theme.orangeColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: AIModule.think
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        rightPadding: 0
                        onToggled: AIModule.think = checked
                    }
                }

                Label {
                    visible: page.messageArea === "installed" && (AIModule.errorText !== "" || AIModule.infoText !== "")
                    text: AIModule.errorText !== "" ? AIModule.errorText : AIModule.infoText
                    color: AIModule.errorText !== "" ? LingmoUI.Theme.redColor : LingmoUI.Theme.secondaryTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // ---------------------------------------------------------- Assistant
            RoundedItem {
                Label {
                    text: qsTr("Assistant")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("A helper for everyday things: it reads your documents, summarizes them, takes notes and schedules tasks, with the model in use. It only does what you allow below.")
                    }

                    Button {
                        text: qsTr("Open the Assistant")
                        flat: true
                        visible: AIModule.assistantInstalled
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        onClicked: {
                            page.messageArea = "assistant"
                            AIModule.openAssistant()
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: page.running && AIModule.model !== "" && AIModule.modelInstalled && !AIModule.modelCanUseTools
                    color: LingmoUI.Theme.orangeColor
                    text: qsTr("“%1” doesn't use tools: the assistant only chats. Models marked “Tools” can.").arg(AIModule.model)
                }

                Label {
                    visible: page.messageArea === "assistant" && AIModule.errorText !== ""
                    text: AIModule.errorText
                    color: LingmoUI.Theme.redColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                HorizontalDivider {}

                // Permissions
                Label {
                    text: qsTr("Permissions")
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Read")
                        }

                        Label {
                            text: qsTr("Look at files, notes, the calendar and the system.")
                            color: LingmoUI.Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: AIModule.assistantRead
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        rightPadding: 0
                        onToggled: AIModule.assistantRead = checked
                    }
                }

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Write")
                        }

                        Label {
                            text: qsTr("Create notes, events and files. Every write asks for your confirmation first.")
                            color: LingmoUI.Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: AIModule.assistantWrite
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        rightPadding: 0
                        onToggled: AIModule.assistantWrite = checked
                    }
                }

                // Shown so the rule is visible: there is no way to turn it on
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Delete — never allowed")
                            color: LingmoUI.Theme.secondaryTextColor
                        }

                        Label {
                            text: qsTr("The assistant never deletes files, notes, events or tasks.")
                            color: LingmoUI.Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: false
                        enabled: false
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        rightPadding: 0
                    }
                }

                HorizontalDivider {}

                // Tools, grouped by the permission they need
                Label {
                    text: qsTr("Tools")
                }

                Repeater {
                    model: [
                        { title: qsTr("Read"), tools: page.readTools, write: false },
                        { title: qsTr("Write"), tools: page.writeTools, write: true }
                    ]

                    ColumnLayout {
                        id: toolGroup
                        readonly property bool allowed: modelData.write ? AIModule.assistantWrite : AIModule.assistantRead

                        spacing: LingmoUI.Units.smallSpacing
                        Layout.fillWidth: true

                        Label {
                            text: modelData.title
                            color: LingmoUI.Theme.secondaryTextColor
                        }

                        Label {
                            visible: !toolGroup.allowed
                            text: modelData.write ? qsTr("Turn on Write above to use these tools.")
                                                  : qsTr("Turn on Read above to use these tools.")
                            color: LingmoUI.Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: modelData.tools

                            RowLayout {
                                spacing: LingmoUI.Units.smallSpacing
                                Layout.fillWidth: true

                                CheckBox {
                                    id: toolCheck
                                    checked: AIModule.assistantTools.indexOf(modelData.id) >= 0
                                    enabled: toolGroup.allowed
                                    Layout.alignment: Qt.AlignTop
                                    onToggled: AIModule.setAssistantTool(modelData.id, checked)
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    TapHandler {
                                        enabled: toolGroup.allowed
                                        onTapped: AIModule.setAssistantTool(modelData.id, !toolCheck.checked)
                                    }

                                    Label {
                                        text: modelData.name
                                        color: toolGroup.allowed ? LingmoUI.Theme.textColor : LingmoUI.Theme.secondaryTextColor
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: modelData.text
                                        color: LingmoUI.Theme.secondaryTextColor
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        visible: modelData.warning !== undefined
                                        text: modelData.warning || ""
                                        color: toolGroup.allowed ? LingmoUI.Theme.orangeColor : LingmoUI.Theme.secondaryTextColor
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }

                HorizontalDivider {}

                // Folders the file tools may read and write
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Folders the assistant can read and write")
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("File tools only work inside these folders.")
                            color: LingmoUI.Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        text: qsTr("Add folder…")
                        flat: true
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        onClicked: {
                            page.folderError = ""
                            folderDialog.open()
                        }
                    }
                }

                Label {
                    visible: AIModule.assistantFolders.length === 0
                    text: qsTr("No folders: the assistant can't open your files.")
                    color: LingmoUI.Theme.secondaryTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                ColumnLayout {
                    spacing: LingmoUI.Units.smallSpacing
                    Layout.fillWidth: true
                    visible: AIModule.assistantFolders.length > 0

                    Repeater {
                        model: AIModule.assistantFolders

                        RowLayout {
                            spacing: LingmoUI.Units.largeSpacing
                            Layout.fillWidth: true

                            LingmoUI.IconItem {
                                source: "folder"
                                width: LingmoUI.Units.iconSizes.smallMedium
                                height: width
                                Layout.preferredWidth: width
                                Layout.preferredHeight: height
                            }

                            Label {
                                text: AIModule.displayPath(modelData)
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }

                            Button {
                                text: qsTr("Remove")
                                onClicked: {
                                    page.folderError = ""
                                    AIModule.removeAssistantFolder(modelData)
                                }
                            }
                        }
                    }
                }

                Label {
                    visible: page.folderError !== ""
                    text: page.folderError
                    color: LingmoUI.Theme.redColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    text: page.showBlockedAreas ? qsTr("Hide the always-blocked areas")
                                                : qsTr("Some areas are always blocked, even inside these folders…")
                    color: LingmoUI.Theme.linkColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true

                    TapHandler {
                        onTapped: page.showBlockedAreas = !page.showBlockedAreas
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Label {
                    visible: page.showBlockedAreas
                    text: qsTr("Passwords, keys and browser data are never read or written: %1.")
                              .arg(AIModule.assistantBlockedAreas.join(", "))
                    color: LingmoUI.Theme.secondaryTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // ---------------------------------------------------------- Download
            RoundedItem {
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing

                    Label {
                        text: qsTr("Recommended for this computer")
                        color: LingmoUI.Theme.secondaryTextColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    LingmoUI.Spinner {
                        id: llmfitBusy
                        size: 22
                        visible: AIModule.llmfitBusy
                        running: llmfitBusy.visible
                    }

                    Button {
                        text: qsTr("Refresh")
                        visible: AIModule.llmfitAvailable
                        enabled: !AIModule.llmfitBusy
                        onClicked: AIModule.refreshRecommendations()
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: AIModule.systemSummary !== ""
                    color: LingmoUI.Theme.secondaryTextColor
                    text: qsTr("This computer: %1").arg(AIModule.systemSummary)
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: !AIModule.llmfitAvailable
                    color: LingmoUI.Theme.secondaryTextColor
                    text: qsTr("Install llmfit to see which models suit this computer: sudo pacman -S llmfit")
                }

                LingmoUI.SegmentedControl {
                    fillWidth: true
                    model: [qsTr("Conversation"), qsTr("General use"), qsTr("Programming"), qsTr("Reasoning")]
                    Layout.fillWidth: true
                    visible: AIModule.llmfitAvailable
                    // Follows the setting (also after a click, like TabBar did)
                    Binding on currentIndex { value: ["chat", "general", "coding", "reasoning"].indexOf(AIModule.useCase) }
                    onActivated: (index) => {
                        if (index === 0) { page.showAllRecommendations = false; AIModule.useCase = "chat" }
                        else if (index === 1) { page.showAllRecommendations = false; AIModule.useCase = "general" }
                        else if (index === 2) { page.showAllRecommendations = false; AIModule.useCase = "coding" }
                        else if (index === 3) { page.showAllRecommendations = false; AIModule.useCase = "reasoning" }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: AIModule.llmfitAvailable && AIModule.recommendations.length === 0 && text !== ""
                    color: AIModule.llmfitError !== "" ? LingmoUI.Theme.redColor : LingmoUI.Theme.secondaryTextColor
                    text: AIModule.llmfitError !== "" ? AIModule.llmfitError
                        : AIModule.llmfitBusy ? qsTr("Checking which models suit this computer…")
                        : qsTr("llmfit found no Ollama model of this kind that fits this computer.")
                }

                PullStatus {
                    area: "download"
                }

                ColumnLayout {
                    spacing: LingmoUI.Units.largeSpacing
                    Layout.fillWidth: true
                    visible: AIModule.llmfitAvailable && AIModule.recommendations.length > 0

                    Repeater {
                        model: page.showAllRecommendations ? AIModule.recommendations
                                                           : AIModule.recommendations.slice(0, page.collapsedCount)

                        RowLayout {
                            spacing: LingmoUI.Units.largeSpacing
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                RowLayout {
                                    spacing: LingmoUI.Units.smallSpacing
                                    Layout.fillWidth: true

                                    // Always the full name: the tag ("qwen2.5:3b" vs ":7b") is what tells models apart
                                    Label {
                                        text: modelData.name
                                    }

                                    Label {
                                        id: fitLabel
                                        text: modelData.fitText
                                        color: page.fitColor(modelData.fitLevel)
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }
                                }

                                TagRow {
                                    tags: modelData.tags
                                }

                                Label {
                                    text: page.joinParts([modelData.parameters,
                                                          modelData.download !== "" ? qsTr("%1 download").arg(modelData.download) : "",
                                                          modelData.memory !== "" ? qsTr("needs %1 of memory").arg(modelData.memory) : ""])
                                    color: LingmoUI.Theme.secondaryTextColor
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: page.joinParts([modelData.runMode, modelData.speed])
                                    color: LingmoUI.Theme.secondaryTextColor
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            Label {
                                visible: modelData.installed
                                text: modelData.inUse ? qsTr("In use") : qsTr("Installed")
                                color: modelData.inUse ? LingmoUI.Theme.highlightColor : LingmoUI.Theme.secondaryTextColor
                            }

                            Button {
                                visible: !modelData.installed
                                text: qsTr("Download")
                                flat: true
                                enabled: page.running && !AIModule.pulling
                                onClicked: page.download(modelData.name)
                            }
                        }
                    }

                    Button {
                        visible: AIModule.recommendations.length > page.collapsedCount
                        text: page.showAllRecommendations ? qsTr("Show fewer")
                                                          : qsTr("Show all %1").arg(AIModule.recommendations.length)
                        Layout.fillWidth: true
                        onClicked: page.showAllRecommendations = !page.showAllRecommendations
                    }
                }

                HorizontalDivider {}

                ColumnLayout {
                    spacing: LingmoUI.Units.smallSpacing
                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Other model")
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: LingmoUI.Theme.secondaryTextColor
                        text: qsTr("Any model from ollama.com/library, for example gemma3:4b or user/model:tag.")
                    }

                    RowLayout {
                        spacing: LingmoUI.Units.largeSpacing
                        Layout.fillWidth: true

                        TextField {
                            id: otherField
                            placeholderText: qsTr("name:tag")
                            Layout.fillWidth: true
                            onAccepted: if (otherButton.enabled) otherButton.clicked()
                        }

                        Button {
                            id: otherButton
                            text: qsTr("Download")
                            flat: true
                            enabled: page.running && !AIModule.pulling && AIModule.isValidModelName(otherField.text.trim())
                            onClicked: {
                                page.download(otherField.text.trim(), "other")
                                otherField.text = ""
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        visible: otherField.text.trim() !== "" && !AIModule.isValidModelName(otherField.text.trim())
                        color: LingmoUI.Theme.redColor
                        text: qsTr("Use lowercase letters, numbers, dots and dashes, like llama3.2:3b.")
                    }

                    PullStatus {
                        area: "other"
                    }
                }
            }

            // ---------------------------------------------------------- Transcription and subtitles
            // whisper.cpp models for Lingmo Studio's subtitles (ai.conf: subtitle_backend,
            // subtitle_model, subtitle_language; files in AIModule.whisperModelsDir)
            RoundedItem {
                id: transcriptionCard

                Label {
                    text: qsTr("Transcription and subtitles")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Lingmo Studio turns what is said in your videos into subtitles with Whisper, on this computer. Larger models get more words right but take longer.")
                }

                LingmoUI.Banner {
                    Layout.fillWidth: true
                    visible: !AIModule.whisperCppInstalled && !AIModule.fasterWhisperInstalled
                    type: 2
                    closable: false
                    title: qsTr("No transcription program installed")
                    text: qsTr("Install whisper.cpp in a terminal with “sudo pacman -S whisper-cpp” and come back to this page. faster-whisper is optional: “pipx install whisper-ctranslate2” or the AUR package whisper-ctranslate2.")
                }

                // Engine
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Engine")
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: LingmoUI.Theme.secondaryTextColor
                            text: page.joinParts([
                                AIModule.whisperCppInstalled ? qsTr("whisper.cpp installed") : qsTr("whisper.cpp not installed"),
                                AIModule.fasterWhisperInstalled ? qsTr("faster-whisper installed") : qsTr("faster-whisper not installed")
                            ])
                        }
                    }

                    LingmoUI.SegmentedControl {
                        model: [qsTr("Automatic"), "whisper.cpp", "faster-whisper"]
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        Binding on currentIndex { value: Math.max(0, ["", "whisper.cpp", "faster-whisper"].indexOf(AIModule.subtitleBackend)) }
                        onActivated: (index) => AIModule.subtitleBackend = ["", "whisper.cpp", "faster-whisper"][index]
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: text !== ""
                    color: LingmoUI.Theme.orangeColor
                    text: AIModule.subtitleBackend === "whisper.cpp" && !AIModule.whisperCppInstalled
                          ? qsTr("whisper.cpp is chosen but not installed: sudo pacman -S whisper-cpp")
                          : AIModule.subtitleBackend === "faster-whisper" && !AIModule.fasterWhisperInstalled
                          ? qsTr("faster-whisper is chosen but not installed: pipx install whisper-ctranslate2")
                          : ""
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: AIModule.subtitleBackend === "faster-whisper"
                    color: LingmoUI.Theme.secondaryTextColor
                    text: qsTr("faster-whisper uses the size chosen below and downloads its own copy of the model the first time.")
                }

                // Spoken language
                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing * 2
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Spoken language")
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: LingmoUI.Theme.secondaryTextColor
                            text: qsTr("Choosing it avoids mistakes in the first seconds; automatic detects it from the audio.")
                        }
                    }

                    ComboBox {
                        id: languageBox
                        textRole: "text"
                        valueRole: "value"
                        model: page.subtitleLanguages
                        Layout.preferredWidth: 220
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        currentIndex: Math.max(0, page.subtitleLanguages.findIndex(l => l.value === AIModule.subtitleLanguage))
                        onActivated: (index) => AIModule.subtitleLanguage = page.subtitleLanguages[index].value
                    }
                }

                HorizontalDivider {}

                RowLayout {
                    spacing: LingmoUI.Units.largeSpacing
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Whisper models")
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: LingmoUI.Theme.secondaryTextColor
                            text: AIModule.subtitleModel !== ""
                                  ? qsTr("Subtitles use %1. Models are saved in %2.").arg(AIModule.subtitleModel).arg(AIModule.displayPath(AIModule.whisperModelsDir))
                                  : qsTr("No model chosen yet. Download one; the first one is used for subtitles.")
                        }
                    }
                }

                // Download progress and the result of the last action
                ColumnLayout {
                    spacing: LingmoUI.Units.smallSpacing
                    Layout.fillWidth: true
                    visible: AIModule.whisperDownloading
                             || (page.messageArea === "whisper" && (AIModule.errorText !== "" || AIModule.infoText !== ""))

                    RowLayout {
                        visible: AIModule.whisperDownloading
                        spacing: LingmoUI.Units.largeSpacing
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            Label {
                                text: qsTr("Downloading %1").arg(AIModule.whisperDownloadModel)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Label {
                                text: AIModule.whisperDownloadDetail
                                color: LingmoUI.Theme.secondaryTextColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Button {
                            text: qsTr("Cancel")
                            onClicked: AIModule.cancelWhisperDownload()
                        }
                    }

                    ProgressBar {
                        visible: AIModule.whisperDownloading
                        Layout.fillWidth: true
                        from: 0
                        to: 1
                        indeterminate: AIModule.whisperDownloadProgress < 0
                        value: Math.max(0, AIModule.whisperDownloadProgress)
                    }

                    Label {
                        visible: !AIModule.whisperDownloading && page.messageArea === "whisper"
                                 && (AIModule.errorText !== "" || AIModule.infoText !== "")
                        text: AIModule.errorText !== "" ? AIModule.errorText : AIModule.infoText
                        color: AIModule.errorText !== "" ? LingmoUI.Theme.redColor : LingmoUI.Theme.secondaryTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    spacing: LingmoUI.Units.largeSpacing
                    Layout.fillWidth: true

                    Repeater {
                        // Compressed (quantised) versions only on request, unless recommended or installed
                        model: AIModule.whisperModels.filter(m => page.showAllWhisper || !m.quantized || m.recommended || m.installed)

                        RowLayout {
                            spacing: LingmoUI.Units.largeSpacing
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Label {
                                    text: modelData.name
                                }

                                Flow {
                                    spacing: LingmoUI.Units.smallSpacing / 2
                                    Layout.fillWidth: true
                                    Layout.topMargin: 2
                                    Layout.bottomMargin: 2

                                    LingmoUI.Badge {
                                        visible: modelData.recommended
                                        text: qsTr("Recommended for your computer")
                                        tone: LingmoUI.Theme.greenColor
                                    }

                                    Repeater {
                                        model: modelData.tags

                                        LingmoUI.Badge {
                                            text: modelData.text
                                            tone: page.tagColor(modelData.id)
                                        }
                                    }

                                    LingmoUI.Badge {
                                        visible: modelData.quantized
                                        text: qsTr("Compressed")
                                        subtle: true
                                    }
                                }

                                Label {
                                    text: page.joinParts([qsTr("%1 download").arg(modelData.download),
                                                          qsTr("≈ %1 of memory").arg(modelData.memory)])
                                    color: LingmoUI.Theme.secondaryTextColor
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: page.joinParts([qsTr("Speed: %1").arg(modelData.speedText),
                                                          qsTr("Portuguese: %1").arg(modelData.qualityText)])
                                    color: LingmoUI.Theme.secondaryTextColor
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            Label {
                                visible: modelData.inUse
                                text: qsTr("In use")
                                color: LingmoUI.Theme.highlightColor
                            }

                            Button {
                                visible: modelData.installed && !modelData.inUse
                                text: qsTr("Use for subtitles")
                                flat: true
                                onClicked: {
                                    page.messageArea = "whisper"
                                    AIModule.useWhisperModel(modelData.name)
                                }
                            }

                            Button {
                                visible: modelData.installed
                                text: qsTr("Remove")
                                enabled: AIModule.whisperDownloadModel !== modelData.name
                                onClicked: {
                                    removeDialog.whisper = true
                                    removeDialog.modelName = modelData.name
                                    removeDialog.inUse = modelData.inUse
                                    removeDialog.open()
                                }
                            }

                            Button {
                                visible: !modelData.installed
                                text: qsTr("Download")
                                flat: true
                                enabled: !AIModule.whisperDownloading
                                onClicked: {
                                    page.messageArea = "whisper"
                                    AIModule.downloadWhisperModel(modelData.name)
                                }
                            }
                        }
                    }

                    Button {
                        text: page.showAllWhisper ? qsTr("Hide the compressed versions")
                                                  : qsTr("Show the compressed versions too")
                        Layout.fillWidth: true
                        onClicked: page.showAllWhisper = !page.showAllWhisper
                    }
                }
            }

            // ---------------------------------------------------------- Where it is used
            RoundedItem {
                Label {
                    text: qsTr("Where it is used")
                    font.pointSize: LingmoUI.Units.fontSubheading
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Spotlight: type “ai:” before a question, or ask anything ending with “?”.")
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Automator: routines can hand their output to the AI to summarize or explain it.")
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: LingmoUI.Theme.secondaryTextColor
                    text: AIModule.remoteServer
                          ? qsTr("The models run on the Ollama server at %1.").arg(AIModule.serverAddress)
                          : qsTr("The models run on this computer. Nothing you ask leaves it.")
                }
            }

            Item {
                height: LingmoUI.Units.largeSpacing
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: qsTr("Choose a folder for the assistant")
        currentFolder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        onAccepted: page.folderError = AIModule.addAssistantFolder(selectedFolder)
    }

    Dialog {
        id: removeDialog
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        title: qsTr("Remove %1?").arg(removeDialog.modelName)

        property string modelName: ""
        property bool inUse: false
        // A whisper model instead of an Ollama one
        property bool whisper: false
        onClosed: whisper = false

        ColumnLayout {
            spacing: LingmoUI.Units.largeSpacing * 1.5

            Label {
                text: removeDialog.inUse
                      ? (removeDialog.whisper
                         ? qsTr("Lingmo Studio uses it for subtitles: choose or download another one afterwards. You can download it again later.")
                         : qsTr("It is the model in use: Spotlight and Automator won't answer until you choose another one. You can download it again later."))
                      : qsTr("It frees up disk space. You can download it again later.")
                wrapMode: Text.WordWrap
                Layout.maximumWidth: 320
            }

            RowLayout {
                spacing: LingmoUI.Units.largeSpacing

                Button {
                    text: qsTr("Cancel")
                    Layout.fillWidth: true
                    onClicked: removeDialog.reject()
                }

                Button {
                    text: qsTr("Remove")
                    flat: true
                    Layout.fillWidth: true
                    onClicked: {
                        const whisper = removeDialog.whisper
                        removeDialog.accept()
                        if (whisper) {
                            page.messageArea = "whisper"
                            AIModule.removeWhisperModel(removeDialog.modelName)
                        } else {
                            page.messageArea = "installed"
                            AIModule.removeModel(removeDialog.modelName)
                        }
                    }
                }
            }
        }
    }
}
