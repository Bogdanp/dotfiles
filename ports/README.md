# Local MacPorts overlay

This directory is a local MacPorts port tree. It is listed first in
`/opt/local/etc/macports/sources.conf`, so ports here shadow the
official tree. The `PortIndex` files are generated and gitignored;
`bootstrap.sh` runs `portindex` here, and you must rerun it yourself
after changing a Portfile.

MacPorts reads this tree as the `macports` user, so `$HOME`
needs a search-only ACL for it (`chmod +a "macports allow search" ~`).
`bootstrap.sh` adds it.

## aqua/emacs-mac-app

Copy of the official `emacs-mac-app` Portfile (and its `files/`) with
two local changes, applied to both subports (revisions bumped to 9).
Install with `sudo port -N install emacs-mac-app-devel -nativecomp`.

### 1. `LSEnvironment` sets `EMACS_REINVOKED_FROM_SHELL=1`

When Emacs is launched by Finder, the Dock or Raycast there is no
`SHLVL` in its environment, so emacs-mac re-execs itself through
`Contents/MacOS/Emacs.sh` and a login shell to pick up the shell
environment. On macOS 27 LaunchServices drops the pid of an app that
re-exec'd itself (`LSApplicationHasReExecedItselfKey`, no `pid`),
`NSRunningApplication.processIdentifier` reports -1, and Amethyst,
which keys every application on that value, never sees the app and
never tiles it. Terminal launches have `SHLVL` and skip the re-exec.
Presetting the guard variable through `LSEnvironment` skips the
re-exec for LaunchServices launches too. PATH still gets
`${prefix}/bin` from the port's `emacs.c` patch; the rest of the shell
environment comes from exec-path-from-shell in init.el.

### 2. Finder custom icon

`post-activate` assigns `files/Emacs-padded.icns` as a Finder custom
icon (an `Icon\r` resource file plus the custom-icon flag), and
`pre-deactivate` removes it. macOS 26+ draws an app's bundled icon
inside a squircle but draws custom icons in their original shape, so
this keeps the classic Emacs icon. The Dock caches icons aggressively:
after an upgrade, remove Emacs from the Dock and add it back.

`Emacs-padded.icns` is the bundle's own `Emacs.icns` with the artwork
scaled to 824/1024 of the canvas, the margin Apple's icon grid uses;
the raw artwork fills the canvas and looks oversized in the Dock and
the app switcher. Regenerate it after an upstream icon change:

    swiftc -O -o pad-icon files/pad-icon.swift
    ./pad-icon /Applications/MacPorts/EmacsMac.app/Contents/Resources/Emacs.icns Emacs.iconset 824
    iconutil -c icns Emacs.iconset -o files/Emacs-padded.icns
