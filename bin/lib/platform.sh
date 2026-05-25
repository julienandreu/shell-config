# shellcheck shell=bash
# Platform detection helpers. Source after log.sh.

require_macos() {
    if [[ "${OSTYPE:-}" != darwin* ]]; then
        die "This script supports macOS only (got OSTYPE=$OSTYPE)."
    fi
}

is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]]
}

brew_prefix() {
    if is_apple_silicon; then
        printf '/opt/homebrew'
    else
        printf '/usr/local'
    fi
}

ensure_brew_in_path() {
    local prefix
    prefix="$(brew_prefix)"
    if ! command -v brew >/dev/null 2>&1; then
        if [[ -x "$prefix/bin/brew" ]]; then
            eval "$("$prefix/bin/brew" shellenv)"
        fi
    fi
}
