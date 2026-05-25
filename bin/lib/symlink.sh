# shellcheck shell=bash
# Idempotent symlink helpers. Source after log.sh.
#
# ensure_symlink SRC DST
#   - If DST is already a symlink to SRC: no-op.
#   - If DST is a different symlink: replace it.
#   - If DST is a regular file/dir: move to DST.backup.YYYYMMDD-HHMMSS, then link.
#   - If DST's parent dir is missing: create it.

ensure_symlink() {
    local src="$1"
    local dst="$2"

    [[ -e "$src" ]] || { log_error "Symlink source missing: $src"; return 1; }

    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        local current
        current="$(readlink "$dst")"
        if [[ "$current" == "$src" ]]; then
            return 0
        fi
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        local backup
        backup="$dst.backup.$(date +%Y%m%d-%H%M%S)"
        log_warning "Backing up existing $dst to $backup"
        mv "$dst" "$backup"
    fi

    ln -s "$src" "$dst"
    log_step "linked $dst -> $src"
}

# remove_symlink DST
#   Only removes DST if it is a symlink. Safe no-op otherwise.
remove_symlink() {
    local dst="$1"
    if [[ -L "$dst" ]]; then
        rm "$dst"
        log_step "removed symlink $dst"
    fi
}
