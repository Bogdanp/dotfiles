# Locale
set -xg LC_ALL en_US.UTF-8
set -xg LANG en_US.UTF-8


# Path
set -xg PATH /usr/local/sbin /usr/local/bin /usr/bin /usr/sbin /bin /sbin $PATH
set -xg PATH $PATH "/usr/local/opt/go@1.13/bin"
set -xg PATH $PATH $HOME/.local/bin $HOME/bin
set -xg PATH $PATH $HOME/.config/yarn/global/node_modules/.bin
set -xg PATH $PATH $HOME/.gem/ruby/2.6.0/bin
set -xg PATH $PATH $HOME/sandbox/golang/bin
set -xg PATH $PATH $HOME/Library/Racket/7.5/bin
set -xg MANPATH /usr/share/man /usr/local/share/man /opt/X11/share/man /usr/local/MacGPG2/share/man /Library/TeX/Distributions/.DefaultTeX/Contents/Man
set -xg GOPATH $HOME/sandbox/golang


# Env
set -xg EDITOR ec


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
