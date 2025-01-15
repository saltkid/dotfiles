#!/bin/sh
# ASSUMES:
# - Debian
# - git already installed
# Always installed packages 
# - curl (third party repo signing)
# - gpg (third party repo signing)
# - mesa-utils (get gui apps to work)
# - firefox-esr-l10n-nb-no (test gui functionality)

# REPO SETUP {{{
# Debian unstable
echo "deb http://deb.debian.org/debian/ unstable main
deb-src http://deb.debian.org/debian/ unstable main" | sudo tee /etc/apt/sources.list
# wezterm repo
sudo apt install -y curl gpg
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y

# setup initial dirs
mkdir ~/source ~/projects ~/work ~/.config

# }}}

# INSTALL PACKAGES {{{
# minimum required to get gui apps working
# source: https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux
sudo apt install -y mesa-utils firefox-esr-l10n-nb-no
# user packages
sudo apt install -y $(<../packages.txt)
sudo apt autoremove -y
# }}}

# INSTALL ZSH PLUGINS {{{
# based on u/colemaker360's snippet
# https://www.reddit.com/r/zsh/comments/dlmf7r/manually_setup_plugins/
for zsh_plugin in $(<../zsh-plugins.txt); do
  if [[ ! -d ${ZDOTDIR:-$HOME}/.zsh_plugins/$zsh_plugin ]]; then
    mkdir -p ${ZDOTDIR:-$HOME}/.zsh_plugins/${zsh_plugin%/*}
    git clone --depth 1 --recurse-submodules -j8 https://github.com/$zsh_plugin.git ${ZDOTDIR:-$HOME}/.zsh_plugins/$zsh_plugin
  fi
done
# }}}

# INSTALL NERD FONTS {{{
mkdir -p ~/.local/share/fonts/
for nerd_font in $(<../nerd-fonts.txt); do
  curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$nerd_font.tar.xz && \
  tar xf $nerd_font.tar.xz -C ~/.local/share/fonts/ && \
  rm $nerd_font.tar.xz
done
# }}}

# INSTALL PACKAGES NOT IN REPOS {{{
# TODO: UV (not in any apt sources)
curl -LsSf https://astral.sh/uv/install.sh | sh

# TODO: NEOVIM (outdated in debian repos)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz && \
sudo rm -rf /opt/nvim && \
sudo mkdir -p /opt/nvim && \
sudo tar -C /opt/nvim -xzf nvim-linux64.tar.gz --strip-components=1 && \
rm nvim-linux64.tar.gz

# TODO: LAZYGIT (not in any apt sources)
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*') && \
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
tar xf lazygit.tar.gz lazygit && \
sudo install lazygit -D -t /usr/local/bin/ && \
rm lazygit lazygit.tar.gz && \
unset LAZYGIT_VERSION

# GT FOR FZFCD
git clone git@github.com-saltkid:saltkid/gt.git ~/projects/etc/gt
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
fi
# }}}

# FINISH {{{
unset packages zsh_plugins zsh_plugin nerd_fonts nerd_font
chsh -s $(which zsh) $USER
# initialize dotfiles
cd $HOME/dotfiles
stow . --adopt
git restore . # remove adopted changes
cd $HOME
# }}}
