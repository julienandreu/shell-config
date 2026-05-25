#!/usr/bin/env bash
# rebuild.sh - apply local edits (Brewfile + symlinks + macOS defaults).
#
# Run after editing anything under configs/, Brewfile, or bin/macos-defaults.sh.
# Idempotent: re-running with no changes should be a no-op.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export DOTFILES_DIR

# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"
# shellcheck source=lib/config.sh
. "$SCRIPT_DIR/lib/config.sh"
# shellcheck source=lib/symlink.sh
. "$SCRIPT_DIR/lib/symlink.sh"

log_header "rebuild.sh (stub - implemented in Phase 3)"
require_macos
ensure_brew_in_path
load_dotfiles_config
log_info "DOTFILES_DIR=$DOTFILES_DIR"
log_info "CATPPUCCIN_FLAVOR=$CATPPUCCIN_FLAVOR"
log_warning "Not yet implemented."
exit 0
