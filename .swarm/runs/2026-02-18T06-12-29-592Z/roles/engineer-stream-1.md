# engineer-stream-1 Summary

**Timestamp:** 2026-02-18T06:15:01.786Z

Here's a summary of changes:

**`install.sh`** (new) — Installation script for Linux/macOS:
- Detects OS; rejects Windows with a WSL suggestion
- Clones the repo to `~/.local/share/csctl` and copies the script to `~/.local/bin/csctl`
- Also copies `extra-values/` to the share directory for profile resolution
- Re-running updates to the latest version (does `git reset --hard origin/main`)

**`scripts/csctl`** — Added `update` command:
- New `cmd_update` function fetches the latest from `origin/main` and overwrites the running script in-place
- Also updates `extra-values/` in `~/.local/share/csctl`
- Profile resolution now falls back to `~/.local/share/csctl/extra-values/` when not found relative to the script
- Usage/help updated with the new command

**`README.md`** — Updated installation section with quick install via curl, manual install, Windows note, and `update` command documentation.
