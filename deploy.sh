#!/usr/bin/env bash

DOTFILES_ROOT="$(dirname "$(realpath "$0")")"

echo "Deploying $DOTFILES_ROOT"

echo "Creating dir ~/.config"
mkdir -p ~/.config || exit 1
echo "Creating dir ~/.local/scripts"
mkdir -p ~/.local/scripts || exit 1

CFG_DIRS=$(ls -ad -- .config/*/)

for dir in $CFG_DIRS; do
	FINAL_DIR="$HOME/$dir"
	echo "Creating dir $FINAL_DIR"
	mkdir -p "$FINAL_DIR" || exit 1
done

echo Stowing all files
stow . || exit 1

echo Done
