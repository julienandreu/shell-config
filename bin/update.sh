#!/usr/bin/env bash
# update.sh - sync from origin + brew upgrade + rebuild.
#
# Modes:
#   (default)  git pull --ff-only + brew bundle --upgrade + rebuild
#   --local    rebuild only (no git, no brew upgrade)
#   --deps     brew bundle --upgrade + rebuild (no git pull)
#   --check    brew bundle check (no install/upgrade, no rebuild)
#   --help     show usage

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

usage() {
    cat <<EOF
Usage: update [MODE]

  (no args)   git pull --ff-only + brew bundle --upgrade + rebuild
  --local     rebuild only (no git, no brew upgrade)
  --deps      brew bundle --upgrade + rebuild (no git pull)
  --check     brew bundle check (verify nothing missing, no changes)
  --help      this message

Use 'rebuild' directly if you just want to apply local config edits.
EOF
}

mode="full"
case "${1:-}" in
    ""|"--all")  mode="full" ;;
    "--local")   mode="local" ;;
    "--deps")    mode="deps" ;;
    "--check")   mode="check" ;;
    "--help"|"-h") usage; exit 0 ;;
    *)           usage; exit 2 ;;
esac

log_header "update.sh ($mode)"
require_macos
ensure_brew_in_path

case "$mode" in
    full)
        log_section "git pull"
        cd "$DOTFILES_DIR"
        if ! git diff-index --quiet HEAD --; then
            die "Working tree has uncommitted changes. Stash or commit first."
        fi
        git pull --ff-only || die "git pull failed (non-fast-forward?)"

        log_section "brew bundle --upgrade"
        brew bundle --file="$DOTFILES_DIR/Brewfile" --upgrade --no-lock --quiet || \
            die "brew bundle --upgrade failed."

        exec "$SCRIPT_DIR/rebuild.sh"
        ;;

    deps)
        log_section "brew bundle --upgrade"
        brew bundle --file="$DOTFILES_DIR/Brewfile" --upgrade --no-lock --quiet || \
            die "brew bundle --upgrade failed."
        exec "$SCRIPT_DIR/rebuild.sh"
        ;;

    local)
        exec "$SCRIPT_DIR/rebuild.sh"
        ;;

    check)
        log_section "brew bundle check"
        if brew bundle check --file="$DOTFILES_DIR/Brewfile" --verbose; then
            log_success "All Brewfile entries satisfied."
            exit 0
        else
            log_warning "Brewfile drift detected (see above). Run 'update --deps' to apply."
            exit 1
        fi
        ;;
esac
