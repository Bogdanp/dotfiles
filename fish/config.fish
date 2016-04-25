# Fisherman
set fisher_home ~/.local/share/fisherman
set fisher_config ~/.config/fisherman
source $fisher_home/config.fish

# Locale
set -xg LC_ALL en_US.UTF-8
set -xg LANG en_US.UTF-8

# Path
set -xg GHC_PATH /Applications/ghc-7.10.2.app/Contents/bin
set -xg TEX_PATH /usr/local/texlive/2015/bin/x86_64-darwin

set -xg GOGAE /usr/local/opt/go_appengine
set -xg GOROOT /usr/local/opt/go/libexec
set -xg GOPATH $HOME/sandbox/gopath

set -xg PATH /usr/local/sbin /usr/local/bin /usr/bin /usr/sbin /bin /sbin $PATH
set -xg PATH $HOME/.local/bin $HOME/.rvm/bin $GHC_PATH $TEX_PATH $PATH
set -xg PATH $PATH /usr/local/share/npm/bin
set -xg PATH $PATH /usr/local/google-cloud-sdk/bin
set -xg PATH $PATH $HOME/bin
set -xg PATH $PATH $HOME/.cargo/bin
set -xg PATH $PATH $GOROOT/bin $GOPATH/bin $GOGAE
set -xg PATH /usr/local/php5/bin $HOME/.composer/vendor/bin $PATH
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
alias vi=vim
alias e="open -a Emacs"
alias ec="emacsclient -n"
alias w=workon


# Fish
set fish_greeting


# Private
source $HOME/.config/fish/private.fish; or true


# Ocaml
source $HOME/.opam/opam-init/init.fish; or true


# Python
eval (python -m virtualfish)
