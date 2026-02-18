# pm-tasks Summary

**Timestamp:** 2026-02-17T12:37:32.642Z

## Decomposed Tasks

1. Rewrite scripts/csctl bash script with subcommand parsing, state management, install/delete/credentials/port-forward flows, env var exports, spinner UX, and prerequisites checks
2. Replace extra-values profiles: delete all existing YAML files and create new console-focused profiles (console.yaml, console-noauth.yaml, console-override.yaml, console-tls.yaml, console-harbor.yaml, console-license-valid.yaml, console-license-valid-public.yaml, console-license-invalid.yaml, console-discovery-mode.yaml) per the profile mapping spec
3. Delete obsolete files (scripts/install, infra/ directory) and rewrite README.md to document new CLI interface, prerequisites, usage examples, and available profiles
