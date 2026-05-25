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

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

flavor_title_case() {
    case "$1" in
        latte)     printf 'Latte' ;;
        frappe)    printf 'Frappé' ;;
        macchiato) printf 'Macchiato' ;;
        mocha)     printf 'Mocha' ;;
        *)         die "Unknown CATPPUCCIN_FLAVOR=$1" ;;
    esac
}

# render_template SRC DST
#   Reads SRC, replaces __CATPPUCCIN_FLAVOR__ and __CATPPUCCIN_FLAVOR_TITLE__,
#   writes DST. Idempotent (only rewrites when content differs).
render_template() {
    local src="$1" dst="$2" tmp
    mkdir -p "$(dirname "$dst")"
    tmp="$(mktemp)"
    sed \
        -e "s/__CATPPUCCIN_FLAVOR__/$CATPPUCCIN_FLAVOR/g" \
        -e "s/__CATPPUCCIN_FLAVOR_TITLE__/$CATPPUCCIN_FLAVOR_TITLE/g" \
        "$src" > "$tmp"
    if [[ ! -f "$dst" ]] || ! cmp -s "$tmp" "$dst"; then
        mv "$tmp" "$dst"
        log_step "rendered $dst"
    else
        rm -f "$tmp"
    fi
}

# -----------------------------------------------------------------------------
# Stages
# -----------------------------------------------------------------------------

stage_brew() {
    log_section "Homebrew"
    if ! command -v brew >/dev/null 2>&1; then
        die "Homebrew not installed. Run setup.sh first."
    fi
    brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock --quiet || \
        die "brew bundle failed."
    log_success "Brewfile applied."
}

stage_render_templates() {
    log_section "Rendering templates"
    local rendered="$HOME/.cache/dotfiles/rendered"
    mkdir -p "$rendered"

    render_template \
        "$DOTFILES_DIR/configs/starship/starship.toml.in" \
        "$rendered/starship.toml"

    render_template \
        "$DOTFILES_DIR/configs/ghostty/config.in" \
        "$rendered/ghostty/config"

    render_template \
        "$DOTFILES_DIR/configs/cursor/settings.json.defaults.in" \
        "$rendered/cursor/settings.json.defaults"
}

stage_symlinks() {
    log_section "Symlinks"
    local rendered="$HOME/.cache/dotfiles/rendered"

    # Static (non-templated) configs
    ensure_symlink "$DOTFILES_DIR/configs/zsh/zshrc"             "$HOME/.zshrc"
    ensure_symlink "$DOTFILES_DIR/configs/git/config"            "$HOME/.gitconfig"
    ensure_symlink "$DOTFILES_DIR/configs/ssh/config"            "$HOME/.ssh/config"
    ensure_symlink "$DOTFILES_DIR/configs/gh/config.yml"         "$HOME/.config/gh/config.yml"
    ensure_symlink "$DOTFILES_DIR/configs/bat/config"            "$HOME/.config/bat/config"
    ensure_symlink "$DOTFILES_DIR/configs/bottom/bottom.toml"    "$HOME/.config/bottom/bottom.toml"
    ensure_symlink "$DOTFILES_DIR/configs/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
    ensure_symlink "$DOTFILES_DIR/configs/nvim"                  "$HOME/.config/nvim"

    # Rendered (templated) configs
    ensure_symlink "$rendered/starship.toml"                     "$HOME/.config/starship.toml"
    ensure_symlink "$rendered/ghostty/config"                    "$HOME/.config/ghostty/config"
    ensure_symlink "$rendered/cursor/settings.json.defaults"     "$HOME/Library/Application Support/Cursor/User/settings.json.defaults"

    chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
}

stage_cursor_merge() {
    log_section "Cursor settings merge"
    local script="$DOTFILES_DIR/bin/merge-cursor-settings.sh"
    if [[ -x "$script" ]]; then
        "$script" || log_warning "Cursor merge script reported an error (non-fatal)."
    else
        log_warning "merge-cursor-settings.sh missing - skipping."
    fi
}

stage_macos_defaults() {
    log_section "macOS defaults"
    if [[ -x "$SCRIPT_DIR/macos-defaults.sh" ]]; then
        "$SCRIPT_DIR/macos-defaults.sh" || log_warning "macos-defaults.sh reported an error (non-fatal)."
    fi
}

stage_set_display() {
    log_section "Display resolution"
    if [[ -x "$SCRIPT_DIR/set-display.sh" ]]; then
        "$SCRIPT_DIR/set-display.sh" || log_warning "set-display.sh reported an error (non-fatal)."
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    log_header "rebuild.sh"
    require_macos
    ensure_brew_in_path
    load_dotfiles_config
    CATPPUCCIN_FLAVOR_TITLE="$(flavor_title_case "$CATPPUCCIN_FLAVOR")"
    export CATPPUCCIN_FLAVOR_TITLE

    log_info "DOTFILES_DIR=$DOTFILES_DIR"
    log_info "CATPPUCCIN_FLAVOR=$CATPPUCCIN_FLAVOR ($CATPPUCCIN_FLAVOR_TITLE)"

    stage_brew
    stage_render_templates
    stage_symlinks
    stage_cursor_merge
    stage_macos_defaults
    stage_set_display

    printf '\n'
    log_success "rebuild complete. Run 'exec zsh' to reload your shell."
}

main "$@"
