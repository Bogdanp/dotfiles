# Locale
set -xg LC_ALL en_US.UTF-8
set -xg LANG en_US.UTF-8


# Path
set -xg PATH /usr/local/sbin /usr/local/bin /usr/bin /usr/sbin /bin /sbin $PATH
set -xg PATH $PATH $HOME/.local/bin $HOME/bin
set -xg PATH $PATH $HOME/.config/yarn/global/node_modules/.bin
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


# Virtualfish
#   Inlined output from (python -m virtualfish) for faster startup times:
set -g VIRTUALFISH_VERSION 1.0.6
set -g VIRTUALFISH_PYTHON_EXEC /usr/local/opt/python/bin/python3.7
source /usr/local/lib/python3.7/site-packages/virtualfish/virtual.fish
emit virtualfish_did_setup_plugins


# GPG
set -xg GPG_TTY (tty)
