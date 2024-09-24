# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

plugins=(git)

source $ZSH/oh-my-zsh.sh


# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

alias c='clear'
alias nf='neofetch'
alias pf='pfetch'
alias shutdown='systemctl poweroff'
alias v='nvim'
alias ts='~/dotfiles/scripts/snapshot.sh'
alias matrix='cmatrix'
alias wifi='nmtui'
alias rw='~/dotfiles/waybar/launch.sh'
alias dot="cd ~/dotfiles"
alias clean-arch='yay -Sc && yay -Yc && flatpak remove --unused'
alias update-mirrors='sudo reflector --verbose --score 20 --fastest 5 --sort rate --save /etc/pacman.d/mirrorlist'
alias ssh="TERM=xterm-256color $(which ssh)"

# -----------------------------------------------------
# GIT
# -----------------------------------------------------

alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash; git pull"
alias gcheck="git checkout"

# -----------------------------------------------------
# SCRIPTS
# -----------------------------------------------------

alias ascii='~/dotfiles/scripts/figlet.sh'

# -----------------------------------------------------
# SYSTEM
# -----------------------------------------------------

alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

# -----------------------------------------------------
# START STARSHIP
# -----------------------------------------------------

eval "$(starship init zsh)"

# -----------------------------------------------------
# PYWAL
# -----------------------------------------------------

cat ~/.cache/wal/sequences

# -----------------------------------------------------
# PFETCH if on wm
# -----------------------------------------------------

pfetch

TERM=xterm-256color

# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored _approximate
zstyle :compinstall filename '/home/lasauce6/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install

# Created by `pipx` on 2023-12-15 14:31:54
export PATH="$PATH:/home/lasauce6/.local/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
