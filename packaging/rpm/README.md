# dwm-titus-ai-skills RPM

Sample package for shipping the dwm-titus agent skills on their own, so they
can be updated with dnf without updating the whole desktop.

- Installs to `/usr/share/dwm-titus/agents/skills/`.
- `dwm-agent link-skills` (run by `make install-user` and `dwm-agent setup`)
  links each skill into `~/.agents/skills`, preferring this system copy over
  the copy in `~/.local/share/dwm-titus/config/agents/skills`. Codex,
  OpenCode and Gemini CLI read skills from there.
- After installing or removing the package, the links are switched the next
  time `dwm-agent` opens an agent, or right away with `dwm-agent link-skills`.
- The package never writes to home directories.

Build locally (needs `rpm-build`):

    packaging/rpm/build.sh [output-dir]

## COPR

1. Publish a release tarball that contains `skills/`, `LICENSE` and
   `README.md` under `dwm-titus-ai-skills-<version>/` (what `build.sh` builds),
   and point `Source0` at its URL.
2. `copr-cli create dwm-titus --chroot fedora-44-x86_64 --chroot fedora-44-aarch64`
3. `copr-cli build dwm-titus release/dwm-titus-ai-skills-<version>-1.fc44.src.rpm`
4. Users: `sudo dnf copr enable <owner>/dwm-titus && sudo dnf install dwm-titus-ai-skills`
