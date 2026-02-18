# cross-model-review Summary

**Timestamp:** 2026-02-17T13:57:48.979Z

## Stream 1

Two fixes applied to `scripts/csctl`:

1. **Helm version**: Added `| tr -d '"' | tr -d "'"` to strip quotes from the extracted `CAMUNDA_HELM_CHART_VERSION` value. The source file has `="13.4.2"` with quotes, which was being passed literally to `helm --version`, causing the "improper constraint" error.

2. **Hosts/sudo prompt**: Replaced `run_step` (which suppresses all output) with a direct execution for the hosts step, preceded by a clear yellow warning that sudo access is needed and a password prompt may appear. Also added the same sudo warning to the `add_hosts_entry` function used in no-domain mode.

---

## Stream 2

All three issues fixed in `scripts/csctl`:

1. **Helm version quotes** (line 252): Added `| tr -d '"' | tr -d "'"` to strip quotes from extracted `CAMUNDA_HELM_CHART_VERSION` — fixes `improper constraint: "13.4.2"` error.

2. **Domain hosts step** (lines 358-367): Replaced `run_step` (which hid output behind spinner) with direct execution plus an explicit `⚠` warning about sudo/password prompt.

3. **Sudo indication** (line 267): Added `"This requires sudo — you may be prompted for your password."` to the `add_hosts_entry` function used in no-domain mode.

---

## Stream 3

Both review issues are resolved in the current `scripts/csctl`:

1. **`improper constraint: "13.4.2"`** — `get_chart_version()` now pipes through `tr -d '"' | tr -d "'"` to strip quotes from the version extracted by sed.
2. **Hosts sudo warning** — Domain mode shows a `⚠` warning about sudo before running `hosts-add.sh` (moved out of `run_step` so the sudo prompt is visible); no-domain mode's `add_hosts_entry` function now includes "This requires sudo — you may be prompted for your password."
