# dotfiles

## Setup

1. `git submodule update --init`
1. `./bootstrap -d`

## How Stuff Works

### Email

Email is synced via [isync] and sent via [msmtp], both of these use
the OS X keychain for password management.


[isync]: http://isync.sourceforge.net/
[msmtp]: https://marlam.de/msmtp/
