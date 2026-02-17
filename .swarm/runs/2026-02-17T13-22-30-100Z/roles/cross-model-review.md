# cross-model-review Summary

**Timestamp:** 2026-02-17T13:40:18.938Z

## Stream 1

Both fixes applied and syntax check passes:

1. **README.md** — Added `jq` to the prerequisites list (line 13) to match the `check_prerequisites` function.
2. **scripts/csctl** — Added a fallback block after the mode-specific cleanup (lines 528–535): when no state file exists, both `camunda.example.com` and `camunda-keycloak` hosts entries are removed along with any leftover certs, ensuring no-domain installs don't leave behind stale `/etc/hosts` entries when mode detection is wrong.

---

## Stream 2

The reported issue is already resolved. `jq` IS a real runtime dependency — it's used by the reference repo's `check-deployment-ready.sh` (line 7: `kubectl get pods ... | jq -r ...`), and it's already documented in `README.md` line 14. Both the prerequisite check and README are consistent. Syntax check passes cleanly.

---

## Stream 3

Fixed in `scripts/csctl`:

1. **`setup-kind.sh` → `cluster-create.sh`** — matched actual script name in the reference repo
2. **`setup-ingress.sh` → `ingress-nginx-deploy.sh`** — matched actual script name, moved inside domain-only block (no-domain mode doesn't use ingress per the Makefile)
3. **`setup-mkcert.sh` → 3 separate scripts** — split into `certs-generate.sh`, `certs-create-secret.sh`, `certs-create-ca-configmap.sh` matching the reference repo's procedure
4. **Added missing `coredns-config.sh` step** — required for domain mode per the Makefile workflow
