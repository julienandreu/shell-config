#!/usr/bin/env bash
# edit-config.sh - open the dotfiles configs/ root in $EDITOR.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

EDITOR="${EDITOR:-nvim}"
exec "$EDITOR" "$DOTFILES_DIR"
