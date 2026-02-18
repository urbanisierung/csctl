# engineer-stream-2 Summary

**Timestamp:** 2026-02-17T12:46:18.219Z

All 9 new console-focused profiles created and validated. Here's a summary of changes:

**Deleted** (12 files): `xs.yaml`, `xs-noauth.yaml`, `xs-override.yaml`, `xs-tls.yaml`, `xs-harbor.yaml`, `xs-license-valid.yaml`, `xs-license-valid-public.yaml`, `xs-license-invalid.yaml`, `xs-discovery-mode.yaml`, `sm.yaml`, `md.yaml`, `lg.yaml`

**Created** (9 files):
| File | Key content |
|---|---|
| `console.yaml` | Base console env (telemetry, customerid, installationid) |
| `console-noauth.yaml` | Adds `CAMUNDA_CONSOLE_DISABLE_AUTH: "true"` |
| `console-override.yaml` | Adds `overrideConfiguration` with managed releases, license key, disable auth |
| `console-tls.yaml` | SSL cert volumes/mounts + `SERVER_SSL_*` env vars |
| `console-harbor.yaml` | Private registry `registry.camunda.cloud` + `pullSecrets` |
| `console-license-valid.yaml` | License key + `IS_TEST` + disable auth (default chart image) |
| `console-license-valid-public.yaml` | Same license vars + explicit `registry.hub.docker.com` image |
| `console-license-invalid.yaml` | License key + experimental license checker + experimental disable auth |
| `console-discovery-mode.yaml` | Console disabled + `zeebe.env` with ping settings, placeholder ngrok URL |

All non-console sections (ingress, identity, elasticsearch, operate, tasklist, optimize, zeebe-gateway, connectors) removed. Template vars (`${HOST}`, `${CONSOLE_VERSION}`) removed. Only `console-discovery-mode.yaml` retains a `zeebe` section per spec.
