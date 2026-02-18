# csctl — Camunda 8 Local Setup Control

A CLI tool for deploying Camunda 8 locally on Kind, wrapping the [camunda/camunda-deployment-references](https://github.com/camunda/camunda-deployment-references) repository.

## Prerequisites

The following tools must be installed:

- [Docker](https://docs.docker.com/engine/install/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [jq](https://jqlang.github.io/jq/download/)

**Domain mode only** (default):

- [mkcert](https://github.com/FiloSottile/mkcert#installation) — used to generate self-signed TLS certificates

## Installation

### Quick install (Linux / macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/urbanisierung/csctl/main/install.sh | bash
```

This clones the repository to `~/.local/share/csctl` and symlinks the script into `~/.local/bin/`. Re-running the command updates to the latest version.

### Manual install (git clone)

```bash
git clone https://github.com/urbanisierung/csctl.git
export PATH="$PWD/csctl/scripts:$PATH"
```

With a git-based install you can update in-place via `csctl update`.

> **Windows:** csctl requires a Unix shell. Use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) to run it on Windows.

## Usage

```bash
csctl [command] [flags]
```

### Subcommands

| Subcommand     | Description                                       |
| -------------- | ------------------------------------------------- |
| `install`      | Deploy Camunda 8 locally (domain mode by default) |
| `delete`       | Tear down the deployment and cluster               |
| `credentials`  | Print Keycloak admin credentials                   |
| `port-forward` | Start port-forwarding to cluster services          |
| `update`       | Update csctl to the latest version                  |

Running `csctl` with no command is equivalent to `csctl install`.

### Global flags

| Flag              | Description                                  |
| ----------------- | -------------------------------------------- |
| `-h`, `--help`    | Print usage summary                          |
| `-v`, `--verbose` | Show full output instead of spinner UI       |

### `install` flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--no-domain` | boolean | `false` | Use no-domain (port-forward) mode instead of domain mode |
| `--version <ref>` | string | `stable/8.8` | Git branch/tag of `camunda-deployment-references` to check out |
| `-p <profile>` | string | _(none)_ | Profile from `extra-values/` (repeatable) |
| `-f <file>` | string | _(none)_ | Additional Helm values file (repeatable) |

### Examples

```bash
# Install with default settings (domain mode)
csctl install

# Install with a console profile
csctl install -p console

# Install in no-domain mode with verbose output
csctl install --no-domain --verbose

# Install with a specific version and custom values
csctl install --version stable/8.7 -f my-overrides.yaml

# Combine profiles and extra values files
csctl install -p console -p console-noauth -f my-overrides.yaml

# Print Keycloak admin credentials
csctl credentials

# Port-forward services (intended for no-domain mode)
csctl port-forward

# Delete the deployment
csctl delete

# Update csctl to the latest version
csctl update

# Show help
csctl -h
```

## Profiles

Profiles are Helm values files located in the [`extra-values/`](./extra-values/) directory. Pass them with `-p <name>` (without the `.yaml` extension).

| Profile | Description |
|---------|-------------|
| `console` | Base console env (telemetry, customerid, installationid) |
| `console-noauth` | Disables authentication (`CAMUNDA_CONSOLE_DISABLE_AUTH`) |
| `console-override` | Adds `console.overrideConfiguration` with managed releases config |
| `console-tls` | Mounts SSL certs via `extraVolumes`/`extraVolumeMounts` |
| `console-harbor` | Uses private registry (`registry.camunda.cloud`) for console image |
| `console-license-valid` | Sets a valid test license key |
| `console-license-valid-public` | Same as above but uses the public Docker Hub image |
| `console-license-invalid` | Sets an invalid license key for testing |
| `console-discovery-mode` | Enables discovery mode (includes `zeebe.env` for console-ping) |

Multiple profiles can be combined: `-p console -p console-noauth`.

User-supplied files (`-f`) are applied last and override all other values.

## How it works

csctl clones the `camunda/camunda-deployment-references` repository to `~/.config/csctl/camunda-deployment-references/` and runs its procedure scripts to set up:

1. A Kind cluster
2. Ingress (nginx)
3. TLS certificates via mkcert (domain mode only)
4. Camunda 8 via `helm upgrade --install`

Configuration is persisted to `~/.config/csctl/state` so that `delete`, `credentials`, and `port-forward` can operate without re-specifying flags.

### Domain mode vs no-domain mode

- **Domain mode** (default): Services are accessible at `https://<host>/` (default: `https://camunda.example.com/`). Requires `mkcert` and adds an entry to `/etc/hosts`.
- **No-domain mode** (`--no-domain`): Services are accessed via `kubectl port-forward`. Adds `127.0.0.1 camunda-keycloak` to `/etc/hosts`.
