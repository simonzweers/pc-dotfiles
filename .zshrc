
ZINIT_HOME="${XDG_DATA_HOME:=${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# zsh plugins
zinit ice depth=1
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found
zinit snippet OMZP::dnf
zinit snippet OMZP::docker

# load completions
autoload -U compinit && compinit

zinit cdreplay -q

# set keybinds
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# alt-left / alt-right to move by word
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

# ctrl-x ctrl-e to edit the current command in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# history configuration
HISTSIZE=10000
HISTFILE=~/.zsh-history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# completion configurations
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


# aliases
alias ls='ls --color'
alias ll='ls -lah'
alias vi='nvim'
alias vim='nvim'
alias nv='nvim'
alias tm='tmux'
alias tmsel='tmux a -t $(tmux ls | fzf | sed -r "s|^(.*): .*|\1|g")'
alias lazyvim='NVIM_APPNAME=nvim-lazyvim nvim'

alias randcow='cowsay -f $(cowsay -l | shuf -n1) "$(fortune)"'

alias gs='git status'
alias gc='git commit'
alias gp='git pull'
alias gP='git push'

alias 'cd ...'='cd ../..'
alias 'cd ....'='cd ../../..'

alias get_idf='. $HOME/esp/esp-idf/export.sh'

alias ocses='opencode -s $(opencode session list | tail -2 | fzf | cut --delimiter " " --fields 1)'

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

export PATH=$PATH:/home/simon/.spicetify

# opencode
export PATH=/home/simon/.opencode/bin:$PATH

source <(fzf --zsh)

fastfetch
