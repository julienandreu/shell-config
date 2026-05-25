#!/usr/bin/env bash
# =============================================================================
# setup.sh - first-run interactive bootstrap.
# =============================================================================
# Idempotent. Safe to re-run. Steps:
#   1. macOS check, Homebrew install
#   2. Catppuccin flavor prompt
#   3. Write ~/.config/dotfiles/config.sh
#   4. Run bin/rebuild.sh (Brewfile + symlinks + macOS defaults)
#   5. Git identity (name + email) -> ~/.config/dotfiles/git.local
#   6. SSH key (ed25519) for GitHub
#   7. GitHub CLI auth (optional, interactive)
#   8. fnm install --lts (if no default node)
#   9. Install claude-code (via official curl script) + codex (via npm)
#   10. Optional onboarding wizard
#   11. Optional Nix removal hint
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
export DOTFILES_DIR

# shellcheck source=bin/lib/log.sh
. "$DOTFILES_DIR/bin/lib/log.sh"
# shellcheck source=bin/lib/platform.sh
. "$DOTFILES_DIR/bin/lib/platform.sh"
# shellcheck source=bin/lib/config.sh
. "$DOTFILES_DIR/bin/lib/config.sh"

# -----------------------------------------------------------------------------
# Prompts
# -----------------------------------------------------------------------------

prompt_with_default() {
    local prompt="$1" default="${2:-}" answer
    if [[ -n "$default" ]]; then
        read -rp "$prompt [$default]: " answer
        printf '%s\n' "${answer:-$default}"
    else
        read -rp "$prompt: " answer
        printf '%s\n' "$answer"
    fi
}

validate_email() {
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

# -----------------------------------------------------------------------------
# Steps
# -----------------------------------------------------------------------------

step_homebrew() {
    log_section "Homebrew"
    if command -v brew >/dev/null 2>&1; then
        log_success "Homebrew already installed at $(command -v brew)."
        return 0
    fi
    log_info "Installing Homebrew (you may be prompted for sudo)..."
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ensure_brew_in_path
    log_success "Homebrew installed."
}

step_flavor() {
    log_section "Catppuccin flavor"
    load_dotfiles_config
    if [[ -f "$DOTFILES_CONFIG" ]]; then
        log_info "Existing flavor: $CATPPUCCIN_FLAVOR (keep with empty answer)."
    fi
    local flavor
    flavor="$(prompt_with_default "Flavor (latte|frappe|macchiato|mocha)" "$CATPPUCCIN_FLAVOR")"
    case "$flavor" in
        latte|frappe|macchiato|mocha) CATPPUCCIN_FLAVOR="$flavor" ;;
        *) die "Invalid flavor: $flavor" ;;
    esac
    write_dotfiles_config
}

step_rebuild() {
    log_section "Initial rebuild"
    bash "$DOTFILES_DIR/bin/rebuild.sh"
}

step_git_identity() {
    log_section "Git identity"
    local git_local="$DOTFILES_CONFIG_DIR/git.local"
    local current_name="" current_email=""
    if [[ -f "$git_local" ]]; then
        current_name="$(awk -F'= ' '/name =/{print $2; exit}' "$git_local" | sed 's/^ *//;s/ *$//')"
        current_email="$(awk -F'= ' '/email =/{print $2; exit}' "$git_local" | sed 's/^ *//;s/ *$//')"
    fi

    local name email
    name="$(prompt_with_default "Your name" "$current_name")"
    while true; do
        email="$(prompt_with_default "Your email" "$current_email")"
        if validate_email "$email"; then break; fi
        log_warning "Email looks invalid, try again."
    done

    mkdir -p "$DOTFILES_CONFIG_DIR"
    cat > "$git_local" <<EOF
# ~/.config/dotfiles/git.local - personal git overrides (gitignored).
[user]
    name = $name
    email = $email
EOF
    log_success "Wrote $git_local"
}

step_ssh_key() {
    log_section "SSH key for GitHub"
    local key="$HOME/.ssh/id_ed25519_github"
    if [[ -f "$key" ]]; then
        log_success "SSH key already exists at $key."
    else
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        local email
        email="$(awk -F'= ' '/email =/{print $2; exit}' "$DOTFILES_CONFIG_DIR/git.local" | tr -d ' ')"
        ssh-keygen -t ed25519 -C "$email" -f "$key" -N ""
        log_success "Generated $key"
    fi

    eval "$(ssh-agent -s)" >/dev/null
    ssh-add --apple-use-keychain "$key" 2>/dev/null || ssh-add "$key" || true

    printf '\n'
    log_info "Your public key (copy & add to https://github.com/settings/ssh/new):"
    cat "$key.pub"
    if command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "$key.pub"
        log_success "Public key copied to clipboard."
    fi
    printf '\n'
    read -rp "Press Enter once the key is added to GitHub (or 'skip'): " ack
    [[ "$ack" == "skip" ]] && return 0

    if ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_success "GitHub SSH authentication works."
    else
        log_warning "Could not confirm GitHub SSH auth - test later with 'ssh -T git@github.com'."
    fi
}

step_gh_auth() {
    log_section "GitHub CLI"
    if ! command -v gh >/dev/null 2>&1; then
        log_warning "gh not installed (Brewfile should have it). Skipping."
        return 0
    fi
    if gh auth status >/dev/null 2>&1; then
        log_success "gh already authenticated."
        return 0
    fi
    read -rp "Authenticate gh now? [Y/n] " ans
    case "${ans:-y}" in
        y|Y|yes|YES) gh auth login --hostname github.com --git-protocol ssh --web ;;
        *)           log_info "Skipped. Run 'gh auth login' later." ;;
    esac
}

step_node_lts() {
    log_section "Node.js LTS via fnm"
    if ! command -v fnm >/dev/null 2>&1; then
        log_warning "fnm not installed. Skipping."
        return 0
    fi
    eval "$(fnm env --shell bash)" || true
    if fnm current 2>/dev/null | grep -q '^v'; then
        log_success "Default Node already set: $(fnm current)"
    else
        log_info "Installing latest Node LTS via fnm..."
        fnm install --lts
        fnm default lts-latest
        log_success "Node $(fnm current) set as default."
    fi
}

step_ai_assistants() {
    log_section "AI coding assistants"

    if command -v claude >/dev/null 2>&1; then
        log_success "Claude Code already installed: $(command -v claude)"
    else
        read -rp "Install Claude Code via official installer? [Y/n] " ans
        case "${ans:-y}" in
            y|Y|yes|YES)
                curl -fsSL https://claude.ai/install.sh | bash || \
                    log_warning "Claude Code install failed (non-fatal)."
                ;;
            *) log_info "Skipped Claude Code." ;;
        esac
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log_warning "npm unavailable; cannot install codex. Run fnm install --lts first."
    elif command -v codex >/dev/null 2>&1; then
        log_success "Codex already installed: $(command -v codex)"
    else
        read -rp "Install OpenAI Codex globally via npm? [Y/n] " ans
        case "${ans:-y}" in
            y|Y|yes|YES) npm install -g @openai/codex || log_warning "codex install failed." ;;
            *)           log_info "Skipped Codex." ;;
        esac
    fi
}

step_onboard() {
    log_section "Application onboarding (optional)"
    if [[ -x "$DOTFILES_DIR/onboard.sh" ]]; then
        read -rp "Run onboard.sh now (1Password, gh auth, Cursor extensions, etc.)? [Y/n] " ans
        case "${ans:-y}" in
            y|Y|yes|YES) bash "$DOTFILES_DIR/onboard.sh" ;;
            *)           log_info "Skipped. Run later with: $DOTFILES_DIR/onboard.sh" ;;
        esac
    fi
}

step_nix_uninstall_hint() {
    if [[ ! -d /nix ]]; then return 0; fi
    log_section "Optional: remove old Nix install"
    printf '/nix still exists on this machine.\n'
    printf 'The new shell-only dotfiles do not need it.\n'
    printf 'Remove it with:  %s/bin/uninstall-nix.sh\n' "$DOTFILES_DIR"
    printf '(That script is destructive and never auto-runs.)\n'
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    log_header "Dotfiles Setup"
    require_macos

    step_homebrew
    step_flavor
    step_rebuild
    step_git_identity
    step_ssh_key
    step_gh_auth
    step_node_lts
    step_ai_assistants
    step_onboard
    step_nix_uninstall_hint

    printf '\n'
    log_success "Setup complete. Open a new terminal or run 'exec zsh'."
}

main "$@"
