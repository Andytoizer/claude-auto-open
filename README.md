# claude-auto-open

Built by Andy Toizer — I write **AgentOperator**, a newsletter about building with AI agents in real workflows.

**TLDR:** When Claude Code writes a file you're supposed to look at — a `.env`, a draft, an image, anything in a hidden folder — this opens it for you automatically, once the turn finishes. No more digging through terminal output to find the path.

I built this because I kept losing track of where Claude had put things. Generate an image, draft an email, spit out a config — and then I'd spend twenty seconds hunting for the path in scrollback. Now it just opens. This is one of the hooks I use every day.

## How it works

Two hooks in `~/.claude/settings.json`:

1. **`PostToolUse` on `Write`** — when Claude writes a file matching the rules, the path gets queued to a per-session tempfile. Nothing opens yet.
2. **`Stop`** — when Claude finishes its turn, the queue is dedup'd and each file is opened with `open`. The queue is deleted.

The two-step design matters: Claude often iterates on the same image or draft multiple times within a single turn. You only see the final version open, once.

### What auto-opens

| Category | Extensions |
|---|---|
| Images | `.png` `.jpg` `.jpeg` `.gif` `.webp` `.pdf` `.svg` |
| Drafts | `.md` `.txt` `.html` `.docx` |
| Env files | `.env`, `.env.production`, any `.env.*` |
| Hidden folders | any path containing `/.something/` |

Code files (`.py`, `.ts`, `.json`, etc.) don't open — you're editing those in Claude Code already.

## Install (macOS)

```bash
git clone https://github.com/YOUR-USERNAME/claude-auto-open.git
cd claude-auto-open
./install.sh
```

Then inside Claude Code, run `/hooks` (or restart the session) so it picks up the new config.

The installer:
- Backs up your existing `~/.claude/settings.json` before touching it
- Merges the two hooks in (doesn't replace your other settings)
- Refuses to run if it's already installed, or if your settings file is broken JSON

Requires `jq`. If you don't have it: `brew install jq`.

## Uninstall

```bash
./uninstall.sh
```

Removes only these two hooks. Any other hooks and settings you have are left alone. Also backs up first, for paranoia.

## Linux / WSL

The hook uses macOS's `open` command. For other platforms, edit `hooks.json` before installing and swap one line:

| OS | Change in the `Stop` hook |
|---|---|
| macOS | `open "$p"` (default) |
| Linux | `xdg-open "$p"` |
| WSL | `explorer.exe "$(wslpath -w "$p")"` |

See [CLAUDE.md](./CLAUDE.md) for full details.

## Customizing

Want to add `.csv` to the list? Change the trigger from end-of-turn to instant? Edit `hooks.json` before installing, or edit `~/.claude/settings.json` directly after.

If you open this repo in [Claude Code](https://claude.ai/claude-code), the `CLAUDE.md` walks through everything you might want to change.

## License

MIT
