# dotfiles

## Setup

1. `sudo pip install ansible`
1. `cd ansible && make`

## How Stuff Works

### Email

Email is synced via [isync] and sent via [msmtp], both of these use
the OS X keychain for password management.


[isync]: http://isync.sourceforge.net/
[msmtp]: https://marlam.de/msmtp/
