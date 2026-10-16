# claude-profiles

Use two (or more) Claude subscriptions side by side with [Claude Code](https://claude.com/claude-code) — typically a personal account and a work account — while sharing your `CLAUDE.md` and skills between them.

Works on macOS, Linux and Windows through WSL.

## How it works

Claude Code reads its whole configuration (login, settings, plugins, history, memory) from the directory pointed to by `CLAUDE_CONFIG_DIR`, which defaults to `~/.claude`.

This script creates a second directory, `~/.claude-<profile>`, and a `claude-<profile>` launcher that sets the variable for you:

```
claude          → ~/.claude          (personal account, unchanged)
claude-jdo      → ~/.claude-jdo      (work account, status line "JDO")
                    ├── CLAUDE.md  → ~/.claude/CLAUDE.md   (shared)
                    ├── skills/    → ~/.claude/skills/     (shared)
                    ├── agents/    → ~/.claude/agents/     (shared)
                    ├── commands/  → ~/.claude/commands/   (shared)
                    └── settings.json, plugins/, …         (own)
```

## Install

```bash
git clone https://github.com/syjust/claude-profiles.git
cd claude-profiles
./install.sh jdo
```

Then:

1. Run `claude-jdo` and `/login` with your work account
2. Install the work-specific plugins and MCP servers from that profile

### Options

| Option | Default | Description |
|---|---|---|
| `--share <items>` | `CLAUDE.md,skills,agents,commands` | Items symlinked from `~/.claude` |
| `--no-share` | | Keep the profile fully independent |
| `--label <text>` | profile name in uppercase | Status line label |
| `--bin-dir <dir>` | `~/.local/bin` | Where the launcher is written |

The script is idempotent and never overwrites an existing file or directory in the profile: run it again safely.

## Good to know

- **Keep work-specific stuff out of the shared items.** Everything in a shared `skills/` folder is visible from both accounts. Put company-specific skills, agents and commands in a plugin installed only in the work profile, or in the project's own `.claude/` folder.
- **Cloud MCP connectors follow the account, not the profile.** Slack, Google Drive, Notion… connected on claude.ai are available in whichever profile is logged in with that account. Local MCP servers must be declared in each profile.
- **Project files are shared.** A repository's `.claude/` folder and `CLAUDE.md` are read by both profiles.
- **Always know which account you are on.** The script sets a status line showing the profile label. If you already have a custom status line, add the label yourself — mixing up accounts is easy otherwise.
- **IDE extensions** (VS Code, JetBrains) use `~/.claude` unless the IDE is started with `CLAUDE_CONFIG_DIR` set.
- **Windows:** run everything inside WSL, where Claude Code is installed.

## Uninstall

```bash
rm ~/.local/bin/claude-jdo
rm -rf ~/.claude-jdo   # removes the symlinks only, not the shared files in ~/.claude
```

## License

[GPL-3.0](LICENSE)
