#!/usr/bin/env bash
# doctor.sh - non-destructive diagnostics for this dotfiles install.
#
# Exit codes:
#   0  all blocking checks passed (warnings allowed)
#   1  one or more blocking checks failed
#   2  invalid arguments

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

log_header "doctor.sh (stub - implemented in Phase 5)"
log_warning "Not yet implemented."
exit 0
