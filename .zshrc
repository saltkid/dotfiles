# initialize completions {{{
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit
compinit
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# }}}

# PATH {{{
path+=("/usr/local/go/bin")
path+=("$HOME/projects/etc/gt")
export PATH
# }}}

# INTERACTIVE SOURCES {{{
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# }}}

# ALIASES {{{
alias lg="lazygit"
alias l="ls"
alias ll="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias v="nvim"
alias v.="nvim ."
alias plugpull="find ${ZDOTDIR:-$HOME}/.zsh_plugins -type d -exec test -e \"{}/.git\" \";\" -print0 | xargs -I {} -0 git -C {} pull"
# }}}

# FUNCTIONS {{{
function git-check() {
  git config user.name
  git config user.email
  git config user.signingkey
}
function git-clear() {
  git config user.name ""
  git config user.email ""
  git config user.signingkey ""
}
function git-setup() {
  username=$(git ls-remote --get-url origin | cut -d@ -f2 | cut -d: -f1)
  if [[ -z "$username" ]]; then
    echo 'No username found in remote.origin.url. expected format is "git@username:repo_owner/repo.git"'
    echo "Please enter a username:"
    read -r username
  else
    echo "Username found: $username"
  fi
  ssh_key_file="$HOME/.ssh/$username.pub"
  if [[ -f "$ssh_key_file" ]]; then
    email=$(tail -n 1 "$ssh_key_file" | awk '{print $NF}')
    echo "Email found: $email"
  else
    echo "No SSH public key found for $username. Please enter an email:"
    read -r email
  fi
  signingkey=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -B 2 "$username.*<$email>" | grep -oP 'rsa4096\/\K[A-F0-9]{16}')
  if [[ -z "$signingkey" ]]; then
    echo "No signing key found for $username. Please enter a signing key:"
    read -r signing_key
  else
    echo "Signing key found: $signingkey"
  fi
  git config user.name "$username"
  git config user.email "$email"
  git config user.signingkey "$signingkey"
  unset username
  unset email
  unset ssh_key_file
  unset signing_key
}

function __gt_integ() {
  source gt -f
  zle accept-line
}
# }}}

# KEYBINDS {{{
zle -N __gt_integ

bindkey '^F' __gt_integ
bindkey -s '^T' 'tbg run -r -p list-4\n'
# }}}

# install zsh plugins {{{
# credits: thank you u/colemaker360
# https://www.reddit.com/r/zsh/comments/dlmf7r/manually_setup_plugins/
# removed some plugins I think I would not need and added p10k
# assumes github and slash separated plugin names
github_plugins=(
  romkatv/powerlevel10k
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-history-substring-search
  # must be last
  z-shell/F-Sy-H
)
for plugin in $github_plugins; do
  # clone the plugin from github if it does not exist
  if [[ ! -d ${ZDOTDIR:-$HOME}/.zsh_plugins/$plugin ]]; then
    mkdir -p ${ZDOTDIR:-$HOME}/.zsh_plugins/${plugin%/*}
    git clone --depth 1 --recursive https://github.com/$plugin.git ${ZDOTDIR:-$HOME}/.zsh_plugins/$plugin
  fi
  # load the plugin
  for initscript in ${plugin#*/}.zsh ${plugin#*/}.plugin.zsh ${plugin#*/}.zsh-theme ${plugin#*/}.sh; do
    if [[ -f ${ZDOTDIR:-$HOME}/.zsh_plugins/$plugin/$initscript ]]; then
      source ${ZDOTDIR:-$HOME}/.zsh_plugins/$plugin/$initscript
      break
    fi
  done
done
fpath=(${ZDOTDIR:-$HOME}/.zsh_plugins/zsh-users/zsh-completions/src $fpath)
[[ ! -f ${ZDOTDIR:-$HOME}/.p10k.zsh ]] || source ${ZDOTDIR:-$HOME}/.p10k.zsh
# clean up
unset github_plugins
unset plugin
unset initscript
# }}}
