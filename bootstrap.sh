#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)

log() {
    printf "[%s] %s\n" "$(date)" "$@"
}

link() {
    if [ "$#" -ne 2 ]; then
        echo "usage: link SRC DST"
        exit 1
    fi

    SRC="$ROOT/$1"
    DST="$2"
    log "Linking '$SRC' to '$DST'..."
    if [ "$DRY_RUN" -eq 0 ]; then
        ln -sf "$SRC" "$DST"
    fi
}

load_agent() {
    if [ "$#" -ne 1 ]; then
        echo "usage: load_agent NAME"
        exit 1
    fi

    AGENT="$1"
    AGENT_PATH="$HOME/Library/LaunchAgents/$AGENT.plist"
    log "Loading LaunchAgent '$AGENT'..."
    if [ "$DRY_RUN" -eq 0 ]; then
        if launchctl stop "$AGENT"; then
            launchctl unload "$AGENT_PATH"
        fi
        launchctl load "$AGENT_PATH"
        launchctl start "$AGENT"
    fi
}

install_agent() {
    if [ "$#" -ne 1 ]; then
        echo "usage: install_agent NAME"
        exit 1
    fi

    mkdir -p "$HOME/Library/LaunchAgents"
    link "agents/$1.plist" "$HOME/Library/LaunchAgents/"
    load_agent "$1"
}

remove() {
    if [ "$#" -ne 1 ]; then
        echo "usage: remove PATH"
        exit 1
    fi

    if [ -f "$1" ]; then
        log "Removing '$1'..."
        if [ "$DRY_RUN" -eq 0 ]; then
            rm -rf "$1"
        fi
    fi
}

DRY_RUN=0

while getopts ":d" arg; do
    case "$arg" in
        d)
            DRY_RUN=1
            ;;
        *)
            echo "usage: bootstrap [-d]"
            exit 1
    esac
done

if [ "$DRY_RUN" -eq 1 ]; then
    log "Doing a dry run..."
fi


## Packages

log "Creating workspace..."
mkdir -p "$ROOT/workspace"

log "Logging installed pkgs..."
port installed > "$ROOT/workspace/installed"

log "Clearing failures..."
if [ "$DRY_RUN" -eq 0 ]; then
    if [ -f "$ROOT/workspace/failures" ]; then
        echo "" > "$ROOT/workspace/failures"
    fi
fi

log "Installing pkgs..."
while IFS= read -r PKG_AND_OPTS; do
    PKG=$(echo "$PKG_AND_OPTS" | cut -d' ' -f1)
    if ! grep -q "$PKG" "$ROOT/workspace/installed"; then
        log "Installing $PKG..."
        if [ "$DRY_RUN" -eq 0 ]; then
            if ! sudo port install $PKG_AND_OPTS 2>"$ROOT/workspace/errors.$PKG"; then
                echo "$PKG" >> "$ROOT/workspace/failures"
            fi
        fi
    fi
done < "$ROOT/packages"


## Shell and dotfiles

log "Changing shell to Fish..."
if [ "$DRY_RUN" -eq 0 ]; then
    sudo chsh -s /opt/local/bin/fish
fi

log "Linking dotfiles..."
mkdir -p "$HOME/.gnupg"
mkdir -p "$HOME/.config/fish/functions"
link "amethystrc" "$HOME/.amethyst"
link "bashrc" "$HOME/.bashrc"
remove "$HOME/.config/fish"
link "fish" "$HOME/.config"
link "gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
link "mbsyncrc" "$HOME/.mbsyncrc"
link "msmtprc" "$HOME/.msmtprc"
link "psqlrc" "$HOME/.psqlrc"
remove "$HOME/.tmux"
link "tmux" "$HOME/.tmux"
link "tmux.conf" "$HOME/.tmux.conf"
link "vimrc" "$HOME/.vimrc"


## Key bindings

log "Installing keybindings..."
mkdir -p "$HOME/Library/KeyBindings"
link "DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/"


## Emacs


## Git

log "Linking gitignore and gitconfig..."
link gitignore ~/.gitignore
link gitconfig ~/.gitconfig


## Fava

log "Installing fava launch agent..."
install_agent "io.defn.fava"


## Tarsnap

log "Linking tarsnap.conf..."
if [ "$DRY_RUN" -eq 0 ]; then
    sudo ln -sf "$ROOT/tarsnap.conf" "/opt/local/etc/"
fi

log "Installing tarsnap scripts..."
if [ "$DRY_RUN" -eq 0 ]; then
    sudo ln -sf "$ROOT/bin/tarsnap-perform-backup" "/opt/local/bin/"
fi

install_agent "io.defn.tarsnap-backup"
