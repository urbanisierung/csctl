# engineer-stream-1 Summary

**Timestamp:** 2026-02-17T13:53:23.386Z

Two fixes applied to `scripts/csctl`:

1. **Helm version**: Added `| tr -d '"' | tr -d "'"` to strip quotes from the extracted `CAMUNDA_HELM_CHART_VERSION` value. The source file has `="13.4.2"` with quotes, which was being passed literally to `helm --version`, causing the "improper constraint" error.

2. **Hosts/sudo prompt**: Replaced `run_step` (which suppresses all output) with a direct execution for the hosts step, preceded by a clear yellow warning that sudo access is needed and a password prompt may appear. Also added the same sudo warning to the `add_hosts_entry` function used in no-domain mode.
