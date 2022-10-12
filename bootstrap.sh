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

render() {
    if [ "$#" -lt 1 ]; then
        echo "usage: render NAME [VAR ...]"
        exit 1
    fi

    NAME="$1"
    SRC="$ROOT/$NAME.tpl"
    DST="$ROOT/$NAME"
    if [ ! -f "$SRC" ]; then
        echo "error: $SRC does not exist"
        exit 1
    fi

    shift
    log "Templating '$SRC' to '$DST' with vars '$*'..."
    if [ "$DRY_RUN" -eq 0 ]; then
        envsubst "$@" < "$SRC" > "$DST"
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

    log "Removing '$1'..."
    if [ "$DRY_RUN" -eq 0 ]; then
        rm -rf "$1"
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
                log "Failed to install $PKG, see '$ROOT/workspace/errors.$PKG' for details..."
                echo "$PKG" >> "$ROOT/workspace/failures"
            fi
        fi
    fi
done < "$ROOT/packages"


## Shell and dotfiles

log "Changing shell to Fish..."
if [ "$DRY_RUN" -eq 0 ]; then
    if ! grep -q "/opt/local/bin/fish" "/etc/shells"; then
        log "Adding /opt/local/bin/fish to /etc/shells..."
        echo "/opt/local/bin/fish" | sudo tee -a "/etc/shells"
    fi

    sudo chsh -s /opt/local/bin/fish
    chsh -s /opt/local/bin/fish
fi

log "Linking dotfiles..."
mkdir -p "$HOME/.gnupg"
mkdir -p "$HOME/.local"
remove "$HOME/.config/fish"
remove "$HOME/.tmux"
link "amethyst.yml " "$HOME/.amethyst.yml"
link "bashrc" "$HOME/.bashrc"
link "fish" "$HOME/.config/fish"
link "gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
link "mbsyncrc" "$HOME/.mbsyncrc"
link "msmtprc" "$HOME/.msmtprc"
link "psqlrc" "$HOME/.psqlrc"
link "tmux" "$HOME/.tmux"
link "tmux.conf" "$HOME/.tmux.conf"
link "vimrc" "$HOME/.vimrc"


## Key bindings

log "Installing keybindings..."
mkdir -p "$HOME/Library/KeyBindings"
link "DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/"


## Emacs

if [ ! -d "$HOME/.emacs.d" ]; then
    log "Cloning .emacs.d..."
    if [ "$DRY_RUN" -eq 0 ]; then
        git clone https://github.com/Bogdanp/.emacs.d "$HOME/.emacs.d"

        log "Loading Emacs submodules..."
        (cd "$HOME/.emacs.d" && \
             git submodule update --init)

        log "Fixing up .emacs.d origin repo..."
        (cd "$HOME/.emacs.d" && \
             git remote rm origin && \
             git remote add origin git@github.com:Bogdanp/.emacs.d)
    fi
fi

if [ ! -f "$HOME/bin/emacsclient" ]; then
    log "Linking emacslient..."
    mkdir -p ~/bin
    ln -sf "/Applications/MacPorts/EmacsMac.app/Contents/MacOS/bin/emacsclient" "$HOME/bin/emacsclient"
fi


## Git

log "Linking gitignore and gitconfig..."
link gitignore ~/.gitignore
link gitconfig ~/.gitconfig


## Yubikey

log "Installing yubikey-agent launch agent..."
mkdir -p ~/.local/var/run
render "agents/io.defn.yubikey-agent.plist" '$HOME'
install_agent "io.defn.yubikey-agent"


## Fava

log "Installing fava launch agent..."
render "agents/io.defn.fava.plist" '$HOME'
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

render "agents/io.defn.tarsnap-backup.plist" '$HOME'
install_agent "io.defn.tarsnap-backup"


## Notes & accounting agents

log "Installing git-personal launch agent..."
render "agents/io.defn.git-personal.plist" '$HOME'
install_agent "io.defn.git-personal"

log "Installing git-accounting launch agent..."
render "agents/io.defn.git-accounting.plist" '$HOME'
install_agent "io.defn.git-accounting"


## Nginx

log "Copying /etc/hosts..."
if [ "$DRY_RUN" -eq 0 ]; then
    sudo cp "$ROOT/etc/hosts" "/etc/hosts"
fi

log "Linking Nginx configs..."
if [ "$DRY_RUN" -eq 0 ]; then
    sudo rm -rf "/opt/local/etc/nginx/hosts"
    sudo ln -sf "$ROOT/etc/nginx/nginx.conf" "/opt/local/etc/nginx/nginx.conf"
    sudo ln -sf "$ROOT/etc/nginx/hosts" "/opt/local/etc/nginx/hosts"
fi

log "Loading Nginx agent..."
if [ "$DRY_RUN" -eq 0 ]; then
    sudo port load nginx
fi


## PostgreSQL

if [ ! -d "/opt/local/var/db/postgresql13/defaultdb" ]; then
    log "Setting up PostgreSQL database..."
    if [ "$DRY_RUN" -eq 0 ]; then
        sudo mkdir -p /opt/local/var/db/postgresql13/defaultdb
        sudo chown postgres:postgres /opt/local/var/db/postgresql13/defaultdb
        sudo su postgres -c 'cd /opt/local/var/db/postgresql13 && /opt/local/lib/postgresql13/bin/initdb -D /opt/local/var/db/postgresql13/defaultdb'
    fi

    log "Loading PostgreSQL agent..."
    if [ "$DRY_RUN" -eq 0 ]; then
        sudo port load postgresql13-server
    fi
fi

log "Selecting PostgreSQL version..."
if [ "$DRY_RUN" -eq 0 ]; then
    sudo port select postgresql postgresql13
fi


## MacPorts

log "Linking MacPorts sources..."
render "etc/macports/sources.conf" '$HOME'
if [ "$DRY_RUN" -eq 0 ]; then
    sudo ln -sf "$ROOT/etc/macports/sources.conf" "/opt/local/etc/macports/sources.conf"
fi


## Python

log "Selecting Python version..."
if [ "$DRY_RUN" -eq 0 ]; then
    sudo port select python python38
    sudo port select pip pip38
fi

log "Installing pip packages..."
while IFS= read -r PKG; do
    if ! grep -q "$PKG" "$ROOT/workspace/installed-pip"; then
        log "Installing $PKG (pip)..."
        if [ "$DRY_RUN" -eq 0 ]; then
            if ! sudo pip install "$PKG" 2>"$ROOT/workspace/errors.$PKG"; then
                log "Failed to install $PKG, see '$ROOT/workspace/errors.$PKG' for details..."
                echo "$PKG" >> "$ROOT/workspace/failures-pip"
            fi
        fi
    fi
done < "$ROOT/packages-pip"


## SSL

log "Linking ca-certificates..."
if [ "$DRY_RUN" -eq 0 ]; then
    sudo ln -sf /Library/Python/3.8/site-packages/certifi/cacert.pem /etc/ssl/certs/ca-certificates.crt
fi
