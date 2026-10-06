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

    function fitColor(level) {
        if (level === "Perfect" || level === "Good")
            return LingmoUI.Theme.greenColor
        if (level === "Marginal")
            return LingmoUI.Theme.orangeColor
        if (level === "Too Tight")
            return LingmoUI.Theme.redColor
        return LingmoUI.Theme.disabledTextColor
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
    }

    // Notice when Ollama gets installed or started outside this page
    Timer {
        interval: 4000
        repeat: true
        running: !page.running
        onTriggered: AIModule.refresh()
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
                    color: LingmoUI.Theme.disabledTextColor
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
            color: AIModule.errorText !== "" ? LingmoUI.Theme.redColor : LingmoUI.Theme.disabledTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    Scrollable {
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
                        color: LingmoUI.Theme.disabledTextColor
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    LingmoUI.BusyIndicator {
                        id: ollamaBusy
                        source: "qrc:/images/view-refresh.svg"
                        width: 22
                        height: width
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
                            return LingmoUI.Theme.disabledTextColor
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
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
                            color: LingmoUI.Theme.disabledTextColor
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
                    color: LingmoUI.Theme.disabledTextColor
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
                    color: LingmoUI.Theme.disabledTextColor
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
                                    color: modelData.embedding ? LingmoUI.Theme.disabledTextColor : LingmoUI.Theme.textColor
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: modelData.embedding
                                          ? page.joinParts([modelData.details, qsTr("Embeddings for search, not for chat")])
                                          : page.joinParts([modelData.details, modelData.thinking ? qsTr("Reasoning") : ""])
                                    color: LingmoUI.Theme.disabledTextColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Label {
                                    visible: modelData.fitLevel !== ""
                                    text: modelData.fitLevel === "Too Tight"
                                          ? qsTr("Too heavy for this computer: answers will be slow.")
                                          : page.joinParts([modelData.fitText, modelData.runMode, modelData.speed])
                                    color: modelData.fitLevel === "Too Tight" ? LingmoUI.Theme.orangeColor
                                                                              : LingmoUI.Theme.disabledTextColor
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
                            color: LingmoUI.Theme.disabledTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: page.running && AIModule.model !== "" && AIModule.modelInstalled && !AIModule.modelCanThink
                            text: qsTr("“%1” can't reason, so it always answers right away. Models marked “Reasoning” can.").arg(AIModule.model)
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
                    color: AIModule.errorText !== "" ? LingmoUI.Theme.redColor : LingmoUI.Theme.disabledTextColor
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
                        color: LingmoUI.Theme.disabledTextColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    LingmoUI.BusyIndicator {
                        id: llmfitBusy
                        source: "qrc:/images/view-refresh.svg"
                        width: 22
                        height: width
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
                    color: LingmoUI.Theme.disabledTextColor
                    text: qsTr("This computer: %1").arg(AIModule.systemSummary)
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: !AIModule.llmfitAvailable
                    color: LingmoUI.Theme.disabledTextColor
                    text: qsTr("Install llmfit to see which models suit this computer: sudo pacman -S llmfit")
                }

                TabBar {
                    Layout.fillWidth: true
                    visible: AIModule.llmfitAvailable
                    currentIndex: ["chat", "general", "coding", "reasoning"].indexOf(AIModule.useCase)

                    TabButton {
                        text: qsTr("Conversation")
                        onClicked: { page.showAllRecommendations = false; AIModule.useCase = "chat" }
                    }
                    TabButton {
                        text: qsTr("General use")
                        onClicked: { page.showAllRecommendations = false; AIModule.useCase = "general" }
                    }
                    TabButton {
                        text: qsTr("Programming")
                        onClicked: { page.showAllRecommendations = false; AIModule.useCase = "coding" }
                    }
                    TabButton {
                        text: qsTr("Reasoning")
                        onClicked: { page.showAllRecommendations = false; AIModule.useCase = "reasoning" }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: AIModule.llmfitAvailable && AIModule.recommendations.length === 0 && text !== ""
                    color: AIModule.llmfitError !== "" ? LingmoUI.Theme.redColor : LingmoUI.Theme.disabledTextColor
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

                                Label {
                                    text: page.joinParts([modelData.parameters,
                                                          modelData.download !== "" ? qsTr("%1 download").arg(modelData.download) : "",
                                                          modelData.memory !== "" ? qsTr("needs %1 of memory").arg(modelData.memory) : ""])
                                    color: LingmoUI.Theme.disabledTextColor
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: page.joinParts([modelData.runMode, modelData.speed])
                                    color: LingmoUI.Theme.disabledTextColor
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            Label {
                                visible: modelData.installed
                                text: modelData.inUse ? qsTr("In use") : qsTr("Installed")
                                color: modelData.inUse ? LingmoUI.Theme.highlightColor : LingmoUI.Theme.disabledTextColor
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
                        color: LingmoUI.Theme.disabledTextColor
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

            // ---------------------------------------------------------- Where it is used
            RoundedItem {
                Label {
                    text: qsTr("Where it is used")
                    color: LingmoUI.Theme.disabledTextColor
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
                    color: LingmoUI.Theme.disabledTextColor
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

    Dialog {
        id: removeDialog
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        title: qsTr("Remove %1?").arg(removeDialog.modelName)

        property string modelName: ""
        property bool inUse: false

        ColumnLayout {
            spacing: LingmoUI.Units.largeSpacing * 1.5

            Label {
                text: removeDialog.inUse
                      ? qsTr("It is the model in use: Spotlight and Automator won't answer until you choose another one. You can download it again later.")
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
                        removeDialog.accept()
                        page.messageArea = "installed"
                        AIModule.removeModel(removeDialog.modelName)
                    }
                }
            }
        }
    }
}
