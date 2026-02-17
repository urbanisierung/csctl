# engineer-stream-3 Summary

**Timestamp:** 2026-02-17T13:54:57.201Z

Both review issues are resolved in the current `scripts/csctl`:

1. **`improper constraint: "13.4.2"`** — `get_chart_version()` now pipes through `tr -d '"' | tr -d "'"` to strip quotes from the version extracted by sed.
2. **Hosts sudo warning** — Domain mode shows a `⚠` warning about sudo before running `hosts-add.sh` (moved out of `run_step` so the sudo prompt is visible); no-domain mode's `add_hosts_entry` function now includes "This requires sudo — you may be prompted for your password."
