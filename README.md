# dotfiles
@saltkid's dotfiles for WSL, Debian unstable. Includes a build script to get
GUI apps working. Has editable package lists to add more packages, zsh plugins,
and nerd fonts on build. 
# Setup
This build script assumes a fresh newly installed Debian on WSL. This is
because when the build fails, the script will try to undo the build process,
which includes the entire `~/.config` directory for example since a fresh
install of Debian on WSL does not have that.

```bash
git clone --recurse-submodules -j8 https://github.com/saltkid/dotfiles.git $HOME/dotfiles
cd $HOME/dotfiles
chmod +x ./scripts/build.sh
./scripts/build.sh
```
Then restart your shell.
```bash
cd $HOME/dotfiles
chmod +x ./scripts/post-build.sh
./scripts/post-build.sh
```
The `post-build.sh` should fix wayland gui apps not working. See the comments
at the end of [this issue](https://github.com/microsoft/wslg/issues/1032). It
is marked as closed but is still relevant today since in my experience, after
restarting wsl with `wsl --shutdown; wsl`, wayland gui apps won't launch
anymore without this workaround.

The build script will always install these packages, regardless of what is
specified in `packages.txt`
1. [`curl`](https://curl.se/docs/manpage.html) and [`gpg`](https://gnupg.org/)
for signing third party apt sources
2. [`mesa-utils`](https://wiki.debian.org/Mesa) for gui apps
2. [`stow`](https://wiki.debian.org/Mesa) for dotfile configs
3. [`uv`](https://github.com/astral-sh/uv) and
[`lazygit`](https://github.com/jesseduffield/lazygit) because both are not in
any apt sources
    - TODO: make these optional (as a part of `packages.txt`) when an apt
    source for these are found
4. [`neovim`](https://github.com/neovim/neovim) because it is outdated in the
official unstable debian source
    -  the executable is installed in `/opt/nvim/bin`
    - TODO: make this optional (as a part of `packages.txt`) when it gets
    updated
5. [`gt`](https://github.com/saltkid/gt) for finding git repos and cd'ing to
them. Might replace this with zoxide after trying it out but this is fine for
my simple workflows for now.

# Editable package lists
Packages must be separated by newline. The order does not matter EXCEPT for
`zsh-plugins.txt` which require syntax highlighting plugins to be last entry.
That's it.
1. `packages.txt`
    - packages installed by apt in the build script.
    - the build script requires `git`, `curl`, `gpg`, and `mesa-utils` so you
    don't need to include those since these will be installed anyway.
2. `nerd-fonts.txt`
    - from the [nerd fonts repo](https://github.com/ryanoasis/nerd-fonts).
    - To know which are the correct nerd font names,
    check the directory names
    [here](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts).
2. `zsh-plugins.txt`
    - only github plugins following the format: `owner/repo_name`.
    - must be plugins that need to be loaded, in which the init script is
    named like: `<plugin_name>.zsh`, `<plugin_name>.plugin.zsh`,
    `<plugin_name>.zsh-theme`, or `<plugin_name>.sh`.
        - this means no frameworks like Oh My Zsh.
