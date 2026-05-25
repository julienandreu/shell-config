#!/usr/bin/env bash
# doctor.sh - non-destructive diagnostics for this dotfiles install.
#
# Usage:  doctor          # report
#         doctor --fix    # apply opt-in fixes (e.g., disable PEP-668 marker
#                         #                       when ALLOW_GLOBAL_PIP=1)
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

FIX=0
case "${1:-}" in
    "")        FIX=0 ;;
    "--fix")   FIX=1 ;;
    "--help"|"-h")
        printf 'Usage: doctor [--fix]\n'
        exit 0
        ;;
    *)
        printf 'Unknown arg: %s\n' "$1" >&2
        exit 2
        ;;
esac

BLOCKING_FAILS=0
WARNINGS=0
fail()  { log_error "$1"; BLOCKING_FAILS=$((BLOCKING_FAILS+1)); }
warn()  { log_warning "$1"; WARNINGS=$((WARNINGS+1)); }
ok()    { log_success "$1"; }

# -----------------------------------------------------------------------------
# Checks
# -----------------------------------------------------------------------------

check_macos() {
    log_section "Platform"
    if [[ "${OSTYPE:-}" == darwin* ]]; then
        ok "macOS detected ($(uname -m))."
    else
        fail "macOS only (OSTYPE=$OSTYPE)."
    fi
}

check_homebrew() {
    log_section "Homebrew"
    ensure_brew_in_path
    if command -v brew >/dev/null 2>&1; then
        ok "brew at $(command -v brew)."
    else
        fail "Homebrew not installed."
        return
    fi
    if brew bundle check --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
        ok "Brewfile satisfied (no drift)."
    else
        warn "Brewfile drift - run 'update --deps'."
    fi
}

check_config() {
    log_section "Dotfiles config"
    if [[ -f "$DOTFILES_CONFIG" ]]; then
        ok "$DOTFILES_CONFIG present."
        load_dotfiles_config
        log_info "  username=$USERNAME flavor=$CATPPUCCIN_FLAVOR allow_global_pip=$ALLOW_GLOBAL_PIP"
    else
        fail "Missing $DOTFILES_CONFIG. Run setup.sh."
    fi
}

check_symlinks() {
    log_section "Symlinks"
    local links=(
        "$HOME/.zshrc:$DOTFILES_DIR/configs/zsh/zshrc"
        "$HOME/.gitconfig:$DOTFILES_DIR/configs/git/config"
        "$HOME/.ssh/config:$DOTFILES_DIR/configs/ssh/config"
        "$HOME/.config/gh/config.yml:$DOTFILES_DIR/configs/gh/config.yml"
        "$HOME/.config/bat/config:$DOTFILES_DIR/configs/bat/config"
        "$HOME/.config/bottom/bottom.toml:$DOTFILES_DIR/configs/bottom/bottom.toml"
        "$HOME/.config/karabiner/karabiner.json:$DOTFILES_DIR/configs/karabiner/karabiner.json"
        "$HOME/.config/nvim:$DOTFILES_DIR/configs/nvim"
    )
    local pair link expected
    for pair in "${links[@]}"; do
        link="${pair%%:*}"
        expected="${pair#*:}"
        if [[ -L "$link" && "$(readlink "$link")" == "$expected" ]]; then
            ok "$link -> ok"
        elif [[ ! -e "$link" ]]; then
            warn "$link missing (run 'rebuild')."
        else
            warn "$link is not the expected symlink (run 'rebuild')."
        fi
    done
}

check_node() {
    log_section "Node / fnm"
    if ! command -v fnm >/dev/null 2>&1; then
        warn "fnm not installed."
        return
    fi
    ok "fnm at $(command -v fnm)."
    local current
    current="$(fnm current 2>/dev/null || true)"
    if [[ -n "$current" && "$current" != "none" ]]; then
        ok "Active Node: $current"
    else
        warn "No active Node. Run 'fnm install --lts && fnm default lts-latest'."
    fi
}

check_python() {
    log_section "Python"
    local active
    active="$(command -v python3 || true)"
    if [[ -z "$active" ]]; then
        warn "python3 not on PATH."
        return
    fi
    ok "python3 at $active ($(python3 --version 2>&1))."

    # PEP 668 marker for the Homebrew python.
    local brew_py="${HOMEBREW_PREFIX:-/opt/homebrew}/lib/python3.13/EXTERNALLY-MANAGED"
    if [[ -f "$brew_py" ]]; then
        if [[ "${ALLOW_GLOBAL_PIP:-0}" == "1" ]]; then
            if [[ "$FIX" == "1" ]]; then
                mv "$brew_py" "${brew_py}.disabled"
                ok "Disabled PEP-668 marker (renamed to ${brew_py}.disabled)."
            else
                warn "PEP-668 marker active and ALLOW_GLOBAL_PIP=1 set. Run 'doctor --fix' to disable it."
            fi
        else
            ok "PEP-668 marker present. Use pipx / uv tool / uv venv (run 'py-help')."
        fi
    fi
}

check_ai_assistants() {
    log_section "AI assistants"
    if command -v claude >/dev/null 2>&1; then
        ok "claude at $(command -v claude)."
    else
        warn "Claude Code not installed (run setup.sh or 'curl -fsSL https://claude.ai/install.sh | bash')."
    fi
    if command -v codex >/dev/null 2>&1; then
        ok "codex at $(command -v codex)."
    else
        warn "Codex not installed (run 'npm install -g @openai/codex')."
    fi
}

check_gh() {
    log_section "GitHub CLI"
    if ! command -v gh >/dev/null 2>&1; then
        warn "gh not installed."
        return
    fi
    if gh auth status >/dev/null 2>&1; then
        ok "gh authenticated."
    else
        warn "gh not authenticated (run 'gh auth login')."
    fi
}

check_apps() {
    log_section "GUI apps"
    local app
    for app in "1Password" Cursor Ghostty "Google Chrome" Linear Slack "Karabiner-Elements"; do
        if [[ -d "/Applications/$app.app" ]]; then
            ok "$app.app installed."
        else
            warn "$app.app missing (run 'update --deps')."
        fi
    done
}

check_nix_remnant() {
    if [[ -d /nix ]]; then
        log_section "Nix"
        warn "/nix still present. Remove with: bin/uninstall-nix.sh (optional)."
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

log_header "doctor.sh"
check_macos
check_homebrew
check_config
check_symlinks
check_node
check_python
check_ai_assistants
check_gh
check_apps
check_nix_remnant

printf '\n'
if [[ "$BLOCKING_FAILS" -gt 0 ]]; then
    log_error "$BLOCKING_FAILS blocking check(s) failed, $WARNINGS warning(s)."
    exit 1
fi
log_success "All blocking checks passed ($WARNINGS warning(s))."
exit 0
