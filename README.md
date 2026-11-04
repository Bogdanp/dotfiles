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

### Spaces app assignments

`bootstrap.sh` restores the assignments saved in `spaces-app-bindings.json`.
You can also run the restore manually after connecting or disconnecting a display:

```sh
python3 bin/spaces-app-bindings.py restore --dry-run
python3 bin/spaces-app-bindings.py restore
```

Assignments use display roles and desktop numbers, resolved against the live
WindowServer layout. Saved macOS preferences can still list unplugged displays,
so they are not used to decide which desktops are currently available.

With one display, every app uses that display and its saved desktop number.
An optional `single_desktop` overrides the number in single-monitor mode:
Codex uses Desktop 3 alone, and secondary-display Desktop 1 with two monitors.
Create the required desktops in Mission Control first (this configuration needs
five). If a target is unavailable or ambiguous, restore exits before writing.
Restore merges the assignments with existing ones and restarts Dock to apply them;
it does not run automatically when monitors change.

To update the backup from current assignments:

```sh
python3 bin/spaces-app-bindings.py backup
```

When updating an existing backup, single-monitor backups retain the saved
multi-monitor targets and update `single_desktop`; multi-monitor backups retain
existing single-monitor overrides. A new backup made with one display has only
main-display targets until you configure the multi-monitor layout.

Live layout detection uses macOS's private SkyLight API and fails without writing
if that API is unavailable. No extra Python packages are required.

Regression tests (no preference writes):

```sh
python3 -B -m unittest discover -s tests -p 'test_spaces_app_bindings.py'
```
