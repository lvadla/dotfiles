export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_PICTURES_DIR="$HOME/pictures"
export PYENV_ROOT="$HOME/.pyenv"
export BROWSER=firefox
export EDITOR=hx
export VISUAL=hx
export SSH_ASKPASS=/usr/bin/ksshaskpass
export QT_STYLE_OVERRIDE=breeze

alias cat="bat"
alias ls="eza --hyperlink --group-directories-first"
alias ll="eza --hyperlink --group-directories-first -lah"

[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - --no-rehash)"
eval "$(starship init zsh)"

HOMEBREW_NO_INSTALL_UPGRADE=1
HISTORY_IGNORE="(ls|pwd|exit)*"
HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt INC_APPEND_HISTORY     # Immediately append to history file.
setopt EXTENDED_HISTORY       # Record timestamp in history.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS       # Dont record an entry that was just recorded again.
setopt HIST_IGNORE_SPACE      # Do not record an event starting with a space.
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate.
setopt SHARE_HISTORY          # Share history between all sessions.
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks from each command line being added to the history.

if [[ $(uname) == "Darwin" ]]; then
  source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh
  source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' file-patterns '%p(D):globbed-files *(D-/):directories' '*:all-files'
zstyle ':completion:*' completer _complete _correct _approximate
zstyle ':completion:*:correct:*' max-errors 2
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=*' 'l:|=*'
zstyle ':completion:*' menu select
fpath=(~/.zsh $fpath)
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

if [[ $(uname) == "Darwin" ]]; then
	bindkey "^[[1;3C" forward-word
	bindkey "^[[1;3D" backward-word
else
  bindkey "^[[1;5C" forward-word
  bindkey "^[[1;5D" backward-word
  backward-kill-word-break() {
    local WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
    zle backward-kill-word
  }
  zle -N backward-kill-word-break
  bindkey "^H" backward-kill-word-break
fi

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

preexec() {
  # Start timer before each command
  TIMER=$(date +%s)
}

precmd() {
  # Check duration after command finishes
  if [[ -n $TIMER ]]; then
    NOW=$(date +%s)
    DURATION=$((NOW - TIMER))
    if [[ $DURATION -ge 10 ]]; then
      echo -ne "\a"
      if [[ "$(uname)" == "Darwin" ]]; then
        osascript -e "beep"
      fi
    fi
    unset TIMER
  fi

  # Refresh terminal theme cache for git/lazygit pager
  ~/scripts/term-theme.sh > /dev/null
}
