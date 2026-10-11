import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// State for the "Diagnose with AI" assistant, read from `dwm-agent status`.
Scope {
    id: root

    property bool settingsVisible: false
    property bool loaded: false
    property bool refreshQueued: false
    property string agent: "none"
    property var installed: ({})
    property bool crashNotifications: true
    property bool hangDetection: false
    property string skills: "missing"
    property string message: ""
    readonly property bool initialLoading: !root.loaded && (statusProcess.running || root.refreshQueued)
    readonly property bool busy: statusProcess.running || setProcess.running
    readonly property bool hasAgent: root.agent !== "none"
    readonly property bool agentInstalled: root.hasAgent && root.installed[root.agent] === true

    onSettingsVisibleChanged: if (settingsVisible) root.refresh()

    function agentLabel(id) {
        if (id === "codex") return "Codex";
        if (id === "opencode") return "OpenCode";
        if (id === "gemini") return "Gemini CLI";
        return "Not set";
    }

    function parseStatus(text) {
        const installed = {};
        let agent = "none";
        let crash = true;
        let hang = false;
        let skills = "missing";
        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "agent" && fields.length >= 2) agent = fields[1];
            else if (fields[0] === "installed" && fields.length >= 3) installed[fields[1]] = fields[2] === "yes";
            else if (fields[0] === "crash-notifications" && fields.length >= 2) crash = fields[1] !== "off";
            else if (fields[0] === "hang-detection" && fields.length >= 2) hang = fields[1] === "on";
            else if (fields[0] === "skills" && fields.length >= 2) skills = fields[1];
        }
        root.agent = agent;
        root.installed = installed;
        root.crashNotifications = crash;
        root.hangDetection = hang;
        root.skills = skills;
    }

    function refresh() {
        if (statusProcess.running) {
            root.refreshQueued = true;
            return;
        }
        root.refreshQueued = false;
        statusProcess.running = true;
    }

    function setToggle(name, enabled) {
        if (setProcess.running) return;
        root.message = "";
        setProcess.command = Commands.checkedCommand(Commands.agentCommand("set", [name, enabled ? "on" : "off"]));
        setProcess.running = true;
    }

    function openTerminal(action) {
        root.message = "";
        Quickshell.execDetached(Commands.agentTerminalCommand(action));
    }

    Process {
        id: statusProcess

        command: Commands.checkedCommand(Commands.agentCommand("status", []))
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const error = this.text.trim();
                if (error.length > 0) root.message = error;
            }
        }

        onExited: (exitCode, exitStatus) => { // qmllint disable signal-handler-parameters
            root.loaded = true;
            if (exitCode !== 0 && root.message.length === 0)
                root.message = "Could not read the AI assistant status";
        }

        onRunningChanged: {
            if (!running && root.refreshQueued) {
                Qt.callLater(function() {
                    if (!statusProcess.running) root.refresh();
                });
            }
        }
    }

    Process {
        id: setProcess

        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                const error = this.text.trim();
                if (error.length > 0) root.message = error;
            }
        }

        onExited: (exitCode, exitStatus) => { // qmllint disable signal-handler-parameters
            if (exitCode !== 0 && root.message.length === 0)
                root.message = "Could not change the setting";
            root.refresh();
        }
    }
}
