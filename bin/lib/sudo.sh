#!/usr/bin/env bash
# =============================================================================
# lib/sudo.sh - cache administrator credentials once, keep them warm.
# =============================================================================
# Depends on log.sh (log_info, die).

# Prompt for the sudo password a single time, up front, then refresh the
# cached timestamp in the background so the rest of the run (Homebrew install,
# Brewfile casks, macOS defaults) never re-prompts. sudo reads the password
# from /dev/tty, so this works even when the script arrived over curl.
#
# Idempotent and inheritable: the keep-alive PID is exported, so a child
# process (e.g. rebuild.sh launched by setup.sh) sees the parent's live
# keep-alive and skips re-prompting. The loop self-terminates when its owning
# shell exits.
ensure_sudo_session() {
    if [[ -n "${_SUDO_KEEPALIVE_PID:-}" ]] && kill -0 "$_SUDO_KEEPALIVE_PID" 2>/dev/null; then
        return 0
    fi

    log_info "Administrator access is required for some steps."
    log_info "You'll be prompted for your password once, now, and not again."
    sudo -v || die "Administrator (sudo) access is required to continue."

    ( while true; do
          sudo -n true 2>/dev/null || exit
          sleep 60
          kill -0 "$$" 2>/dev/null || exit
      done ) &
    _SUDO_KEEPALIVE_PID=$!
    export _SUDO_KEEPALIVE_PID
}
