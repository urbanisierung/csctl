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

-h, --help        Print this help and exit
-p, --profile     Use a profile instead of an extra-values file
-u, --unreleased  Use unreleased helm charts
-r, --reset       Reset local files
-d, --delete      Delete the cluster
-H, --host        Host name (default: camunda.local)
-c, --cluster     Cluster name (default: camunda-platform-local)
-n, --namespace   Namespace (default: camunda-platform)
```

Available profiles can be found in directory [extra-values](./extra-values/). TL;DR:

| Profile | Zeebe | Console | Identity | Modeler | Operate | Tasklist | Optimize |
| ------- | ----- | ------- | -------- | ------- | ------- | -------- | -------- |
| `lg`    | x     | x       | x        | x       | x       | x        | x        |
| `md`    | x     | x       | x        |         | x       | x        | x        |
| `sm`    | x     | x       | x        |         | x       | x        |          |
| `xs`    | x     | x       | x        |         |         |          |          |
