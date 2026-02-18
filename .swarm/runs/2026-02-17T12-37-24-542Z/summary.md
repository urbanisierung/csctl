# Swarm Run Summary

**Timestamp:** 2026-02-17T13:02:39.287Z
**Tasks:** 3

## Stream 1

Both issues fixed:

1. **`console-discovery-mode.yaml`** — Removed `enabled: false` so Console stays enabled; the discovery profile now only layers `zeebe.env` and `console.env` on top of default console values.
2. **`scripts/csctl` delete command** — Removed `|| true` from helm/kind teardown steps so failures propagate and the state file is only deleted after successful cleanup.

---

## Stream 2

Both fixes applied:

1. **`remove_hosts_entry()`** (lines 282-285): Removed the interactive prompt — now directly runs `sudo sed` to delete the `/etc/hosts` entry on delete.
2. **Command dispatch** (line 578): Added `-*` pattern to detect option-leading args (e.g., `csctl -f foo`) and emit "Unknown option or missing subcommand" instead of "Unknown command".

---

## Stream 3

Both fixes applied to `scripts/csctl`:

1. **L574-577**: Added a guard before command dispatch that detects option-leading invocations (e.g., `csctl -f foo.yaml`) and emits the spec'd `"Unknown option or missing subcommand"` error. Removed the now-unreachable `-*` case.

2. **L475-482**: Added `|| die "..."` after each `run_step` for Helm uninstall and Kind cluster deletion, so failures abort before reaching the state file removal. The `|| die` pattern disables `set -e` for the left side, ensuring the explicit error handler runs with a message noting the state file is preserved.
