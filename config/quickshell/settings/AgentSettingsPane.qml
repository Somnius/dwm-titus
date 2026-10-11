pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.core

Flickable {
    id: root

    required property var agentModel
    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true

    component ToggleCard: Rectangle {
        id: toggleCard

        required property string title
        required property string detail
        required property bool checked
        signal toggled

        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(64, toggleContent.implicitHeight + Theme.spacingLg * 2)
        color: Theme.controlNormalFill
        border.color: Theme.controlNormalBorder
        border.width: Theme.controlBorderWidth
        radius: Theme.controlRadius

        RowLayout {
            id: toggleContent
            anchors.fill: parent
            anchors.margins: Theme.spacingLg
            spacing: Theme.spacingLg

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                UiText {
                    Layout.fillWidth: true
                    text: toggleCard.title
                    color: Theme.controlNormalText
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                UiText {
                    Layout.fillWidth: true
                    text: toggleCard.detail
                    color: Theme.menuMutedText
                    wrapMode: Text.WordWrap
                }
            }

            PanelToggleSwitch {
                checked: toggleCard.checked
                busy: root.agentModel.busy
                accessibleName: toggleCard.title
                accessibleDescription: toggleCard.detail
                onToggled: toggleCard.toggled()
            }
        }
    }

    ColumnLayout {
        id: content
        width: root.width
        spacing: Theme.spacingLg

        RowLayout {
            Layout.fillWidth: true
            UiText {
                Layout.fillWidth: true
                text: "Diagnose with AI opens this agent when a program crashes or stops responding"
                color: Theme.menuMutedText
                elide: Text.ElideRight
            }
            ShellButton {
                label: root.agentModel.busy ? "Applying..." : "Refresh"
                enabled: !root.agentModel.busy
                onActivated: root.agentModel.refresh()
            }
        }

        UiText {
            Layout.fillWidth: true
            visible: root.agentModel.message.length > 0
            text: root.agentModel.message
            color: Theme.danger
            wrapMode: Text.WordWrap
        }

        SectionLabel { label: "Default agent" }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: agentColumn.implicitHeight + Theme.spacingLg * 2
            color: Theme.controlNormalFill
            border.color: root.agentModel.agentInstalled ? Theme.success : Theme.warning
            border.width: Theme.controlBorderWidth
            radius: Theme.controlRadius

            ColumnLayout {
                id: agentColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingLg
                spacing: Theme.spacingSm

                RowLayout {
                    Layout.fillWidth: true
                    UiText {
                        Layout.fillWidth: true
                        text: root.agentModel.agentLabel(root.agentModel.agent)
                        color: Theme.controlNormalText
                        font.bold: true
                    }
                    UiText {
                        visible: root.agentModel.hasAgent
                        text: root.agentModel.agentInstalled ? "Installed" : "Not installed"
                        color: root.agentModel.agentInstalled ? Theme.success : Theme.warning
                        font.bold: true
                    }
                }

                UiText {
                    Layout.fillWidth: true
                    text: root.agentModel.hasAgent
                        ? "Set up picks a different agent and installs it if needed. Log in opens the agent's own sign-in."
                        : "No agent is set up yet. Set up asks which agent to use, installs it and signs you in."
                    color: Theme.menuMutedText
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm
                    ShellButton {
                        label: "Set up..."
                        onActivated: root.agentModel.openTerminal("setup")
                    }
                    ShellButton {
                        label: "Log in..."
                        enabled: root.agentModel.hasAgent
                        onActivated: root.agentModel.openTerminal("login")
                    }
                }
            }
        }

        SectionLabel { label: "Alerts" }

        ToggleCard {
            title: "Crash notifications"
            detail: "Tell me when one of my programs crashes and offer to diagnose it."
            checked: root.agentModel.crashNotifications
            onToggled: root.agentModel.setToggle("crash-notifications", !root.agentModel.crashNotifications)
        }

        ToggleCard {
            title: "Hang detection"
            detail: "dwm checks every few seconds that windows still answer and tells you when one stops for 10 seconds. "
                + "Games, virtual machines and apps that are busy on purpose can show up as not responding when they are fine."
            checked: root.agentModel.hangDetection
            onToggled: root.agentModel.setToggle("hang-detection", !root.agentModel.hangDetection)
        }

        SectionLabel { label: "Skills" }

        UiText {
            Layout.fillWidth: true
            text: root.agentModel.skills === "linked"
                ? "Diagnosis skills: linked"
                : "Diagnosis skills: missing. Set up links them again."
            color: root.agentModel.skills === "linked" ? Theme.success : Theme.warning
            wrapMode: Text.WordWrap
        }
    }
}
