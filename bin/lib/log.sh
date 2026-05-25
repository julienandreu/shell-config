# shellcheck shell=bash
# Logging helpers. Source from any bin/*.sh script.
# Provides: log_info, log_success, log_warning, log_error, log_step,
#           log_section, log_header, die.

if [[ -t 1 ]]; then
    LOG_RED=$'\033[0;31m'
    LOG_GREEN=$'\033[0;32m'
    LOG_YELLOW=$'\033[0;33m'
    LOG_BLUE=$'\033[0;34m'
    LOG_BOLD=$'\033[1m'
    LOG_RESET=$'\033[0m'
else
    LOG_RED='' LOG_GREEN='' LOG_YELLOW='' LOG_BLUE='' LOG_BOLD='' LOG_RESET=''
fi

log_info()    { printf '%sℹ%s  %s\n' "$LOG_BLUE"   "$LOG_RESET" "$1"; }
log_success() { printf '%s✓%s  %s\n' "$LOG_GREEN"  "$LOG_RESET" "$1"; }
log_warning() { printf '%s⚠%s  %s\n' "$LOG_YELLOW" "$LOG_RESET" "$1"; }
log_error()   { printf '%s✗%s  %s\n' "$LOG_RED"    "$LOG_RESET" "$1" >&2; }
log_step()    { printf '   %s→%s  %s\n' "$LOG_BLUE" "$LOG_RESET" "$1"; }

log_section() {
    printf '\n%s%s%s\n' "$LOG_BOLD" "$1" "$LOG_RESET"
    printf '%s%s%s\n' "$LOG_BOLD" "$(printf '%*s' "${#1}" '' | tr ' ' '-')" "$LOG_RESET"
}

log_header() {
    local title="$1"
    local bar="============================================================"
    printf '\n%s%s%s%s\n' "$LOG_BOLD" "$LOG_BLUE" "$bar" "$LOG_RESET"
    printf '%s%s  %s%s\n'   "$LOG_BOLD" "$LOG_BLUE" "$title" "$LOG_RESET"
    printf '%s%s%s%s\n\n'  "$LOG_BOLD" "$LOG_BLUE" "$bar" "$LOG_RESET"
}

die() {
    log_error "$1"
    exit "${2:-1}"
}
