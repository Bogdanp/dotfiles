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


# Python
set -xg PYTHONSTARTUP $HOME/.pythonrc.py


# Dinghy
set -xg DOCKER_HOST tcp://192.168.99.100:2376
set -xg DOCKER_CERT_PATH $HOME/.docker/machine/machines/dinghy
set -xg DOCKER_TLS_VERIFY 1
set -xg DOCKER_MACHINE_NAME dinghy


# Aliases
alias sbcl="rlwrap ros run"
alias g=git
alias w=workon


# Python
python -m virtualfish | source
