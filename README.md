<div align="center">

# claude-quad

### Four Claude Code sessions. One window. One right-click.

![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D6?logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-22C55E)

<br />

https://github.com/user-attachments/assets/9834599f-684f-4c77-a746-6ae5333aabca

<sub>📹 Video not playing? [Watch the demo](Claude_Quad_Demo.mp4).</sub>

</div>

---

## What it does

Right-click any folder → **CLAUDE QUAD** → a maximized Windows Terminal with four colour-coded panes, each running `claude` in that folder.

```
┌─────────────┬─────────────┐
│   GENERAL   │     UI      │
│    blue     │    pink     │
├─────────────┼─────────────┤
│   BACKEND   │  RESEARCH   │
│    green    │   purple    │
└─────────────┴─────────────┘
```

Colours map to roles — glance at a pane and you know what it's for. Pair with role-specific `CLAUDE.md` files, or just use them as four parallel workspaces on the same repo.

## Requirements

- Windows 10 or 11
- [Windows Terminal](https://aka.ms/terminal)
- [Claude Code](https://docs.claude.com/en/docs/claude-code) on `PATH`

## Install

```powershell
git clone https://github.com/LukeRenton/claude-quad.git
cd claude-quad
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Then right-click any folder → **CLAUDE QUAD**.

> On Windows 11, the entry is under **Show more options** (or hit `Shift+F10`).

The installer backs up `settings.json`, adds four hidden WT profiles + schemes, and registers an HKCU context-menu entry (no admin). Restart Windows Terminal if it was already open.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Restores everything. The `settings.json.claude-quad.bak` backup is left in place.

## Customising

| What | Where |
|---|---|
| Layout, split sizes, per-pane command | `claude-quad.ps1` |
| Pane colours | `schemes.json` |
| Role names | `profiles.json` + `claude-quad.ps1` |

Re-run `install.ps1` after edits — it's idempotent.

## Caveats

- The installer strips `//` comments from `settings.json` (the backup preserves them).
- HKCU-only — the menu entry is per-user.
- Run this installer **last** if other tools also patch WT settings.

## License

MIT
