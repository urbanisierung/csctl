# engineer-stream-3 Summary

**Timestamp:** 2026-02-17T13:25:52.621Z

Fixed in `scripts/csctl`:

1. **`setup-kind.sh` → `cluster-create.sh`** — matched actual script name in the reference repo
2. **`setup-ingress.sh` → `ingress-nginx-deploy.sh`** — matched actual script name, moved inside domain-only block (no-domain mode doesn't use ingress per the Makefile)
3. **`setup-mkcert.sh` → 3 separate scripts** — split into `certs-generate.sh`, `certs-create-secret.sh`, `certs-create-ca-configmap.sh` matching the reference repo's procedure
4. **Added missing `coredns-config.sh` step** — required for domain mode per the Makefile workflow
