---
author: christian
title: Configure Bash History
lang: en
ref: bash-history-conf
tags: ['linux', 'bash', 'shell']
---

For [Borg Backup][borg] I wanted to defined environment variables
without adding them to `~/.bash_history`. In the man page I found
`HISTCONTROL`.

Default settings on a fresh Debian Buster installation:

```
borg@borg:~$ set | grep HIST
HISTCONTROL=ignoreboth
HISTFILE=/mnt/backup/borg/.bash_history
HISTFILESIZE=2000
HISTSIZE=1000
```

## HISTCONTROL

This environment variable controls how the executed commands are added
to the history file. Multiple settings can be set, separated by a colon.

- `ignorespace`: All commands starting with a space will not be added to the
  history. So you just need to start the environment variable declaration
  with a space.
- `ignoredups`: Prevents adding repeated/duplicate commands to the history
- `erasedups`: Remove all duplicate commands from the history before adding the
  new ones.

Example:

```sh
HISTCONTROL="ignorespace:erasedups"
export HISTCONTROL
```

## HISTFILE

Path to the history file.

If undefined, no history is created.

## HISTSIZE & HISTFILESIZE

Number of commands which will stored in the history and history file.

[borg]: https://borgbackup.readthedocs.io/en/stable/usage/general.html#environment-variables
