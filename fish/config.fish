# Locale
set -xg LC_ALL en_US.UTF-8
set -xg LANG en_US.UTF-8

# Path
set -xg GHC_PATH /Applications/ghc-7.10.2.app/Contents/bin
set -xg TEX_PATH /usr/local/texlive/2015/bin/x86_64-darwin

set -xg PATH /usr/local/sbin /usr/local/bin /usr/bin /usr/sbin /bin /sbin $PATH
set -xg PATH $HOME/.local/bin $HOME/.rvm/bin $GHC_PATH $TEX_PATH $PATH
set -xg PATH $PATH /usr/local/share/npm/bin
set -xg PATH $PATH /usr/local/google-cloud-sdk/bin
set -xg PATH $PATH $HOME/bin
set -xg PATH $PATH /usr/local/Cellar/rakudo-star/2015.12/share/perl6/site/bin/
set -xg MANPATH /usr/share/man /usr/local/share/man /opt/X11/share/man /usr/local/MacGPG2/share/man /Library/TeX/Distributions/.DefaultTeX/Contents/Man

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


# Emacs
function magit
        env PWD=(pwd) emacsclient -e "(magit-status \"$PWD\")"
end


# Private
source $HOME/.config/fish/private.fish; or true


# Ocaml
source $HOME/.opam/opam-init/init.fish; or true


# Python
eval (python -m virtualfish)
