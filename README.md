# Camunda 8 One Command Installation

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

If you want to install Enterprise components you need to configure the following environment variables:

```bash
export COCI_REG_USER='username'
export COCI_REG_PASS='password'
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

## Usage

```bash
# show available commands:
coci -v

# full installation:
coci -p full

# delete installation:
coci -d
```
