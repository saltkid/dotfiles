#!/bin/bash
# ASSUMES:
# - Debian
# - git already installed
# Always installed packages 
# - curl and gpg (third party repo signing)
# - mesa-utils (get gui apps to work)
# - stow (dotfile configs)

DOTFILES_DIR=$(dirname $(dirname $(realpath $0)))

function _unset_build_vars() {
  unset DOTFILES_DIR packages zsh_plugins zsh_plugin nerd_fonts nerd_font
}

function _build_failed {
  sudo rm /etc/apt/sources.list 2>/dev/null
  sudo mv /etc/apt/sources.list.bak /etc/apt/sources.list 2>/dev/null
  sudo rm -f /etc/apt/keyrings/wezterm-fury.gpg 2>/dev/null
  sudo rm -f /etc/apt/sources.list.d/wezterm.list 2>/dev/null
  uv cache clean 2>/dev/null
  rm -rf ~/source ~/projects ~/work ~/.config ~/.zsh_plugins ~/.local \
  "$(uv python dir)" "$(uv tool dir)" /usr/local/bin/lazygit /opt/nvim \
  ~/lazygit.tar.gz ~/lazygit 2>/dev/null
  for nerd_font in $(< $DOTFILES_DIR/nerd-fonts.txt); do
    rm ~/$nerd_font.tar.xz 2>/dev/null
  done
  sudo apt-get purge -y curl gpg mesa-utils stow 2>/dev/null
  sudo apt-get purge -y $(< $DOTFILES_DIR/wsl-debian-packages.txt) 2>/dev/null
  sudo apt-get autoremove -y 2>/dev/null
  sudo apt-get update && \
  sudo apt-get -y upgrade && \
  sudo apt-get -y dist-upgrade
  cd $DOTFILES_DIR
  stow . --delete
  cd $HOME
  _unset_build_vars
  exit 1
}

# REPO SETUP {{{
# for signing third party sources
sudo apt-get install -y curl gpg && \

# Debian unstable
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
echo "deb http://deb.debian.org/debian/ unstable main
deb-src http://deb.debian.org/debian/ unstable main" | sudo tee /etc/apt/sources.list
if [ $? -ne 0 ]; then
  echo "Failed to write to apt sources to upgrade to debian unstable"
  _build_failed
fi

# wezterm repo
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg && \
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
if [ $? -ne 0 ]; then
  echo "Failed to sign and create wezterm apt source"
  _build_failed
fi

# update sources
sudo apt-get update && \
sudo apt-get -y upgrade && \
sudo apt-get -y dist-upgrade
if [ $? -ne 0 ]; then
  echo "Failed to perform distribution upgrade."
  _build_failed
fi

# setup initial dirs
mkdir ~/source ~/projects ~/work ~/.config
# }}}

# INSTALL PACKAGES {{{
# minimum required to get gui apps working
# source: https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux
# and stow for dotfile configs
sudo apt-get install -y mesa-utils stow && \

# user packages
sudo apt-get install -y $(< $DOTFILES_DIR/wsl-debian-packages.txt) && \
sudo apt-get -y autoremove
if [ $? -ne 0 ]; then
  echo "Failed to install required and user packages"
  _build_failed
fi
# }}}

# INSTALL ZSH PLUGINS {{{
# based on u/colemaker360's snippet
# https://www.reddit.com/r/zsh/comments/dlmf7r/manually_setup_plugins/
for zsh_plugin in $(< $DOTFILES_DIR/zsh-plugins.txt); do
  if [[ ! -d ${ZDOTDIR:-$HOME}/.zsh_plugins/$zsh_plugin ]]; then
    mkdir -p ${ZDOTDIR:-$HOME}/.zsh_plugins/${zsh_plugin%/*} && \
    git clone --depth 1 --recurse-submodules -j8 https://github.com/$zsh_plugin.git ${ZDOTDIR:-$HOME}/.zsh_plugins/$zsh_plugin
    if [ $? -ne 0 ]; then
      echo "Failed to install zsh plugin: $zsh_plugin"
      _build_failed
    fi
  fi
done
# }}}

# INSTALL NERD FONTS {{{
mkdir -p ~/.local/share/fonts/
for nerd_font in $(< $DOTFILES_DIR/nerd-fonts.txt); do
  curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$nerd_font.tar.xz && \
  tar xf $nerd_font.tar.xz -C ~/.local/share/fonts/ && \
  rm $nerd_font.tar.xz
  if [ $? -ne 0 ]; then
    echo "Failed to install nerd font: $nerd_font"
    _build_failed
  fi
done
# }}}

# INSTALL PACKAGES NOT IN REPOS {{{
# TODO: UV (not in any apt sources)
curl -LsSf https://astral.sh/uv/install.sh | sh
if [ $? -ne 0 ]; then
  echo "Failed to install uv"
  _build_failed
fi

# TODO: NEOVIM (outdated in debian repos)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz && \
sudo rm -rf /opt/nvim && \
sudo mkdir -p /opt/nvim && \
sudo tar -C /opt/nvim -xzf nvim-linux64.tar.gz --strip-components=1 && \
rm nvim-linux64.tar.gz
if [ $? -ne 0 ]; then
  echo "Failed to install neovim"
  _build_failed
fi

# TODO: LAZYGIT (not in any apt sources)
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*') && \
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
tar xf lazygit.tar.gz lazygit && \
sudo install lazygit -D -t /usr/local/bin/ && \
rm lazygit lazygit.tar.gz && \
unset LAZYGIT_VERSION
if [ $? -ne 0 ]; then
  echo "Failed to install lazygit"
  _build_failed
fi

# GT FOR FZFCD
git clone git@github.com-saltkid:saltkid/gt.git ~/projects/etc/gt
if [ $? -ne 0 ]; then
  echo "Failed to clone saltkid/gt"
  _build_failed
fi
# }}}

# WSL WAYLAND ISSUE SOLUTION {{{
# If in WSL, do workaround for this wayland issue:
# https://github.com/microsoft/wslg/issues/1032
if [[ -n $WSLENV ]]; then
    # TEMPORARY FIX: wayland gui apps not launching after wsl --shutdown or
    # --update
    mkdir -p ~/.config/user-tmpfiles.d && \
    cat <<'EOF' > ~/.config/user-tmpfiles.d/wsl-symlinks.conf
# Type Path                              Mode User Group Age Argument
L+    %t/.X11-unix/X0                    -    -    -     -   /mnt/wslg/.X11-unix/X0
L+    %t/wayland-0                       -    -    -     -   /mnt/wslg/runtime-dir/wayland-0
L+    %t/wayland-0.lock                  -    -    -     -   /mnt/wslg/runtime-dir/wayland-0.lock
L+    %t/pulse                           -    -    -     -   /mnt/wslg/runtime-dir/pulse
EOF
    if [ $? -ne 0 ]; then
      echo "Failed to make a tempfile for the workaround for wayland gui apps"
      _build_failed
    fi
fi
# }}}

# FINISH {{{
chsh -s $(which zsh) $USER
# initialize dotfiles
cd $DOTFILES_DIR
stow . --adopt
git restore . # remove adopted changes
cd $HOME
_unset_build_vars
# }}}
