# designer Summary

**Timestamp:** 2026-02-17T12:44:02.538Z

Spec updated to v2.2. Five changes applied:

1. **§4.5 — Prompt:** Fixed to "immediate skip on invalid input" (no re-prompt). Added explicit sudo-failure handling as non-fatal warning with manual fallback.
2. **§11.3 — SIGINT trap:** Now explicitly kills `CMD_PID` and `SPINNER_PID` with `wait` to prevent zombies.
3. **§2.4 — Line width:** Error/hint messages explicitly exempt from 80-column rule for greppability.
4. **§3.6 — Delete sudo failure:** Same non-fatal pattern as install.
5. **§12 — Rationale table:** Added entries for password-in-stderr trade-off, sudo non-fatality, no-retry prompt, and explicit subprocess cleanup.
