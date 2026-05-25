# shellcheck shell=bash
# Loads ~/.config/dotfiles/config.sh, falls back to environment defaults.
# Source after log.sh. Defines:
#   DOTFILES_CONFIG_DIR Path to user config directory.
#   DOTFILES_CONFIG     Path to user config file.
#   USERNAME            Login name.
#   HOME_DIRECTORY      Home dir.
#   CATPPUCCIN_FLAVOR   latte|frappe|macchiato|mocha
#   ALLOW_GLOBAL_PIP    0|1 (opt-in to disable PEP 668 marker)

DOTFILES_CONFIG_DIR="${DOTFILES_CONFIG_DIR:-$HOME/.config/dotfiles}"
DOTFILES_CONFIG="$DOTFILES_CONFIG_DIR/config.sh"

load_dotfiles_config() {
    if [[ -f "$DOTFILES_CONFIG" ]]; then
        # shellcheck disable=SC1090
        . "$DOTFILES_CONFIG"
    fi

    : "${USERNAME:=${USER:-$(id -un)}}"
    : "${HOME_DIRECTORY:=$HOME}"
    : "${CATPPUCCIN_FLAVOR:=mocha}"
    : "${ALLOW_GLOBAL_PIP:=0}"

    case "$CATPPUCCIN_FLAVOR" in
        latte|frappe|macchiato|mocha) ;;
        *) die "Invalid CATPPUCCIN_FLAVOR=$CATPPUCCIN_FLAVOR (expected latte|frappe|macchiato|mocha)." ;;
    esac

    export USERNAME HOME_DIRECTORY CATPPUCCIN_FLAVOR ALLOW_GLOBAL_PIP
}

write_dotfiles_config() {
    mkdir -p "$DOTFILES_CONFIG_DIR"
    cat > "$DOTFILES_CONFIG" <<EOF
# ~/.config/dotfiles/config.sh - machine-specific configuration
# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)

USERNAME="$USERNAME"
HOME_DIRECTORY="$HOME_DIRECTORY"
CATPPUCCIN_FLAVOR="$CATPPUCCIN_FLAVOR"
ALLOW_GLOBAL_PIP="${ALLOW_GLOBAL_PIP:-0}"
EOF
    log_success "Wrote $DOTFILES_CONFIG"
}
