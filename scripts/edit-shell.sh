#!/usr/bin/env bash
set -euo pipefail

if (( $# > 0 )); then
    echo "error: edit-shell.sh does not accept arguments" >&2
    exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET="$REPO_ROOT/modules/theme.nix"

[[ -f "$TARGET" ]]            || { echo "error: target file not found: $TARGET" >&2; exit 1; }
[[ -x "$REPO_ROOT/update.sh" ]] || { echo "error: update.sh not found or not executable" >&2; exit 1; }

sh -c '"${EDITOR:-nvim}" "$1"' _ "$TARGET"

read -rp "Apply changes now with update.sh --local? (Y/n): " reply
reply="${reply:-y}"

if [[ "$reply" =~ ^[Yy]$ ]]; then
    exec "$REPO_ROOT/update.sh" --local
fi

echo "Skipped rebuild. Run $REPO_ROOT/update.sh --local when ready."
exit 0
