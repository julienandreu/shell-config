# aliases.zsh - shell aliases.

# eza (ls replacement) - mirrors nix-config programs.eza
# The base `eza` alias injects --git/--icons/--group-directories-first/--header;
# zsh's single-pass alias recursion applies them to ls/ll/la/lt/lla as well.
if command -v eza >/dev/null 2>&1; then
    alias eza='eza --git --icons=auto --group-directories-first --header'
    alias ls='eza'
    alias ll='eza -lah'
    alias la='eza -a'
    alias lt='eza --tree'
    alias lla='eza -la'
fi

# bat (cat replacement)
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'

# Neovim aliases - mirrors nix-config programs.neovim (viAlias, vimAlias, vimdiffAlias)
if command -v nvim >/dev/null 2>&1; then
    alias vi='nvim'
    alias vim='nvim'
    alias vimdiff='nvim -d'
fi

# Dotfiles ergonomics (resolved via PATH set in init.zsh).
alias edit-shell='edit-shell.sh'
alias edit-config='edit-config.sh'
alias rebuild='rebuild.sh'
alias update='update.sh'
alias doctor='doctor.sh'
