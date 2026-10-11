# dwm-titus AI assist roadmap

What this is: shipping the dwm-titus agent skills with the desktop itself,
plus "diagnose with AI" when an app crashes or stops responding. Inspired by
how Omarchy does crash diagnosis, with hang detection added on top.

Work happens in my fork (Somnius/dwm-titus, branch `ai-assist`) and gets
tested on a Fedora 44 VM running dwm-titus. Nothing goes upstream until Chris
says he wants it.

Tick boxes as things land. Each step says what to check.

## 0. titus-ai PR first
- [x] Push `dwm-titus-skills` and `pr-assets` to Somnius/titus-ai
- [x] Check the 4 screenshot links return 200
- [x] Read the final PR text and #298 comment, approve
- [x] Open the PR on ChrisTitusTech/titus-ai
- [x] Post the comment on dwm-titus#298 with the PR link

## 1. Prepare the VM and check the unknowns
- [x] Back up `~/.config/dwm-titus` and `~/.config/quickshell` on the VM
- [x] Install mise (official mise RPM repo), rpm-build, rpmlint, build deps
- [x] Note the mise package name, login command and unattended flag of
      Codex, OpenCode and Gemini (from their `--help`)
- [x] Note which skill folders each of them reads
- [x] Check notify-send `--action`/`--wait` on Fedora 44
- [x] Check the Quickshell notification action API in the installed version
- [x] List which apps on the VM answer `_NET_WM_PING`
- Check: everything recorded in NOTES.md with the command that proved it

## 2. Skills inside dwm-titus
- [x] Fork dwm-titus, branch `ai-assist`
- [x] Add the skills under `config/agents/skills` (the desktop updater only syncs `config/` and `scripts/`)
- [x] install.sh / update path link them into each harness's skill folder,
      never overwriting a real folder the user made
- Check: fresh install and update on the VM leave working links

## 3. Clickable notifications in the panel
- [x] Turn on notification actions in Quickshell
- [x] Show action buttons in popups and history, click runs the action
- [x] Plain notifications look and behave like before
- Check: `notify-send --action=yes=Yes --wait "test"` prints `yes` on click

## 4. AI agent tools and crash notifications
- [x] `dwm-agent setup|default|install|login|set|status` (pick Codex / OpenCode / Gemini, mise install, browser login)
- [x] `dwm-agent` (opens the harness in a terminal)
- [x] `dwm-agent-diagnose` (builds the prompt for crash / hang / window)
- [x] `dwm-crash-watch`, started from autostart, on by default
- [x] "Diagnose a window with AI" (`dwm-agent-diagnose window`; no launcher entry or keybind yet)
- Check: crash a test app on purpose -> notification -> click -> the agent
  opens and uses the dwm-titus-debug skill

## 5. Hang detection in dwm
- [x] dwm pings windows that support `_NET_WM_PING`
- [x] No answer for 10 s -> marked as not responding, answer again -> cleared
- [x] dwm calls `dwm-hang-event`, which shows "<app> is not responding" with
      Diagnose with AI / Kill / Wait
- [x] Off by default, ignore list per app
- Check: freeze a test app (`kill -STOP`) -> notification; resume it
  (`kill -CONT`) -> cleared; `make check-xvfb-runtime` still passes

## 6. Settings
- [x] "AI assistant" section: harness, install/login, crash switch (on),
      hang switch (off)
- [x] First AI setup asks about hang notifications and warns that games, VMs
      and busy apps can show up as hung when they're not
- Check: switches survive a re-login, hang switch off means dwm sends no pings

## 7. Sample RPM
- [x] `dwm-titus-ai-skills.spec` (noarch, skills only; the helpers ship with dwm-titus)
- [x] Builds on the VM, rpmlint clean
- [x] Install, use, remove on the VM; nothing left behind in /usr
- [x] Notes for putting it on COPR

## 8. Demo
- [x] Full run on the VM: crash, hang, force quit, settings (the browser login
      is still for me to do)
- [x] Screenshots
- [ ] VM config restored from the backups afterwards (kept the fork installed so
      I can try it; backups in ~/ai-assist-backup-20261011075855 on the VM)

## 9. Reviews
- [x] `codex review` on the fork until clean
- [x] Second review (Fable)
- [x] Fixes committed

## 10. Proposal for Chris
- [ ] Issue draft on dwm-titus: what, why, how it's split (skills, panel
      actions, hang detection, crash watcher, RPM), what's tested, risks
- [ ] I read and approve it, then it gets posted with links to the fork,
      the RPM and screenshots

## Known risks
- The agent runs unattended and gets crash/hang details that any program can
  influence (names, titles, logs). They're passed as plain data, never run
  through a shell, and everything has an off switch.
- Hang detection can be wrong for games, VMs and apps that are busy on
  purpose. That's why it's off until you turn it on.
- The panel change affects every notification, so plain ones get tested too.
