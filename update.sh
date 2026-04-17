#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
FLAKE_ROOT="$SCRIPT_DIR"
DARWIN_HOST="mac"
DARWIN_FLAKE="$FLAKE_ROOT#$DARWIN_HOST"

# =============================================================================
# Logging Functions
# =============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' RESET=''
fi

log_header() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${BLUE}  $1${RESET}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

log_section() {
    echo ""
    echo -e "${CYAN}▸ $1${RESET}"
    echo -e "${DIM}──────────────────────────────────────────────────${RESET}"
}

log_info()    { echo -e "${BLUE}ℹ${RESET}  $1"; }
log_success() { echo -e "${GREEN}✓${RESET}  $1"; }
log_warning() { echo -e "${YELLOW}⚠${RESET}  $1"; }
log_step()    { echo -e "${DIM}→${RESET}  $1"; }

die() {
    printf '%b✗%b  %s\n' "$RED" "$RESET" "$1" >&2
    exit "${2:-1}"
}

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<'EOF'
Usage: ./update.sh [--local|--deps|--check|--help]

Modes:
  (default)  pull latest changes, ensure brew/taps, nix flake update, rebuild
  --local    targeted Nix eval pre-flight, rebuild only (no git, no brew)
  --deps     nix flake update, targeted Nix eval pre-flight, rebuild
  --check    darwin-rebuild build only (no switch, no Homebrew work)
  --help     show this help
EOF
}

# =============================================================================
# Update Functions
# =============================================================================

ensure_homebrew() {
    if command -v brew &>/dev/null; then
        return 0
    fi

    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        return 0
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        return 0
    fi

    log_info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed"
}

pull_latest_changes() {
    if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
        log_step "Not a git repository, skipping pull"
        return 0
    fi

    log_info "Pulling latest changes..."
    git -C "$SCRIPT_DIR" pull --ff-only --quiet || \
        die "git pull failed; commit, stash, or resolve divergence before rerunning"
    log_success "Repository updated"
}

tap_homebrew_repo() {
    local tap="$1"
    local output=""

    if output="$(brew tap "$tap" 2>&1)"; then
        if grep -q "already tapped" <<<"$output"; then
            log_step "$tap already tapped"
        else
            [[ -n "$output" ]] && printf '%s\n' "$output"
            log_success "Added $tap"
        fi
        return 0
    fi

    if grep -q "already tapped" <<<"$output"; then
        log_step "$tap already tapped"
        return 0
    fi

    [[ -n "$output" ]] && printf '%s\n' "$output" >&2
    die "brew tap $tap failed"
}

update_flake_lock() {
    log_info "Updating flake lock file..."
    ( cd "$SCRIPT_DIR" && nix flake update )
    log_success "Flake lock updated"
}

preflight_eval() {
    log_info "Running targeted Nix evaluation pre-flight..."
    FLAKE_DIR="$SCRIPT_DIR" \
        nix eval --raw --impure \
        "$FLAKE_ROOT#darwinConfigurations.${DARWIN_HOST}.system.drvPath" >/dev/null || \
        die "targeted Nix evaluation failed; fix flake/modules before switching"
    log_success "Nix evaluation passed"
}

cleanup_home_manager_backups() {
    log_info "Cleaning up stale home-manager backup files..."

    local managed_files=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.gitconfig"
    )

    local cleaned=0 backup=""
    while IFS= read -r -d '' backup; do
        rm -f "$backup"
        ((cleaned+=1))
    done < <(
        for file in "${managed_files[@]}"; do
            find "$(dirname "$file")" -maxdepth 1 -type f \
                -name "$(basename "$file").backup*" -print0 2>/dev/null
        done
    )

    if (( cleaned > 0 )); then
        log_success "Removed $cleaned backup file(s)"
    else
        log_step "No backup files to clean"
    fi
}

rebuild_switch() {
    cleanup_home_manager_backups
    export HOME_MANAGER_BACKUP_OVERWRITE=1

    log_info "Rebuilding configuration (requires sudo)..."
    sudo -E FLAKE_DIR="$SCRIPT_DIR" \
        darwin-rebuild switch --flake "$DARWIN_FLAKE" --impure || \
        die "darwin-rebuild switch failed"
    log_success "System rebuilt and activated"
}

build_only() {
    log_info "Building configuration without activation..."
    FLAKE_DIR="$SCRIPT_DIR" \
        darwin-rebuild build --flake "$DARWIN_FLAKE" --impure || \
        die "darwin-rebuild build failed"
    log_success "Build completed"
}

restart_shell_prompt() {
    echo ""
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${GREEN}  ✓ Update complete${RESET}"
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    log_warning "Shell restart recommended to load updated packages"
    echo ""
    read -rp "   Restart shell now? (Y/n): " restart_shell
    restart_shell="${restart_shell:-y}"

    if [[ "$restart_shell" =~ ^[Yy]$ ]]; then
        log_info "Restarting shell..."
        exec zsh
    fi

    log_warning "Remember to restart your terminal or run: exec zsh"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    local mode="${1:-}"
    case "$mode" in
        "") mode="full" ;;
        --local|--deps|--check|--help) ;;
        -h) mode="--help" ;;
        *) printf 'error: unknown flag: %s\n\n' "$mode" >&2; usage >&2; exit 2 ;;
    esac

    cd "$SCRIPT_DIR"

    if [[ "$mode" == "--help" ]]; then
        usage
        exit 0
    fi

    log_header "🔄 Nix Configuration Update"

    case "$mode" in
        full)
            log_section "Syncing Repository"
            pull_latest_changes

            log_section "Checking Prerequisites"
            ensure_homebrew

            log_section "Updating Homebrew Taps"
            log_info "Ensuring custom Homebrew taps are available..."
            tap_homebrew_repo "oneleet/tap"
            tap_homebrew_repo "julienandreu/tap"
            log_info "Updating Homebrew and taps..."
            brew update --quiet || die "brew update failed"
            log_success "Homebrew taps updated"

            log_section "Updating Dependencies"
            update_flake_lock

            log_section "Pre-flight Evaluation"
            preflight_eval

            log_section "Rebuilding System"
            rebuild_switch

            restart_shell_prompt
            ;;
        --local)
            log_section "Pre-flight Evaluation"
            preflight_eval

            log_section "Rebuilding System"
            rebuild_switch

            restart_shell_prompt
            ;;
        --deps)
            log_section "Updating Dependencies"
            update_flake_lock

            log_section "Pre-flight Evaluation"
            preflight_eval

            log_section "Rebuilding System"
            rebuild_switch

            restart_shell_prompt
            ;;
        --check)
            log_section "Building Configuration"
            build_only
            echo ""
            log_success "Dry-run build complete (no activation performed)"
            echo ""
            ;;
    esac
}

main "$@"
