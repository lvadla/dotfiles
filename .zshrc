export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"
export PYENV_ROOT="$HOME/.pyenv"

alias cat="bat"
alias ls="eza --group-directories-first"
alias ll="eza --group-directories-first -lah"
if [[ $(uname) == "Darwin" ]]; then
  alias helix="hx"
fi;

[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(starship init zsh)"

HOMEBREW_NO_INSTALL_UPGRADE=1
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY     # Immediately append to history file.
setopt EXTENDED_HISTORY       # Record timestamp in history.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS       # Dont record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate.
setopt SHARE_HISTORY          # Share history between all sessions.

if [[ $(uname) == "Darwin" ]]; then
  source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh
else
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
fi

if [[ $(uname) == "Darwin" ]]; then
	bindkey "^[[1;3C" forward-word
	bindkey "^[[1;3D" backward-word
else
  bindkey "^[[1;5C" forward-word
  bindkey "^[[1;5D" backward-word
  bindkey "^H" backward-kill-word
fi

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

if [[ $(uname) == "Darwin" ]]; then
	defaults write dev.warp.Warp-Stable ApplePressAndHoldEnabled -bool false
fi
