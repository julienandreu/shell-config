#!/usr/bin/env bash
# =============================================================================
# Dotfiles Bootstrap Installer
# =============================================================================
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/julienandreu/nix-config/main/install.sh)"
# =============================================================================

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/julienandreu/nix-config.git}"
INSTALL_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Colors
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; BLUE=$'\033[0;34m'
    BOLD=$'\033[1m';   RESET=$'\033[0m'
else
    RED='' GREEN='' BLUE='' BOLD='' RESET=''
fi
log_info()    { printf '%sℹ%s  %s\n' "$BLUE"  "$RESET" "$1"; }
log_success() { printf '%s✓%s  %s\n' "$GREEN" "$RESET" "$1"; }
log_error()   { printf '%s✗%s  %s\n' "$RED"   "$RESET" "$1" >&2; }

printf '\n%s%s============================================================%s\n' "$BOLD" "$BLUE" "$RESET"
printf '%s%s  Dotfiles Installer%s\n'                                            "$BOLD" "$BLUE" "$RESET"
printf '%s%s============================================================%s\n\n'  "$BOLD" "$BLUE" "$RESET"

if [[ "${OSTYPE:-}" != darwin* ]]; then
    log_error "macOS only (got OSTYPE=$OSTYPE)."
    exit 1
fi

# Git via Xcode Command Line Tools.
if ! command -v git >/dev/null 2>&1; then
    log_info "Git not found - installing Xcode Command Line Tools."
    xcode-select --install 2>/dev/null || true
    printf '\nWait for the Xcode CLT install to finish, then rerun this script.\n'
    exit 1
fi

if [[ -d "$INSTALL_DIR/.git" ]]; then
    log_info "Existing checkout at $INSTALL_DIR - pulling latest."
    git -C "$INSTALL_DIR" pull --ff-only --quiet || log_error "git pull failed (continuing)."
elif [[ -e "$INSTALL_DIR" ]]; then
    log_error "$INSTALL_DIR exists but isn't a git checkout. Move it aside and rerun."
    exit 1
else
    log_info "Cloning $REPO_URL -> $INSTALL_DIR"
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi
log_success "Repository ready."

cd "$INSTALL_DIR"
export DOTFILES_DIR="$INSTALL_DIR"
exec bash "$INSTALL_DIR/setup.sh"
