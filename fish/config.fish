# Locale
set -xg LC_ALL en_US.UTF-8
set -xg LANG en_US.UTF-8


# Path
set -xg PATH /usr/local/sbin /usr/local/bin /usr/bin /usr/sbin /bin /sbin $PATH
set -xg PATH $PATH $HOME/.local/bin $HOME/bin $HOME/sandbox/google-cloud-sdk/bin
set -xg PATH $PATH $HOME/.config/yarn/global/node_modules/.bin
set -xg MANPATH /usr/share/man /usr/local/share/man /opt/X11/share/man /usr/local/MacGPG2/share/man /Library/TeX/Distributions/.DefaultTeX/Contents/Man
set -xg RUST_SRC_PATH $HOME/sandbox/rust/src


# Env
set -xg EDITOR ec


# Aliases
alias sbcl="rlwrap ros run"
alias g=git
alias w=workon


# Python
set -xg WORKON_HOME $HOME/.virtualenvs


# Pyenv
#   Inlined output from (pyenv init -)
set -gx PATH '/Users/bogdan/.pyenv/shims' $PATH
set -gx PYENV_SHELL fish
source '/usr/local/Cellar/pyenv/1.2.8/libexec/../completions/pyenv.fish'
command pyenv rehash 2>/dev/null
function pyenv
  set command $argv[1]
  set -e argv[1]

  switch "$command"
  case rehash shell
    source (pyenv "sh-$command" $argv|psub)
  case '*'
    command pyenv "$command" $argv
  end
end


# Virtualfish
#   Inlined output from (python -m virtualfish) for faster startup times:
set -g VIRTUALFISH_VERSION 1.0.5
set -g VIRTUALFISH_PYTHON_EXEC /usr/local/bin/python3.7
. /usr/local/lib/python3.7/site-packages/virtualfish/virtual.fish
emit virtualfish_did_setup_plugins


# GPG
set -xg GPG_TTY (tty)
