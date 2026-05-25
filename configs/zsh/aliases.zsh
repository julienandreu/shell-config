# aliases.zsh - shell aliases.

# eza (ls replacement)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --header'
    alias ll='eza -lah --group-directories-first --header'
    alias la='eza -a --group-directories-first --header'
    alias lt='eza --tree --level=2 --group-directories-first'
fi

# bat (cat replacement)
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'

# Vim aliases
command -v nvim >/dev/null 2>&1 && alias vim='nvim'

# Dotfiles ergonomics (resolved via PATH set in init.zsh).
alias edit-shell='edit-shell.sh'
alias edit-config='edit-config.sh'
alias rebuild='rebuild.sh'
alias update='update.sh'
alias doctor='doctor.sh'
