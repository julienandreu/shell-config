#!/usr/bin/env bash
# edit-shell.sh - open the live zsh init for editing, then prompt rebuild.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"

TARGET="$DOTFILES_DIR/configs/zsh/init.zsh"

if [[ ! -f "$TARGET" ]]; then
    log_warning "$TARGET does not exist yet (Phase 2 will create it)."
    exit 0
fi

EDITOR="${EDITOR:-nvim}"
"$EDITOR" "$TARGET"

read -rp "Rebuild now? [Y/n] " ans
case "${ans:-y}" in
    y|Y|yes|YES) exec "$SCRIPT_DIR/rebuild.sh" ;;
    *)           log_info "Skipped. Run 'rebuild' when ready." ;;
esac
