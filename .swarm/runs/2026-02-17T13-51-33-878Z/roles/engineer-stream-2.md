# engineer-stream-2 Summary

**Timestamp:** 2026-02-17T13:55:07.323Z

All three issues fixed in `scripts/csctl`:

1. **Helm version quotes** (line 252): Added `| tr -d '"' | tr -d "'"` to strip quotes from extracted `CAMUNDA_HELM_CHART_VERSION` — fixes `improper constraint: "13.4.2"` error.

2. **Domain hosts step** (lines 358-367): Replaced `run_step` (which hid output behind spinner) with direct execution plus an explicit `⚠` warning about sudo/password prompt.

3. **Sudo indication** (line 267): Added `"This requires sudo — you may be prompted for your password."` to the `add_hosts_entry` function used in no-domain mode.
