#!/usr/bin/env bash
# update.sh - sync from origin + brew upgrade + rebuild.
#
# Modes:
#   --local    rebuild only (no git pull, no brew upgrade)
#   --deps     brew bundle --upgrade + rebuild (no git pull)
#   --check    brew bundle check (no install, no switch)
#   --help     show usage
# Default: git pull --ff-only + brew bundle --upgrade + rebuild.

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

log_header "update.sh (stub - implemented in Phase 3)"
log_warning "Not yet implemented. Args: $*"
exit 0
