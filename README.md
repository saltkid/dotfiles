# dotfiles
@saltkid's dotfiles. Includes a build script for WSL, Debian unstable to get
GUI apps working. Has editable packages lists to add more packages, zsh
plugins, and nerd fonts on build. 

# Table of Contents
- [Setup](#setup)
    - [Setup from scratch](#setup-from-scratch)
- [Build details](#build-details)
- [Post build details](#post-build-details)
- [Editable packages lists](#editable-packages-lists)

---

# Setup
If you just want the dotfiles, while in the dotfiles repo, do:
```bash
stow --adopt .
git restore . # to overwrite existing configs
```
This dotfiles include build scripts (`./scripts/wsl-debian-build.sh` and
`./scripts/wsl-debian-post-build.sh`) which duplicate my setup from a freshly installed
Debian on WSL
## Setup from scratch
[reference](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux)
1. Activate needed features for WSL

    In an elevated powershell, do
    ```powershell
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestartwsl.exe --install
    ```
2. Install and update [WSL](https://github.com/microsoft/WSL)

    Restart PC to apply changes. In an elevated powershell, do
    ```powershell
    wsl.exe --update
    ```
3. Install Debian

    In a non-elevated powershell, do
    ```powershell
    wsl.exe --set-default-version 2
    wsl.exe --install -d Debian
    ```
    This will launch Debian and prompt to create a user
5. Build my setup
    ```bash
    sudo apt-get install -y git
    git clone --recurse-submodules -j8 https://github.com/saltkid/dotfiles.git $HOME/dotfiles
    cd $HOME/dotfiles
    chmod +x ./scripts/wsl-debian-build.sh
    ./scripts/build.sh
    ```
    Then restart your shell. When the build fails, the script will try to undo
    the build process, where you can try executing `build.sh` again (after
    reading what went wrong of course).
6. Post build

    Restart WSL in powershell:
    ```powershell
    wsl.exe --shutdown; wsl
    ```
    Execute the post build script:
    ```bash
    cd $HOME/dotfiles
    chmod +x ./scripts/wsl-debian-post-build.sh
    ./scripts/post-build.sh
    ```
    Restart your shell again and the gui apps should work now. If you
    didn't edit `packages.txt`, [`wezterm`](https://github.com/wez/wezterm)
    will be installed so try that:
    ```bash
    wezterm
    ```

--- 

# Build details
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

# Post Build details
The `post-build.sh` should fix wayland gui apps not working. See the comments
at the end of [this issue](https://github.com/microsoft/wslg/issues/1032). It
is marked as closed but is still relevant today since in my experience, after
restarting wsl with `wsl --shutdown; wsl`, wayland gui apps won't launch
anymore without this workaround.

# Editable packages lists
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
3. `zsh-plugins.txt`
    - only github plugins following the format: `owner/repo_name`.
    - must be plugins that need to be loaded, in which the init script is
    named like: `<plugin_name>.zsh`, `<plugin_name>.plugin.zsh`,
    `<plugin_name>.zsh-theme`, or `<plugin_name>.sh`.
        - this means no frameworks like Oh My Zsh.
