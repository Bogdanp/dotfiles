# Locale
set -xg LC_ALL en_US.UTF-8
set -xg LANG en_US.UTF-8


# Path
set -xg GOROOT /usr/local/opt/go/libexec
set -xg GOPATH $HOME/sandbox/gopath

set -xg PATH /usr/local/sbin /usr/local/bin /usr/bin /usr/sbin /bin /sbin $PATH
set -xg PATH $PATH $HOME/.local/bin $HOME/bin $HOME/sandbox/google-cloud-sdk/bin
set -xg PATH $PATH $GOROOT/bin $GOPATH/bin
set -xg MANPATH /usr/share/man /usr/local/share/man /opt/X11/share/man /usr/local/MacGPG2/share/man /Library/TeX/Distributions/.DefaultTeX/Contents/Man
set -xg RUST_SRC_PATH $HOME/sandbox/rust/src


# Env
set -xg EDITOR ec


# fzf
set -xg FZF_DEFAULT_COMMAND 'find * -name "*.pyc" -prune -o -name .git -prune -o -name .cache -prune -o -name Applications -prune -o -type f -print -o -type d -print -o -type l -print'
set -xg FZF_DEFAULT_OPTS "--height 60% --reverse"
set -xg FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -xg FZF_TMUX 0


# Aliases
alias sbcl="rlwrap ros run"
alias g=git
alias w=workon


# Python
set -xg PYTHONSTARTUP $HOME/.pythonrc.py

# Inlined output from (python -m virtualfish) for faster startup times:
set -g VIRTUALFISH_VERSION 1.0.5
set -g VIRTUALFISH_PYTHON_EXEC /usr/local/opt/python/bin/python2.7
. /usr/local/lib/python2.7/site-packages/virtualfish/virtual.fish
emit virtualfish_did_setup_plugins


# Manta
set -xg MANTA_URL https://us-east.manta.joyent.com
set -xg MANTA_USER bogdanp
set -xg MANTA_KEY_ID (ssh-keygen -l -f $HOME/.ssh/id_rsa.pub | awk '{print $2}')
