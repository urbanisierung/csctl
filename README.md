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

## Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/urbanisierung/coci/main/scripts/install)"
```
