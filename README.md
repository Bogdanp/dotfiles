# dotfiles

## Setup

1. Install [MacPorts].
1. `sudo port install git`
1. `git clone git@github.com/Bogdanp/dotfiles sandbox/dotfiles`
1. `git submodule update --init`
1. `./bootstrap -d`

## How Stuff Works

### Email

Email is synced via [isync] and sent via [msmtp], both of these use
the OS X keychain for password management.


[MacPorts]: https://www.macports.org
[isync]: http://isync.sourceforge.net/
[msmtp]: https://marlam.de/msmtp/
