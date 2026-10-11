#!/bin/sh
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
shell_qml=$repo/config/quickshell/shell.qml
settings_model=$repo/config/quickshell/settings/SettingsModel.qml
settings_window=$repo/config/quickshell/settings/SettingsWindow.qml
agent_model=$repo/config/quickshell/settings/AgentSettingsModel.qml
agent_pane=$repo/config/quickshell/settings/AgentSettingsPane.qml
commands=$repo/config/quickshell/core/Commands.qml
agent=$repo/scripts/dwm-agent

# Wiring: one model, a registered section and a deferred pane.
test "$(grep -c 'AgentSettingsModel {' "$shell_qml")" -eq 1
grep -Fq 'settingsVisible: settingsModel.visible && settingsModel.selectedSectionId === "agent"' "$shell_qml"
grep -Fq 'agentModel: agentModel' "$shell_qml"
grep -Fq '{ "id": "agent", "label": "AI assistant",' "$settings_model"
grep -Fq 'required property var agentModel' "$settings_window"
grep -Fq 'AgentSettingsPane {' "$settings_window"
grep -Fq 'root.settingsModel.selectedSectionId === "agent"' "$settings_window"
grep -Fq 'dataLoading: root.agentModel.initialLoading' "$settings_window"
grep -Fq 'root.settingsModel.selectedSectionId !== "agent"' "$settings_window"

# Helpers go through the managed command resolver.
grep -Fq 'helperCommand("dwm-agent", action, args, true)' "$commands"
grep -Fq 'helperCommand("dwm-terminal", "-e", agentCommand(action, []), true)' "$commands"
grep -Fq 'Commands.checkedCommand(Commands.agentCommand("status", []))' "$agent_model"
grep -Fq 'Commands.agentCommand("set", [name, enabled ? "on" : "off"])' "$agent_model"
grep -Fq 'Quickshell.execDetached(Commands.agentTerminalCommand(action))' "$agent_model"
grep -Fq 'root.refresh();' "$agent_model"

grep -Fq 'label: "Set up..."' "$agent_pane"
grep -Fq 'label: "Log in..."' "$agent_pane"
grep -Fq 'enabled: root.agentModel.hasAgent' "$agent_pane"
grep -Fq 'title: "Crash notifications"' "$agent_pane"
grep -Fq 'title: "Hang detection"' "$agent_pane"
grep -Fq 'dwm checks every few seconds that windows still answer and tells you when one stops for 10 seconds. ' "$agent_pane"
grep -Fq 'Games, virtual machines and apps that are busy on purpose can show up as not responding when they are fine.' "$agent_pane"
grep -Fq 'setToggle("crash-notifications"' "$agent_pane"
grep -Fq 'setToggle("hang-detection"' "$agent_pane"
grep -Fq 'PanelToggleSwitch {' "$agent_pane"

# Backend: `dwm-agent set` creates and removes the toggle files.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
run_agent() {
	env HOME="$work/home" XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work/data" \
		PATH=/usr/bin:/bin "$agent" "$@"
}
expect_status() {
	run_agent status | grep -Fqx "$(printf '%s\t%s' "$1" "$2")" || {
		printf 'Expected %s %s in dwm-agent status\n' "$1" "$2" >&2
		exit 1
	}
}

expect_status crash-notifications on
expect_status hang-detection off
run_agent set hang-detection on
test -e "$work/config/dwm-titus/hang-detection"
expect_status hang-detection on
run_agent set crash-notifications off
test -e "$work/config/dwm-titus/crash-notifications-off"
expect_status crash-notifications off
run_agent set hang-detection off
test ! -e "$work/config/dwm-titus/hang-detection"
expect_status hang-detection off
run_agent set crash-notifications on
test ! -e "$work/config/dwm-titus/crash-notifications-off"
expect_status crash-notifications on
if run_agent set hang-detection maybe 2>/dev/null; then
	printf 'dwm-agent set accepted an invalid value\n' >&2
	exit 1
fi
if run_agent set unknown on 2>/dev/null; then
	printf 'dwm-agent set accepted an unknown setting\n' >&2
	exit 1
fi
run_agent --help | grep -Fq 'dwm-agent set <crash-notifications|hang-detection> <on|off>'

printf 'Quickshell AI assistant settings contract: PASS\n'
