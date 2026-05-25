#!/usr/bin/env bash
# uninstall-nix.sh - OPTIONAL, DESTRUCTIVE removal of an existing Nix install.
#
# This script is NEVER run automatically. It exists so users converting from
# the old nix-darwin setup can reclaim /nix without external tooling.
#
# What it does (all gated on explicit YES confirmation):
#   1. Unload nix-daemon LaunchDaemons (multi-user)
#   2. Kill any lingering nix-daemon / nix processes
#   3. Unmount /nix if it's a separate volume; remove the directory
#   4. Remove $HOME/.nix-profile, $HOME/.nix-defexpr, $HOME/.nix-channels
#   5. Comment out .nix-profile sourcing in ~/.zshrc, ~/.bash_profile, ~/.profile
#
# Won't touch any non-Nix files. Re-runnable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

require_macos
log_header "uninstall-nix.sh"

if [[ ! -d /nix && ! -e "$HOME/.nix-profile" && ! -e "$HOME/.nix-channels" ]]; then
    log_success "No Nix install detected. Nothing to do."
    exit 0
fi

cat <<'WARN'

This will remove:
  /nix                       (system store, requires sudo)
  ~/.nix-profile
  ~/.nix-defexpr
  ~/.nix-channels
  nix-daemon LaunchDaemons

It will also comment out any '.nix-profile' source lines in:
  ~/.zshrc  ~/.bash_profile  ~/.profile

This is destructive. There is no undo.

WARN
read -rp "Type YES (uppercase) to proceed: " ans
if [[ "$ans" != "YES" ]]; then
    log_warning "Aborted."
    exit 0
fi

# -----------------------------------------------------------------------------
# 1. Unload nix-daemon
# -----------------------------------------------------------------------------
log_section "Unloading nix-daemon"
for plist in /Library/LaunchDaemons/org.nixos.nix-daemon.plist \
             /Library/LaunchDaemons/com.nixos.nix-daemon.plist; do
    if [[ -f "$plist" ]]; then
        sudo launchctl unload "$plist" 2>/dev/null || true
        sudo rm -f "$plist"
        log_step "removed $plist"
    fi
done

# -----------------------------------------------------------------------------
# 2. Kill leftovers
# -----------------------------------------------------------------------------
log_section "Killing leftover processes"
sudo pkill -9 nix-daemon 2>/dev/null || true
sudo pkill -9 nix        2>/dev/null || true
log_success "Stopped any running Nix processes."

# -----------------------------------------------------------------------------
# 3. /nix volume / directory
# -----------------------------------------------------------------------------
log_section "Removing /nix"
if [[ -d /nix ]]; then
    if mount | grep -q ' on /nix '; then
        log_info "/nix is a mounted volume - unmounting..."
        sudo diskutil unmount force /nix 2>/dev/null || \
            sudo diskutil unmount /nix 2>/dev/null || \
            sudo umount -f /nix 2>/dev/null || \
            sudo umount /nix 2>/dev/null || true
    fi
    sudo find /nix -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
    if sudo rmdir /nix 2>/dev/null || sudo rm -rf /nix 2>/dev/null; then
        log_success "/nix removed."
    else
        log_warning "/nix still present - delete the APFS 'Nix Store' volume manually via Disk Utility."
    fi
else
    log_success "/nix not present."
fi

# -----------------------------------------------------------------------------
# 4. Per-user state
# -----------------------------------------------------------------------------
log_section "Removing per-user state"
for path in "$HOME/.nix-profile" "$HOME/.nix-defexpr" "$HOME/.nix-channels" "$HOME/.local/state/nix"; do
    if [[ -e "$path" || -L "$path" ]]; then
        rm -rf "$path"
        log_step "removed $path"
    fi
done

# -----------------------------------------------------------------------------
# 5. Clean shell rc files
# -----------------------------------------------------------------------------
log_section "Cleaning shell rc files"
for rc in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc"; do
    if [[ -f "$rc" && ! -L "$rc" ]]; then
        if grep -q '\.nix-profile' "$rc" 2>/dev/null; then
            cp "$rc" "$rc.pre-nix-uninstall"
            sed -i.bak -E 's|^([^#].*\.nix-profile.*)$|# [nix-uninstall] \1|' "$rc"
            rm -f "$rc.bak"
            log_step "commented Nix lines in $rc (backup at $rc.pre-nix-uninstall)"
        fi
    fi
done

printf '\n'
log_success "Nix uninstall complete. Open a new shell to verify."
