# Plan

**Timestamp:** 2026-02-17T11:57:35.487Z

## Original Request

The repo is used as an easiert way to install Camunda C8 locally with kind. In the meanwhile, there are new docs available, that already describe very good
what needs to be done for the installation. Study and research the docs: https://docs.camunda.io/docs/self-managed/deployment/helm/cloud-providers/kind/
There are also references to many scripts that need to be executed in sequence. My goal is to get a one shot command to install everything.
The approach should be:
1. git clone the camunda-deployment-references repo (or update if already available) - use the csctl folder in ~/.config
2. execute one script, that executes all the listed scripts (default: domain mode, but there should be a way for a no-domain mode)
3. A sub command that prints credentials: https://docs.camunda.io/docs/self-managed/deployment/helm/cloud-providers/kind/#default-credentials
4. A sub command that deletes everything: https://docs.camunda.io/docs/self-managed/deployment/helm/cloud-providers/kind/#cleanup

It would be great if the default print out would overwrite the individual outputs, and only prints out the current step with a spinner.
With a parameter -v / --verbose the individual output can be enabled.

Use the same tech stack as available: bash. Also make sure to support overrides via custom extra values yaml files.

## Refined Requirements

Here is the complete revised section:

---

## Problem Statement

The existing `csctl` bash CLI for installing Camunda 8 on kind is outdated. Camunda now maintains an official `camunda-deployment-references` repo with well-structured scripts for local kind deployment. Replace `csctl` with a new version that wraps those official scripts, providing a one-shot install experience with a clean spinner UI.

## Acceptance Criteria

### 1. Repository Management
- On first run, `csctl` clones `camunda/camunda-deployment-references` (branch `stable/<version>`) into `~/.config/csctl/camunda-deployment-references/`
- On subsequent runs, it pulls latest changes (or re-clones if version changed)
- Default version: `8.8`, configurable via `--version <version>` flag
- Stores state (mode, version, chart version) in `~/.config/csctl/state` file

### 2. Environment Variables
Before invoking any reference repo script, `csctl` must export the following environment variables (matching the Makefile defaults):
- `CLUSTER_NAME=camunda-platform-local`
- `CAMUNDA_NAMESPACE=camunda`
- `CAMUNDA_RELEASE_NAME=camunda`
- `CERT_DIR=.certs`

These are required by every `procedure/` script in the reference repo. Without them, script calls will fail.

### 3. Install Command (`csctl` or `csctl install`)
- **Domain mode (default):** Executes these steps in sequence:
  1. `procedure/cluster-create.sh`
  2. `procedure/ingress-nginx-deploy.sh`
  3. `procedure/coredns-config.sh`
  4. `procedure/hosts-add.sh` (requires sudo)
  5. `procedure/certs-generate.sh`
  6. `procedure/certs-create-secret.sh`
  7. `procedure/certs-create-ca-configmap.sh`
  8. Helm install (see §5 for full invocation) with `values-domain.yml` + `values-mkcert.yml` + any extra values
  9. Wait for pods ready via `../../../generic/kubernetes/single-region/procedure/check-deployment-ready.sh` (relative to `kind-single-region/`)
- **No-domain mode (`--no-domain`):** Executes:
  1. `procedure/cluster-create.sh`
  2. Add keycloak hosts entry: csctl implements this inline — if `/etc/hosts` does not already contain `camunda-keycloak`, append `127.0.0.1  camunda-keycloak` (requires sudo). There is no script for this in the reference repo; the Makefile does it inline via `grep`/`tee`.
  3. Helm install (see §5) with `values-no-domain.yml` + any extra values
  4. Wait for pods ready via `../../../generic/kubernetes/single-region/procedure/check-deployment-ready.sh`
- At the end, prints credentials and access URLs (see §8)
- Saves mode (`domain`/`no-domain`) to state file

### 4. Extra Values / Profiles
- `-f <file>` flag: appends additional `--values <file>` to the `helm upgrade --install` call (can be specified multiple times)
- `-p <profile>` flag: uses a profile YAML from `csctl` repo's `extra-values/` directory (appended as extra `--values`)
- Does NOT modify the cloned reference repo; csctl calls `helm` directly (replicating what the deploy scripts do) and appends extra values files

### 5. Helm Install Invocation
Since csctl calls `helm` directly (not the deploy scripts), the full invocation must be specified:
```
helm upgrade --install camunda camunda-platform \
  --repo https://helm.camunda.io \
  --namespace camunda --create-namespace \
  --version <CAMUNDA_HELM_CHART_VERSION> \
  --values <mode-specific values files> \
  --values <extra values files...>
```
- **Release name:** `camunda`
- **Chart name:** `camunda-platform`
- **Repo URL:** `https://helm.camunda.io`
- **Namespace:** `camunda` (matching `CAMUNDA_NAMESPACE`)
- **Chart version:** Parsed from the reference repo's `procedure/camunda-deploy-domain.sh` (or `camunda-deploy-no-domain.sh`), which sets `CAMUNDA_HELM_CHART_VERSION` (e.g., `13.4.2`). csctl extracts this value at runtime. Optionally overridable via `--chart-version <version>` flag.
- **Values files (domain mode):** `values-domain.yml`, `values-mkcert.yml`, plus any `-f` / `-p` extras
- **Values files (no-domain mode):** `values-no-domain.yml`, plus any `-f` / `-p` extras

### 6. Sub-commands
- `csctl credentials` — prints default username (`admin`) and password (from `procedure/get-password.sh`). If no install has been performed (no state file or no cluster), prints a clear error message.
- `csctl delete` — reads saved mode from state, then:
  1. `helm uninstall camunda --namespace camunda`
  2. `kind delete cluster --name camunda-platform-local`
  3. If domain mode: remove hosts entries (reverse of `hosts-add.sh`), clean generated certs
  4. If no-domain mode: remove `camunda-keycloak` entry from `/etc/hosts`
  5. If no state file exists: prompt user to specify mode, or check if cluster exists and infer
- `csctl port-forward` — runs `procedure/port-forward.sh` from the reference repo. Intended for no-domain mode. If the state file indicates domain mode, print a warning (`Port forwarding is intended for no-domain mode. In domain mode, access services via https://camunda.example.com.`) but still execute if the user proceeds.

### 7. Output UX
- **Default:** Suppress individual script output; show a spinner with current step name (e.g., `⠋ Creating Kind cluster...`). On step completion, show `✓ Step name` and move to next.
- **`-v` / `--verbose`:** Show full output from each script as it runs
- On error, always show the failed step's output regardless of verbose mode

### 8. Post-Install Output
After successful install, print credentials and access information. Output differs by mode:
- **Domain mode:** Print:
  - Username: `admin`
  - Password: (from `procedure/get-password.sh`)
  - Access URL: `https://camunda.example.com`
- **No-domain mode:** Print:
  - Username: `admin`
  - Password: (from `procedure/get-password.sh`)
  - Instruction: `Run 'csctl port-forward' to access services, then open:`
  - List localhost ports (as documented in reference repo, e.g., `http://localhost:8080` for Operate, etc.)

### 9. Prerequisites Check
- Check for: `docker`, `kind`, `kubectl`, `helm`, `git`
- Domain mode additionally checks for: `mkcert`
- `csctl` does NOT depend on `make`. Although the reference repo documents `make` targets as its primary interface, csctl invokes the `procedure/` scripts directly.
- Print clear error messages for missing tools

## Technical Requirements
- Pure bash (no external dependencies beyond the prerequisites)
- Replace `scripts/csctl` with the new implementation
- Update `README.md` to reflect new usage
- Keep `extra-values/` directory for profiles
- Working directory for reference repo scripts: `~/.config/csctl/camunda-deployment-references/local/kubernetes/kind-single-region/`
- The `scripts/install` script can remain (it downloads csctl to the user's PATH)
- The path to `check-deployment-ready.sh` is `../../../generic/kubernetes/single-region/procedure/check-deployment-ready.sh` relative to `kind-single-region/`, not in the `procedure/` directory alongside other scripts

## Edge Cases
- Cluster already exists → handled by kind (idempotent via `kind create cluster`)
- Hosts entries already present → reference scripts already handle this (grep before adding); csctl's inline keycloak hosts logic must also grep before adding
- Re-running install when already installed → `helm upgrade --install` is idempotent
- Running `csctl delete` with no state file → prompt user to specify mode or check if cluster exists
- Running `csctl credentials` before install → clear error message
- Extra values file doesn't exist → error before starting install
- `csctl port-forward` in domain mode → print warning but allow execution

## Out of Scope
- Enterprise registry credentials (removed; the reference repo doesn't use them)
- Unreleased helm charts support (`-u` flag from old csctl)
- Console-specific TLS certificate generation
- Custom cluster names / namespaces (use reference repo defaults: `camunda-platform-local` / `camunda`)
- Windows support
- Invoking `make` (csctl calls scripts directly)

## Engineering Decisions

Here is the complete revised section:

---

I have sufficient clarity to implement. Here's the summary of technical decisions and assumptions:

### Script (`scripts/csctl`)
- **Complete rewrite** of the existing bash script
- Wraps `camunda/camunda-deployment-references` repo (branch `stable/<version>`, default `8.8`)
- Clones to `~/.config/csctl/camunda-deployment-references/`; working directory for scripts: `~/.config/csctl/camunda-deployment-references/local/kubernetes/kind-single-region/`
- Exports env vars before every script call (see "Env var export mapping" section below for the complete list and their derivation from state file keys)
- State file at `~/.config/csctl/state` using bash-sourceable `KEY=value` format
- Version override via `--ref <branch-or-tag>` flag (e.g., `--ref stable/8.7`). Default: `stable/8.8`. This flag sets the git branch/tag to check out. It is intentionally named `--ref` (not `--version`) to avoid conflicting with the common convention of `--version` printing the tool's own version.

### State file keys
The state file at `~/.config/csctl/state` contains the following keys (all written at install time, read at delete/credentials/port-forward time):
- `MODE` — `domain` or `no-domain`
- `CLUSTER_NAME` — kind cluster name (default: `camunda-platform-local`)
- `NAMESPACE` — Kubernetes namespace (default: `camunda-platform`)
- `RELEASE_NAME` — Helm release name (default: `camunda-platform`)
- `REF` — git branch/tag used for the deployment-references checkout (default: `stable/8.8`)
- `HOST` — hostname used in domain mode (default: `camunda.example.com`)

### Env var export mapping
The reference repo's procedure scripts expect specific env var names. csctl sources the state file and exports the following env vars before every procedure script call:

| Exported env var | Derived from | Value |
|---|---|---|
| `CLUSTER_NAME` | State key `CLUSTER_NAME` | Passed through directly (same name) |
| `CAMUNDA_NAMESPACE` | State key `NAMESPACE` | `export CAMUNDA_NAMESPACE="$NAMESPACE"` |
| `CAMUNDA_RELEASE_NAME` | State key `RELEASE_NAME` | `export CAMUNDA_RELEASE_NAME="$RELEASE_NAME"` |
| `CERT_DIR` | Derived from working directory | `export CERT_DIR="$WORK_DIR/.certs/"` where `WORK_DIR` is `~/.config/csctl/camunda-deployment-references/local/kubernetes/kind-single-region` |

`CERT_DIR` has no state file key because it is always deterministic — it is the `.certs/` subdirectory within the reference repo's `kind-single-region/` working directory. It is populated by `procedure/setup-mkcert.sh` during domain-mode installs.

### Subcommands and argument parsing
- **Argument parsing strategy:** csctl uses subcommand-first parsing. The first positional argument must be a recognized subcommand (`install`, `delete`, `credentials`, `port-forward`) or a global flag (`-h`/`--help`). If no subcommand is provided and no flags are given, csctl prints the usage summary and exits. **There is no implicit default to `install`.** Running `csctl -f foo.yaml` without a subcommand is an error ("Unknown option or missing subcommand"). This avoids accidental installs.
- `csctl install [flags]` — install (domain by default)
- `csctl delete` — teardown based on saved mode
- `csctl credentials` — print admin credentials (see Credentials section below)
- `csctl port-forward` — run `procedure/port-forward.sh` (see Port-forward section below)
- `csctl -h` / `csctl --help` — usage summary

### Global flags
The following flags are accepted by **all subcommands** as well as at the top level:
- `-h` / `--help` — print usage summary (top-level or subcommand-specific help)
- `-v` / `--verbose` — show full output instead of spinner UI. Applies to all subcommands: `csctl install --verbose`, `csctl delete --verbose`, etc.

### `install` subcommand flags (complete specification)

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--no-domain` | boolean | `false` | Use no-domain (port-forward) mode instead of domain mode |
| `--ref <branch-or-tag>` | string | `stable/8.8` | Git branch/tag to check out in `camunda-deployment-references` |
| `--cluster <name>` | string | `camunda-platform-local` | Kind cluster name |
| `--namespace <name>` | string | `camunda-platform` | Kubernetes namespace for the Camunda deployment |
| `--release <name>` | string | `camunda-platform` | Helm release name |
| `--host <hostname>` | string | `camunda.example.com` | Hostname for domain mode (ignored in no-domain mode) |
| `-p <profile>` | string (repeatable) | _(none)_ | Profile name resolved to `<csctl-repo-root>/extra-values/<profile>.yaml`, where `<csctl-repo-root>` is determined by resolving the directory containing the `scripts/csctl` script (i.e., `$(cd "$(dirname "$0")/.." && pwd)`). May be specified multiple times; files are appended in order. |
| `-f <file>` | string (repeatable) | _(none)_ | Path to an additional Helm values file (resolved relative to `$PWD`). May be specified multiple times; files are appended in order. |

Note: `-v`/`--verbose` is a global flag (see "Global flags" section above), not install-specific.

All values that correspond to state file keys (`--cluster`, `--namespace`, `--release`, `--host`, `--ref`, `--no-domain`) are persisted to `~/.config/csctl/state` at install time.

### Flags for `delete`, `credentials`, and `port-forward`
These subcommands accept **no subcommand-specific flags** (only the global `-v`/`--verbose` and `-h`/`--help`). They rely entirely on the state file for configuration (cluster name, namespace, release name, mode, etc.).

**Missing state file behavior:** If the state file at `~/.config/csctl/state` does not exist when `delete`, `credentials`, or `port-forward` is invoked, csctl prints the error message `"Error: No csctl state found. Run 'csctl install' first."` and exits with code 1.

### Install flow sequence

The `csctl install` subcommand executes the following steps in order:

1. **Prerequisites check** — verify required tools are installed (see Prerequisites section)
2. **Clone/update reference repo** — clone `camunda/camunda-deployment-references` to `~/.config/csctl/camunda-deployment-references/` (or `git fetch && git checkout` if already cloned), check out the branch/tag specified by `--ref`
3. **Extract Helm chart version** — parse `CAMUNDA_HELM_CHART_VERSION` from the reference repo (see Helm invocation section)
4. **Helm repo setup** — run `helm repo add camunda https://helm.camunda.io && helm repo update camunda` to ensure the Camunda Helm chart repo is configured and up-to-date. This runs every install (idempotent; `helm repo add` with `--force-update` avoids errors if already added).
5. **Kind cluster creation** — run `procedure/setup-kind.sh` from the reference repo's `kind-single-region/` working directory, with env vars exported per the "Env var export mapping" section
6. **Ingress setup** — run `procedure/setup-ingress.sh` from the reference repo
7. **mkcert setup (domain mode only)** — run `procedure/setup-mkcert.sh` from the reference repo. This script handles all mkcert operations: it calls `mkcert -install` (to install the local CA), generates certificates for the configured hostname (`mkcert <hostname>`), and stores them in the `.certs/` directory within the `kind-single-region/` working directory. The generated certs are picked up by the Helm values file `helm-values/values-mkcert.yml` which references `.certs/` via Kubernetes secrets. **csctl does not invoke mkcert directly** — all mkcert logic is delegated to the reference repo's procedure script.
8. **Write state file** — persist all configuration to `~/.config/csctl/state`
9. **Helm install** — run `helm upgrade --install` with the assembled values files (see Helm invocation and values ordering sections)
10. **`/etc/hosts` update** — add the appropriate entry (see `/etc/hosts` management section)
11. **Post-install output** — print credentials and access info (mode-dependent)

### Helm invocation
- csctl calls `helm upgrade --install` directly (not the deploy scripts)
- Extracts `CAMUNDA_HELM_CHART_VERSION` from `procedure/camunda-deploy-domain.sh` (or `camunda-deploy-no-domain.sh`) at runtime using a portable extraction: `sed -n 's/.*CAMUNDA_HELM_CHART_VERSION=\([^ ]*\).*/\1/p' <script>`. This avoids GNU grep's `-P` flag, which is unavailable on macOS (BSD grep). If the extraction returns empty or the file is missing, csctl exits with an error message: `"Error: Could not determine Helm chart version from reference repo. Re-run with --ref to specify a valid branch."` (no fallback to latest; explicit failure).
- Values files relative to `kind-single-region/`: `helm-values/values-domain.yml`, `helm-values/values-mkcert.yml`, `helm-values/values-no-domain.yml`
- Extra values via `-f <file>` and `-p <profile>` (from csctl repo's `extra-values/`)

### Helm values file ordering
When combining values files, csctl passes them to `helm upgrade --install` in the following left-to-right order (Helm last-wins semantics):
1. Reference repo base values: `helm-values/values-domain.yml` (or `values-no-domain.yml`)
2. Reference repo mode-specific values (domain mode only): `helm-values/values-mkcert.yml`
3. Profile files (`-p <profile>`): e.g., `extra-values/console.yaml`, in the order specified on the command line
4. User-supplied extra files (`-f <file>`), in the order specified on the command line

This ensures user-supplied files always win over defaults, and profiles always win over reference repo values.

### /etc/hosts management
- **Domain mode install:** csctl adds `127.0.0.1 <HOST>` (where `<HOST>` is the value of the `--host` flag, default `camunda.example.com`) to `/etc/hosts` using `sudo`, after prompting the user for confirmation. If the user declines, csctl prints the required entry and continues without adding it.
- **Domain mode delete:** inline `sed` with `sudo` to remove the `<HOST>` value (read from state file) from `/etc/hosts`.
- **No-domain mode install:** csctl adds `127.0.0.1 camunda-keycloak` to `/etc/hosts` using `sudo`, with the same prompt-and-fallback behavior. The hostname `camunda-keycloak` is a **literal string**, not derived from `--release` or `--namespace`. This is the hostname hardcoded in the reference repo's `values-no-domain.yml` for the Keycloak ingress in no-domain mode. If the reference repo changes this hostname in a future version, csctl must be updated to match.
- **No-domain mode delete:** inline `sed` with `sudo` to remove `camunda-keycloak` from `/etc/hosts`.

### Delete command
- Domain mode: `helm uninstall`, `kind delete cluster`, `sudo sed` to remove `<HOST>` (from state file) entries from `/etc/hosts`, `rm -rf .certs`
- No-domain mode: `helm uninstall`, `kind delete cluster`, `sudo sed` to remove `camunda-keycloak` from `/etc/hosts`
- **State file:** the state file at `~/.config/csctl/state` is **deleted** after successful teardown. This ensures a clean slate for the next install and prevents stale state from leaking into future runs.
- **Cloned reference repo:** the `~/.config/csctl/camunda-deployment-references/` directory is **retained** (not deleted). It serves as a cache to speed up subsequent installs. A fresh `git fetch && git checkout` on the next install ensures it's up-to-date. Users can manually remove it if disk space is a concern.

### Credentials command
- Retrieves admin credentials via: `kubectl get secret ${RELEASE_NAME}-keycloak -n ${NAMESPACE} -o jsonpath='{.data.admin-password}' | base64 -d` where `RELEASE_NAME` and `NAMESPACE` are read from the state file. The Keycloak secret name is `${RELEASE_NAME}-keycloak` because the Camunda Helm chart names the Keycloak secret using the release name as a prefix.
- Username is always `admin` (hardcoded in Keycloak chart defaults)
- Behavior is identical for domain and no-domain modes (same secret, same namespace)
- If the secret does not exist (e.g., cluster not running), prints an error and exits

### Port-forward command
- Runs `procedure/port-forward.sh` from the reference repo's `kind-single-region/` working directory, with env vars exported per the "Env var export mapping" section.
- **Domain mode warning:** If the state file indicates `MODE=domain`, csctl prints a warning: `"Warning: port-forward is intended for no-domain mode. In domain mode, services are accessible via https://<HOST>/."` and then **proceeds with port-forwarding anyway**. The user may have a valid reason (e.g., debugging), so csctl does not block execution.

### UX
- Spinner UI by default (suppress script output, show `⠋ Step name...` → `✓ Step name`)
- `-v`/`--verbose` (global flag) shows full output for any subcommand
- On error, always dump failed step's output
- Post-install prints credentials + access info (mode-dependent)

### Profiles (`extra-values/`)
- **Delete all existing profiles** (including size tiers `xs.yaml`, `sm.yaml`, `md.yaml`, `lg.yaml`); replace with console-focused YAML files
- **Size tiers are intentionally removed.** The old tiers (`xs`, `sm`, `md`, `lg`) controlled which platform components (Operate, Tasklist, Optimize, Modeler) were enabled. With the new architecture, component selection is fully delegated to the reference repo's values files (which enable all components by default). Users who need to disable specific components can pass a custom `-f <file>` with the relevant `enabled: false` overrides. This is an acceptable simplification because csctl's purpose is Console development, not platform component selection.
- New profiles contain primarily the `console:` section. The content of each profile is scoped to console-related Helm values, which includes:
  - `console.env` entries (telemetry, customerid, installationid, and variant-specific vars like `DISABLE_AUTH`, `LICENSE_KEY`, etc.)
  - `console.extraVolumes` / `console.extraVolumeMounts` (retained in `console-tls.yaml` for SSL cert mounting)
  - `console.overrideConfiguration` (retained in `console-override.yaml` for managed-release config)
  - `console.image` overrides (registry, repository, tag where needed, e.g., `console-harbor.yaml`)
- The "console-only" rule has **one exception**: `console-discovery-mode.yaml` additionally includes `zeebe.env` with console-ping settings (endpoint, period, retries, cluster ID). This is required because discovery mode depends on zeebe-side configuration that cannot be expressed under the `console:` section.
- Remove old `${HOST}` / `${CONSOLE_VERSION}` template vars and all non-console sections (ingress, identity, zeebe, elasticsearch, etc. are handled by reference repo values). Exception: `console-discovery-mode.yaml` retains its `zeebe` section as noted above.

### Profile-to-profile mapping and image source distinction

Each new profile is derived from its existing `xs-*` counterpart (or `xs.yaml` for the base). The complete mapping:

| New profile | Derived from | Key content |
|---|---|---|
| `console.yaml` | `xs.yaml` | Base console env (telemetry, customerid, installationid). Console enabled. No auth overrides, no license. Uses default chart image (no `console.image` overrides). |
| `console-noauth.yaml` | `xs-noauth.yaml` | Adds `CAMUNDA_CONSOLE_DISABLE_AUTH: "true"` |
| `console-override.yaml` | `xs-override.yaml` | Adds `console.overrideConfiguration` with managed releases config. Includes license key and `DISABLE_AUTH`. |
| `console-tls.yaml` | `xs-tls.yaml` | Adds `console.extraVolumes`/`extraVolumeMounts` for SSL certs and `SERVER_SSL_*` env vars |
| `console-harbor.yaml` | `xs-harbor.yaml` | Sets `console.image.registry: registry.camunda.cloud`, `console.image.repository: team-console/console-sm`, and `console.image.pullSecrets`. This is the **only profile that uses the private Camunda registry**. |
| `console-license-valid.yaml` | `xs-license-valid.yaml` | Sets `CAMUNDA_LICENSE_KEY`, `CAMUNDA_LICENSE_KEY_IS_TEST: "true"`, `CAMUNDA_CONSOLE_DISABLE_AUTH: "true"`. **Does not override `console.image`** — uses the default chart image (private registry via `pullSecrets` inherited from the existing profile is dropped; the default chart image is sufficient for license testing). |
| `console-license-valid-public.yaml` | `xs-license-valid-public.yaml` | Same license env vars as `console-license-valid.yaml`, but explicitly sets `console.image.registry: registry.hub.docker.com` and `console.image.repository: camunda/console` to use the **public Docker Hub image**. This profile exists to test license validation against the publicly available Console image, distinct from `console-harbor.yaml` which uses the private registry for non-license scenarios. |
| `console-license-invalid.yaml` | `xs-license-invalid.yaml` | Sets `CAMUNDA_LICENSE_KEY`, `CAMUNDA_CONSOLE_EXPERIMENTAL_LICENSE_CHECKER: "true"`, `CAMUNDA_CONSOLE_EXPERIMENTAL_DISABLE_AUTH: "true"`, `CAMUNDA_LICENSE_KEY_IS_TEST: "true"` |
| `console-discovery-mode.yaml` | `xs-discovery-mode.yaml` | Includes `zeebe.env` with console-ping settings. **Discovery mode endpoint:** the `CAMUNDA_CONSOLE_PING_ENDPOINT` value is set to the placeholder `https://REPLACE_ME.ngrok-free.app`. The existing hardcoded ngrok URL (`https://d3b3a8365961.ngrok-free.app`) is session-specific and non-functional for other users. Users must replace this with their own ngrok (or equivalent) tunnel URL before use. A YAML comment above the value explains this: `# Replace with your ngrok or tunnel URL`. |

**Image source summary:** Three profiles touch `console.image`: `console-harbor.yaml` (private registry `registry.camunda.cloud`), `console-license-valid-public.yaml` (public registry `registry.hub.docker.com`), and no others. All other profiles inherit the default image from the Camunda Helm chart.

### Existing `scripts/install` and `infra/` directory
- **`scripts/install`** (curl-based installer): **Delete.** The new csctl is installed by cloning the repo or copying the script directly. The curl installer references the old script and is incompatible with the new architecture.
- **`infra/`** directory (kind cluster config, ingress-nginx module): **Delete.** Cluster creation and ingress setup are now handled by the reference repo's scripts (`procedure/` directory). The csctl repo no longer needs its own infrastructure definitions.

### Prerequisites check
- Always: `docker`, `kind`, `kubectl`, `helm`, `git`
- Domain mode additionally: `mkcert`
- `port-forward.sh` runs as-is (its internal `pkill` is its own concern)

### README
- Full rewrite to reflect new CLI interface, prerequisites, usage examples, and available profiles

## Design Decisions

Here is the complete revised section:

---

## Summary of Design Decisions

### Modes: Domain vs. No-Domain

csctl supports two installation modes that determine how Camunda 8 is accessed:

- **Domain mode** (default): Camunda is exposed via an ingress controller at a hostname (e.g., `camunda.local`). Requires the user to add a `/etc/hosts` entry mapping the hostname to `127.0.0.1` and generates a self-signed TLS certificate. This is the current behavior of the existing script.
- **No-domain mode** (triggered by `--no-domain` flag on `install`): Skips ingress, TLS certificate generation, and `/etc/hosts` setup. Camunda services are accessed exclusively via `kubectl port-forward` (see `port-forward` subcommand below).

The chosen mode is persisted in the state file so that `delete`, `credentials`, and `port-forward` can behave correctly without requiring the flag again.

### CLI Structure

- Single flat help page (`csctl --help`) covering all subcommands and flags.
- Subcommands: `install` (default when no subcommand), `delete`, `credentials`, `port-forward`.

#### Flag-to-Subcommand Mapping

| Flag | `install` | `delete` | `credentials` | `port-forward` | Description |
|------|-----------|----------|---------------|----------------|-------------|
| `-p, --profile` | ✓ | | | | Profile name (e.g., `lg`, `md`, `sm`, `xs`) |
| `-u, --unreleased` | ✓ | | | | Use unreleased helm charts |
| `-r, --reset` | ✓ | | | | Reset local files before install |
| `-H, --host` | ✓ | | | | Hostname (default: `camunda.local`) |
| `-c, --cluster` | ✓ | ✓ | ✓ | ✓ | Cluster name (default: `camunda-platform-local`) |
| `-n, --namespace` | ✓ | | ✓ | ✓ | Namespace (default: `camunda-platform`) |
| `-cv, --console-version` | ✓ | | | | Console image tag (default: `SNAPSHOT`) |
| `-hv, --helm-version` | ✓ | | | | Helm chart version |
| `-st, --skip-tls` | ✓ | | | | Skip TLS cert generation |
| `-ds, --docker-server` | ✓ | | | | Docker registry server (default: `registry.camunda.cloud`) |
| `-dr, --docker-registry` | ✓ | | | | Docker registry secret name (default: `registry-camunda-cloud`) |
| `-tls, --tls` | ✓ | | | | Generate Console TLS certificate |
| `--no-domain` | ✓ | | | | Use no-domain mode (skip ingress/TLS) |
| `--no-color` | ✓ | ✓ | ✓ | ✓ | Disable colored output |
| `-v, --verbose` | ✓ | ✓ | | | Stream script output live instead of spinner |

### Subcommand Specifications

#### `install` (default)
Provisions a Kind cluster, sets up ingress (domain mode) or skips it (no-domain mode), configures secrets, and deploys Camunda 8 via Helm. This is the default when no subcommand is given.

#### `delete`
Tears down the Kind cluster and cleans up local resources. Reads mode from the state file. If no state file exists: checks if the cluster exists via `kind get clusters`, attempts to infer mode by checking `/etc/hosts` for the configured hostname, and falls back to a text prompt: `No state found. Which mode was used? (domain/no-domain):`.

#### `credentials`
Prints the current Camunda platform credentials to stdout. Retrieves the Keycloak admin password via `kubectl get secret camunda-platform-keycloak -o jsonpath='{.data.admin-password}' | base64 -d` and prints it alongside the default username (`demo`). Uses `--cluster` and `--namespace` to target the correct context.

#### `port-forward`
Starts `kubectl port-forward` processes as a long-running foreground command. Forwards the following services (using the namespace from `--namespace` or state file):

| Service | Local Port | Target Port |
|---------|-----------|-------------|
| Zeebe Gateway | 26500 | 26500 |
| Operate | 8081 | 8081 |
| Tasklist | 8082 | 8082 |
| Optimize | 8083 | 8083 |
| Console | 8080 | 8080 |
| Identity (Keycloak) | 18080 | 8080 |

Runs until the user presses Ctrl+C. On exit, all port-forward processes are terminated.

### Spinner & Progress UX

- Default mode: suppress script output, show braille spinner (`⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`) with step name and elapsed timer per step (e.g., `⠋ Creating Kind cluster... (0m 12s)`).
- On step completion: `✓ Step name (0m 45s)`.
- On error: `✗ Step name` + full captured output from the failed step, regardless of verbose mode.
- `-v` / `--verbose`: stream each script's stdout/stderr live (no spinner).
- Pod readiness: after Helm install, poll pod status via `kubectl get pods --namespace <ns> -o jsonpath` in a loop. Print a warning at 10-minute intervals (`⚠ Still waiting for pods to become ready... (10m 0s)`). No hard timeout — the loop continues until all pods are ready or the user cancels with Ctrl+C. (The existing script runs `watch kubectl get pods`, which is interactive and has no timeout; this replaces that with a non-interactive polling loop that produces the same wait-until-ready behavior.)

### Port-forward Warning

In domain mode, when the user runs `csctl port-forward`, print the following warning to stderr, then proceed immediately (no interactive prompt):

```
⚠ Warning: You are running in domain mode. Services are already accessible via
  https://<hostname>. Port-forwarding is intended for no-domain mode installations.
  Proceeding anyway — local ports may conflict with ingress-exposed services.
```

### State Management

- **Path:** `~/.config/csctl/state`. This is an intentional change from the existing `~/.csctl/` directory to follow the XDG Base Directory Specification. The `~/.csctl/` directory is used by the existing script for git checkpoints, TLS certs, and Helm values; those remain at `~/.csctl/`. Only the new state file uses `~/.config/csctl/`. No migration is needed because the existing script does not write a state file — this is a new feature.
- **Format:** JSON. Example:
  ```json
  {
    "mode": "domain",
    "version": "8.5.0",
    "chart-version": "10.2.1",
    "cluster": "camunda-platform-local",
    "namespace": "camunda-platform",
    "host": "camunda.local"
  }
  ```
- State file is written on successful `csctl install`.
- State file is removed on successful `csctl delete`.
- `csctl delete` reads `mode`, `cluster`, and `host` from state. If no state file exists, it follows the inference/prompt fallback described under the `delete` subcommand above.

### Colors

- Follow existing pattern: GREEN for success (`✓`), RED for errors (`✗`), YELLOW for warnings (`⚠`), CYAN/BLUE for informational post-install output. Respect `--no-color` flag and `NO_COLOR` env var (matching the existing `setup_colors` logic).

### Post-Install Output

Boxless, simple labeled lines:

- **Domain mode:**
  ```
  ✓ Camunda 8 installed successfully

    Username:   demo
    Password:   <retrieved from keycloak secret>
    Console:    https://camunda.local
  ```
- **No-domain mode:**
  ```
  ✓ Camunda 8 installed successfully

    Username:   demo
    Password:   <retrieved from keycloak secret>

    Run 'csctl port-forward' to access services:
      Console:    http://localhost:8080
      Operate:    http://localhost:8081
      Tasklist:   http://localhost:8082
      Optimize:   http://localhost:8083
      Keycloak:   http://localhost:18080
      Zeebe:      localhost:26500 (gRPC)
  ```

### Help Page

Single flat page generated from subcommand and flag definitions. Layout:

```
Usage: csctl [subcommand] [options] [profile]

Install Camunda 8 locally with a single command.

Subcommands:
  install       Install Camunda 8 (default if no subcommand given)
  delete        Delete the Kind cluster and clean up
  credentials   Print Camunda platform credentials
  port-forward  Forward local ports to Camunda services

Options:
  -h,  --help             Print this help and exit
  -p,  --profile          Use a profile (lg, md, sm, xs)            [install]
  -u,  --unreleased       Use unreleased helm charts                [install]
  -r,  --reset            Reset local files before install          [install]
  -H,  --host <name>      Host name (default: camunda.local)        [install]
  -c,  --cluster <name>   Cluster name (default: camunda-platform-local)
  -n,  --namespace <name> Namespace (default: camunda-platform)
  -cv, --console-version  Console version (default: SNAPSHOT)       [install]
  -hv, --helm-version     Helm chart version                        [install]
  -st, --skip-tls         Skip TLS certificate generation           [install]
  -ds, --docker-server    Docker server                             [install]
  -dr, --docker-registry  Docker registry                           [install]
  -tls, --tls             Generate Console TLS certificate          [install]
      --no-domain         Skip ingress, use port-forward            [install]
      --no-color          Disable colored output
  -v,  --verbose          Show full script output                   [install, delete]

Examples:
  csctl -p lg                  Install with large profile
  csctl install -p sm          Install with small profile
  csctl --no-domain -p xs      Install without ingress (no-domain mode)
  csctl delete                 Delete the cluster
  csctl credentials            Show login credentials
  csctl port-forward           Forward ports to Camunda services
```

## Technical Analysis

## Technical Feasibility Assessment

**Complexity: Medium** — Complete rewrite of a single 317-line bash script into ~650-800 lines, plus README. Well-defined scope with clear 1:1 mapping to upstream scripts.

### Affected Files
| File | Action |
|------|--------|
| `scripts/csctl` (317 lines) | **Full rewrite** |
| `README.md` (115 lines) | **Full rewrite** |
| `infra/` (3 files) | **Delete** — cluster config + ingress now in reference repo |
| `scripts/install` | **Keep** (maybe update URL) |
| `extra-values/*.yaml` (12 files) | **Keep** — used via `-p` flag |

### Approach
New `csctl` clones `camunda/camunda-deployment-references` (branch `stable/<version>`) to `~/.config/csctl/`, exports 4 env vars, `cd`s into `kind-single-region/`, then orchestrates: procedure scripts for infra steps + direct `helm upgrade --install` for deployment (appending extra `--values`). Chart version parsed from `procedure/camunda-deploy-domain.sh` at runtime. Spinner UX wraps each step, dumping output only on error or with `-v`.

### Risks
1. **Spinner + sudo conflict (Medium):** `hosts-add.sh` needs a password prompt, which clashes with output suppression. Must pass through stdin/stderr for sudo steps.
2. **Hidden `jq` dependency:** `check-deployment-ready.sh` uses `jq` — not in the prereqs list. Should add to checks.
3. **Profile access:** `-p` flag needs extra-values from the csctl repo, but csctl is installed as a standalone script. Needs a download-on-demand or repo-clone strategy.
4. **Upstream stability:** Depends on reference repo maintaining consistent script names, env vars, and directory structure across versions.

### Estimated Scope
- **2 files rewritten**, **3 files deleted**, **13 files unchanged**, **0 new files**
- **~650 lines bash** + **~80 lines README**
- **0 tests** (no test framework exists)

Full assessment saved to session plan.md.
