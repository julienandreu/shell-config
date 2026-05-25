#!/usr/bin/env bash
# macos-defaults.sh - apply macOS system preferences declaratively.
#
# Ported from machines/default.nix (nix-darwin system.defaults +
# networking.applicationFirewall blocks). Idempotent: `defaults write`
# is a no-op when the target value already matches.
#
# Requires sudo for the firewall block. Other settings run as the user.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

require_macos

# -----------------------------------------------------------------------------
# Keyboard
# -----------------------------------------------------------------------------

stage_keyboard() {
    log_section "Keyboard"
    # Use F1, F2, etc. as standard function keys (hold Fn for special features).
    defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
    # Globe key behavior: 0 = Do Nothing
    defaults write com.apple.HIToolbox AppleFnUsageType -int 0
    log_success "Keyboard preferences applied."
}

# -----------------------------------------------------------------------------
# Dock
# -----------------------------------------------------------------------------

stage_dock() {
    log_section "Dock"
    defaults write com.apple.dock tilesize -int 48
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 0.0
    defaults write com.apple.dock autohide-time-modifier -float 0.4
    defaults write com.apple.dock show-recents -bool false

    if command -v dockutil >/dev/null 2>&1; then
        # Reset persistent-apps to exactly this list (--no-restart; we restart at end).
        log_step "Resetting dock persistent-apps via dockutil..."
        dockutil --remove all --no-restart >/dev/null 2>&1 || true

        local apps=(
            "/Applications/Google Chrome.app"
            "/Applications/Slack.app"
            "/Applications/Cursor.app"
            "/Applications/Ghostty.app"
            "/Applications/Linear.app"
            "/Applications/1Password.app"
            "/System/Applications/System Settings.app"
        )
        local app
        for app in "${apps[@]}"; do
            if [[ -d "$app" ]]; then
                dockutil --add "$app" --no-restart >/dev/null 2>&1 || \
                    log_warning "dockutil could not add $app"
            else
                log_warning "Skipping dock entry (not installed): $app"
            fi
        done
    else
        log_warning "dockutil not installed; persistent-apps left unchanged."
    fi

    log_success "Dock preferences applied."
}

# -----------------------------------------------------------------------------
# Default browser (Chrome)
# -----------------------------------------------------------------------------

stage_default_browser() {
    log_section "Default browser (Chrome)"
    if [[ ! -d "/Applications/Google Chrome.app" ]]; then
        log_warning "Chrome not installed; skipping."
        return
    fi
    # LSHandlers array entries for http/https + html/xhtml content.
    /usr/libexec/PlistBuddy -c "Delete :LSHandlers" \
        "$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist" \
        2>/dev/null || true

    # Use plutil to write the array atomically.
    local plist="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
    /usr/libexec/PlistBuddy -c "Add :LSHandlers array" "$plist" 2>/dev/null || true
    local i=0
    for entry in \
        "LSHandlerURLScheme:http"  \
        "LSHandlerURLScheme:https" \
        "LSHandlerContentType:public.html" \
        "LSHandlerContentType:public.xhtml"
    do
        local key="${entry%%:*}"
        local val="${entry#*:}"
        /usr/libexec/PlistBuddy -c "Add :LSHandlers:$i dict"                  "$plist" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :LSHandlers:$i:$key string $val"      "$plist" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :LSHandlers:$i:LSHandlerRoleAll string com.google.chrome" "$plist" 2>/dev/null || true
        i=$((i+1))
    done
    log_success "Default browser handlers written (logout may be required)."
}

# -----------------------------------------------------------------------------
# Firewall
# -----------------------------------------------------------------------------

stage_firewall() {
    log_section "Application firewall"
    local fw=/usr/libexec/ApplicationFirewall/socketfilterfw
    [[ -x "$fw" ]] || { log_warning "socketfilterfw not found; skipping."; return; }

    log_info "Firewall changes require sudo. You may be prompted."
    sudo "$fw" --setglobalstate on >/dev/null
    sudo "$fw" --setallowsigned on >/dev/null
    sudo "$fw" --setallowsignedapp on >/dev/null
    sudo "$fw" --setblockall off >/dev/null
    sudo "$fw" --setstealthmode off >/dev/null
    log_success "Firewall configured."
}

# -----------------------------------------------------------------------------
# Restart UI services so changes take effect
# -----------------------------------------------------------------------------

stage_restart() {
    log_section "Refresh"
    killall Dock 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true
    killall cfprefsd 2>/dev/null || true
    log_success "UI services restarted."
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    log_header "macos-defaults.sh"
    stage_keyboard
    stage_dock
    stage_default_browser
    stage_firewall
    stage_restart
    log_success "macOS defaults applied."
}

main "$@"
