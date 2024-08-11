---
author: christian
title: "Unison: Sync folders in both directions"
locale: en
tags: [ linux, bash ]
---

[Unison](https://github.com/bcpierce00/unison) is a nice tool to synchronize two folders in 
both directions. It keeps two replicas of a folder in sync. Regardless which side was modified.
This works with local folders or via SSH.

I use Unison to keep the folder with ISO images and templates on my Proxmox Cluster on all
nodes in sync. On purpose I avoid shared file systems on my home lab cluster, to keep the
setup as easy as possible.

```sh
unison /zpoolprime/pve-manual/ /zpoolbeta/pve-manual/ -batch
unison /zpoolbeta/pve-manual/ ssh://benny//zpoolbeta/pve-manual/ -batch
```

To run it as a cron job:

```sh
#!/bin/bash
# /usr/local/sbin/pve-sync.sh

set -u
set -e

cleanup() {
    rm -f /var/lock/unison-pve
}

trap cleanup EXIT

if [ -e /var/lock/unison-pve ]; then
    >&2 echo "Process is already running, exit."
    exit 1
fi

if [ ! -d "/zpoolbeta/pve-manual/" ]; then
    >&2 echo "Source '/zpoolbeta/pve-manual/' does not exists, exit."
    exit 1
fi

touch /var/lock/unison-pve

unison "/zpoolbeta/pve-manual/" "ssh://benny//zpoolbeta/pve-manual/" -batch
unison "/zpoolbeta/pve-manual/" "ssh://deputron//zpoolbeta/pve-manual/" -batch
```
