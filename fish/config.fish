# Locale
set -xg LC_ALL en_US.UTF-8
set -xg LANG en_US.UTF-8


# Paths
set -xg PATH /opt/local/bin /usr/local/bin /usr/bin /usr/sbin /bin /sbin $PATH
set -xg PATH $PATH $HOME/bin $HOME/Library/Python/3.11/bin /opt/local/Library/Frameworks/Python.framework/Versions/3.10/bin $HOME/.cargo/bin
set -xg MANPATH /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/share/man /opt/local/man /usr/share/man /usr/local/share/man


# Env
set -xg CLICOLOR x
set -xg EDITOR emacsclient


# Aliases
alias g=git
alias w=workon


# Python
set -xg WORKON_HOME $HOME/.virtualenvs


# GPG
set -xg GPG_TTY (tty)


# Theme
set fish_color_search_match --background='#f5f5f5'
set fish_pager_color_prefix '#ff0000' --underline
set fish_pager_color_progress '#ffffff' --background='#ff0000'
set fish_pager_color_description '#948c94' --background='#ffffff'
