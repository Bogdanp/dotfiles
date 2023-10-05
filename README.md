# dotfiles

## Prerequisites

Make sure the machine has a unique network name (System Settings ->
Sharing -> Local Hostname).

## Setup

1. Install [MacPorts].
1. `sudo port install git`
1. `git clone git@github.com/Bogdanp/dotfiles sandbox/dotfiles`
1. `git submodule update --init`
1. `./bootstrap -d`

## How Stuff Works

### Email

Email is synced via [isync] and sent via [msmtp], both of these use
the OS X keychain for password management.

## Quirks

See `~/.local/var/log` for launch agent logs.

### `io.defn.git-personal.plist` agent

The folder this operates on lives in `~/Documents`, so it won't have
access unless `zsh` is granted full disk access from System Settings.

### External Displays

From the "Arrange..." menu of the "Displays" section of System Settings,
move the menu bar to the external display to have spaces automatically
migrate to the external display when it's plugged in.


[MacPorts]: https://www.macports.org
[isync]: http://isync.sourceforge.net/
[msmtp]: https://marlam.de/msmtp/
