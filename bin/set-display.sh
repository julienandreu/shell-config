#!/usr/bin/env bash
# set-display.sh - set "More Space" resolution based on Mac model.
# Ported from machines/default.nix system.activationScripts.postActivation.
# Add new models by running 'sysctl hw.model' and 'displayplacer list'.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"

DISPLAYPLACER="${HOMEBREW_PREFIX:-/opt/homebrew}/bin/displayplacer"

if [[ ! -x "$DISPLAYPLACER" ]]; then
    log_warning "displayplacer not installed; skipping."
    exit 0
fi

MODEL="$(sysctl -n hw.model)"
log_info "Detected Mac model: $MODEL"

case "$MODEL" in
    # MacBook Pro 14" (M3 Pro/Max - 2023)
    "Mac15,6"|"Mac15,8"|"Mac15,10")
        "$DISPLAYPLACER" "id:1 res:1800x1169"
        log_success "Set 'More Space' (1800x1169) for MacBook Pro 14\""
        ;;
    # MacBook Pro 14" (M4 Pro/Max - 2024)
    "Mac16,1"|"Mac16,8")
        "$DISPLAYPLACER" "id:1 res:1800x1169"
        log_success "Set 'More Space' (1800x1169) for MacBook Pro 14\""
        ;;
    # MacBook Pro 16" (M3 Pro/Max - 2023)
    "Mac15,7"|"Mac15,9"|"Mac15,11")
        "$DISPLAYPLACER" "id:1 res:2056x1329"
        log_success "Set 'More Space' (2056x1329) for MacBook Pro 16\""
        ;;
    # MacBook Pro 16" (M4 Pro/Max - 2024)
    "Mac16,5"|"Mac16,6")
        "$DISPLAYPLACER" "id:1 res:2056x1329"
        log_success "Set 'More Space' (2056x1329) for MacBook Pro 16\""
        ;;
    # MacBook Air 13" (M3 - 2024)
    "Mac15,12")
        "$DISPLAYPLACER" "id:1 res:1710x1112"
        log_success "Set 'More Space' (1710x1112) for MacBook Air 13\""
        ;;
    # MacBook Air 15" (M3 - 2024)
    "Mac15,13")
        "$DISPLAYPLACER" "id:1 res:1903x1236"
        log_success "Set 'More Space' (1903x1236) for MacBook Air 15\""
        ;;
    *)
        log_warning "Unknown Mac model: $MODEL - skipping display resolution change."
        log_info "Run 'displayplacer list' and add a case in bin/set-display.sh."
        ;;
esac
