# PC dotfiles

## Installation

This installation requires the following packages:

```bash
sudo zypper in \
         fastfetch \
         zoxide \
         fzf \
         tealdeer \
         hyprland \
         gdm \
         hyprland-guiutils \
         nwg-displays \
         dmenu \
         rofi \
         tmux \
         rg \
         ripgrep \
         vscode \
         code \
         hyprlock \
         fzf \
         nwg-look \
         gcc \
         libopenssl-devel \
         alsa \
         alsa-devel \
         btop \
         steam \
         jp2a \
         rg \
         neovim \
         ghostty \
         cowsay \
         git \
         cmake \
         go \
         tree-sitter-cli \
         lazygit \
         wl-clipboard \
         zsh \
         stow
```

## Installing nvidia drivers

```bash
sudo zypper install openSUSE-repos-Tumbleweed-NVIDIA
```

```bash
sudo zypper in nvidia-open-driver-G07-signed-kmp-meta
```

## Installing gruvbox GTK theme

```bash
git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git
cd Gruvbox-GTK-Theme/themes
./install.sh

sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons
flatpak override --user --filesystem=xdg-config/gtk-4.0
sudo flatpak override --filesystem=xdg-config/gtk-4.0
```
