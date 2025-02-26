export PATH="/opt/homebrew/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"
export PYENV_ROOT="$HOME/.pyenv"

alias cat="bat"
alias ls="eza --group-directories-first"
alias ll="eza --group-directories-first -lah"

eval "$(starship init zsh)"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

HOMEBREW_NO_INSTALL_UPGRADE=1
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
