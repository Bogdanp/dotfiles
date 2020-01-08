# dotfiles

## Setup

1. `git submodule update --init`
1. `pip3 install --user ansible`
1. `ln -s ~/Library/Python/3.7/bin/ansible* /usr/local/bin/`
1. `cd ansible && make`

## How Stuff Works

### Email

Email is synced via [isync] and sent via [msmtp], both of these use
the OS X keychain for password management.


[isync]: http://isync.sourceforge.net/
[msmtp]: https://marlam.de/msmtp/
