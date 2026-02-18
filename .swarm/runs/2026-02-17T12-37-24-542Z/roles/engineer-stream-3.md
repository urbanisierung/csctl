# engineer-stream-3 Summary

**Timestamp:** 2026-02-17T12:46:12.927Z

Done. Changes made:

1. **Deleted `scripts/install`** — the old curl-based installer is incompatible with the new architecture
2. **Deleted `infra/`** — cluster creation and ingress setup are now handled by the reference repo's procedure scripts
3. **Rewrote `README.md`** — documents the new subcommand-based CLI (`install`, `delete`, `credentials`, `port-forward`), prerequisites (including `mkcert` for domain mode), all flags, usage examples, the 9 new console-focused profiles, and how the tool works internally
