# completion.zsh - lazy compinit (defers ~300-400ms until first TAB press).
# See: https://scottspence.com/posts/speeding-up-my-zsh-shell

autoload -Uz compinit

ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"

function _lazy_compinit() {
    unfunction _lazy_compinit
    local _comp_dump="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"

    if [[ -f "$_comp_dump" && $(date +'%j') == $(date -r "$_comp_dump" +'%j' 2>/dev/null) ]]; then
        compinit -C -d "$_comp_dump"
    else
        compinit -d "$_comp_dump"
        touch "$_comp_dump"
    fi

    zle expand-or-complete
}

zle -N expand-or-complete _lazy_compinit
