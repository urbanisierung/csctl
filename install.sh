#!/usr/bin/env bash
# csctl installer — works on Linux and macOS.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/urbanisierung/csctl/main/install.sh | bash
#   or: bash install.sh
#
# Re-running this script updates csctl to the latest version.

set -Eeuo pipefail

REPO_URL="https://github.com/urbanisierung/csctl.git"
CLONE_DIR="$HOME/.local/share/csctl"
BIN_DIR="${CSCTL_BIN_DIR:-$HOME/.local/bin}"

# ── Colors ───────────────────────────────────────────────────────────────────
if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
  RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NOFORMAT='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NOFORMAT=''
fi

msg()  { echo >&2 -e "${1-}"; }
die()  { msg "${RED}Error: ${1-}${NOFORMAT}"; exit 1; }

# ── OS detection ─────────────────────────────────────────────────────────────
detect_os() {
  local os
  os="$(uname -s)"
  case "$os" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "macos" ;;
    MINGW*|MSYS*|CYGWIN*)
      die "Windows is not supported. csctl requires a Unix shell (bash). Consider using WSL (Windows Subsystem for Linux).\n  https://learn.microsoft.com/en-us/windows/wsl/install" ;;
    *)
      die "Unsupported operating system: $os" ;;
  esac
}

# ── Prerequisites ────────────────────────────────────────────────────────────
check_prerequisites() {
  command -v git &>/dev/null || die "git is required but not installed."
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  local os
  os=$(detect_os)
  msg "${BLUE}Installing csctl for ${os}...${NOFORMAT}"

  check_prerequisites

  # Clone or update the repo
  if [[ -d "$CLONE_DIR/.git" ]]; then
    msg "  Updating existing installation..."
    if ! git -C "$CLONE_DIR" diff --quiet || ! git -C "$CLONE_DIR" diff --cached --quiet; then
      die "Local changes detected in ${CLONE_DIR}. Please commit or stash them before updating."
    fi
    git -C "$CLONE_DIR" fetch --all --quiet
    git -C "$CLONE_DIR" merge --ff-only origin/main --quiet
    msg "  ${GREEN}✓${NOFORMAT} Updated to latest version"
  else
    msg "  Cloning csctl..."
    mkdir -p "$(dirname "$CLONE_DIR")"
    git clone --quiet "$REPO_URL" "$CLONE_DIR"
    msg "  ${GREEN}✓${NOFORMAT} Cloned repository"
  fi

  # Symlink the script into BIN_DIR
  mkdir -p "$BIN_DIR"
  ln -sf "$CLONE_DIR/scripts/csctl" "$BIN_DIR/csctl"
  chmod +x "$CLONE_DIR/scripts/csctl"
  msg "  ${GREEN}✓${NOFORMAT} Linked csctl → ${BIN_DIR}/csctl"

  # Check if BIN_DIR is on PATH
  if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    msg ""
    msg "${YELLOW}Add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):${NOFORMAT}"
    msg ""
    msg "  export PATH=\"${BIN_DIR}:\$PATH\""
    msg ""
  fi

  msg ""
  msg "${GREEN}✓ csctl installed successfully!${NOFORMAT}"
  msg "  Run ${BLUE}csctl --help${NOFORMAT} to get started."
}

main
