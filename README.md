# Camunda 8 Setup Control

## Prerequisites

- Docker Engine
  - Linux: https://docs.docker.com/engine/install/ubuntu/#installation-methods
  - MacOS: https://docs.docker.com/desktop/install/mac-install/
- Kubectl
  - Linux: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
  - MacOS: https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/
- Kind
  - https://kind.sigs.k8s.io/docs/user/quick-start/
- Helm
  - https://helm.sh/docs/intro/install/
- Git
  - https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

If you want to install Enterprise components you need to configure the following environment variables:

```bash
export CAMUNDA_REG_USER='username'
export CAMUNDA_REG_PASS='password'
```

Camunda 8 will be installed locally with a self-signed TLS certificate. Make sure to add the host to your hosts file:

```bash
# /etc/hosts or /private/etc/hosts
127.0.0.1       <host_name, default: camunda.local>
```

### Helm Repository

Add the camunda repo:

```bash
helm repo add camunda https://helm.camunda.io
helm repo update
```

## Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/urbanisierung/coci/main/scripts/install)"
```

If the installation script fails, you can also simply download [csctl](./scripts/csctl), make it executable and move it to a user-wide used `bin` folder.

## Usage

```bash
# show available commands:
csctl -h

# full installation:
csctl -p lg

# delete installation:
csctl -d
```

Available options:

```bash
Available options:

-h,  --help             Print this help and exit
-p,  --profile          Use a profile instead of an extra-values file
-u,  --unreleased       Use unreleased helm charts
-r,  --reset            Reset local files
-d,  --delete           Delete the cluster
-H,  --host             Host name (default: camunda.local)
-c,  --cluster          Cluster name (default: camunda-platform-local)
-n,  --namespace        Namespace (default: camunda-platform)
-cv, --console-version  Console version (default: SNAPSHOT)
-hv, --helm-version     Helm chart version to use (optional)
-st, --skip-tls         Skip TLS certificate generation (default: false)
-ds, --docker-server    Docker server (default: registry.camunda.cloud)
-dr, --docker-registry  Docker registry (default: registry-camunda-cloud)
-tls, --tls             TLS certificate (generate Console cert)
  --no-color         Disable colored output
```

Available profiles can be found in directory [extra-values](./extra-values/). TL;DR:

| Profile | Zeebe | Console | Identity | Modeler | Operate | Tasklist | Optimize |
| ------- | ----- | ------- | -------- | ------- | ------- | -------- | -------- |
| `lg`    | x     | x       | x        | x       | x       | x        | x        |
| `md`    | x     | x       | x        |         | x       | x        | x        |
| `sm`    | x     | x       | x        |         | x       | x        |          |
| `xs`    | x     | x       | x        |         |         |          |          |

## Under the hood

`csctl` creates a new folder in your home directory: `~/.csctl`. Here you will find the following structure:

- `csctl`: Checkout of this repository.
- `tls`: Folder with created tls certificate for local installation.
- `values.yaml`: Adjusted extra values according to configured profile (for example exchanged custom `host`).

### K8s Magic

```bash
# update envvar for running pod
kubectl set env deployment/camunda-platform-console ENVVAR_NAME=ENVVAR_VALUE

# let ingress interact via https to backends
kubectl edit ingress
# add the following annotation:
# nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"

# get admin password for keycloak:
kubectl get secret camunda-platform-keycloak -o jsonpath='{.data.admin-password}' | base64 -d
```
