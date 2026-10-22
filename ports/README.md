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
two local changes, applied to both subports (revisions bumped to 10).
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

### 2. Liquid Glass icon

`files/Emacs.icon` is an Icon Composer document: the white "E" from
upstream's `etc/images/icons/hicolor/scalable/apps/emacs.svg` as a
glass layer over a squircle filled with the icon's purple gradient.
`files/Assets.car` is that document compiled by actool. `post-destroot`
copies the catalog into the bundle and sets `CFBundleIconName`, so
macOS 26+ renders the icon with live glass effects and dark/tinted
variants. The Dock caches icons aggressively: after an upgrade, remove
Emacs from the Dock and add it back.

Recompile after editing the document (actool ships with Xcode, not
the Command Line Tools):

    out=$(mktemp -d)
    DEVELOPER_DIR=/Applications/Xcode.app xcrun actool \
        --app-icon Emacs --platform macosx --minimum-deployment-target 26.0 \
        --output-partial-info-plist /dev/null --compile "$out" files/Emacs.icon
    mv "$out/Assets.car" files/
