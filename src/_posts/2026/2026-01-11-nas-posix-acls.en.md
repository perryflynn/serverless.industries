---
author: christian
title: "Posix ACLs and NFS"
locale: en
tags: [ linux, debian, server, projects, projects:linas ]
series:
  tag: series:linas
  index: 1
---

In a multi-user environment, there is always the challenge to set file permissions so that all
users for a folder actually have access to all files. 

Of couse groups can be used, and if the Sticky bit is set on a folder (`chmod g+s folder/`),
this group is also replicated to all newly created folders and files. But the problem are the
permission bits. The group will never get the write permission (`w`) automatically.

To change this, we can use [Posix ACLs][acls].

ACLs allow you to add additional sets of permissions to a file and also to define so called
default permissions, which will be inherited to all newly created files.

ACLs are enabled by default on all `ext4` filesystems, but you have to install the package `acl`
on Debian to make the tools available.

Example: 

```sh
# set read-write to all elements recursively, but execute only to folders
setfacl -R -m "g:myawesomegroup:rwX" /mnt/raid/test
# set the same permissions as default to all elements recursively
setfacl -R -d -m "g:myawesomegroup:rwX" /mnt/raid/test
```

[acls]: https://www.osc.edu/resources/getting_started/howto/howto_manage_access_control_list_acls/howto_use_posix_acl

Next we have to install and configure NFS. On Debian the package is called `nfs-kernel-server`.
To allow access to the rpcbind service only from local networks, add the following line to 
`/etc/hosts.allow`: 

```txt
rpcbind: 192.168.0.0/16, 127.0.0.0/8, 172.16.0.0/12, 10.0.0.0/8`
```

Then we have to set some settings in `/etc/nfs.conf`:

- Enforce NFS Version 3: `vers3=y`, `vers4=n`, `vers4.0=n`, `vers4.1=n`, `vers4.2=n`
- Disable GID Management (both occurrences):  `manage-gids=n`

Posix ACLs only work with NFSv3. In v4 there are NFSv4 ACLs which are not supported by Linux.
Also NFS per default checks group memberships server-side. With disabling `manage-gids`,
client-side GIDs will be accepted. But keep in mind, that **only the first 16 GIDs** of a user
will be sent to the NFS server.

NFSv3 does not use user-based authentication, but IP-based authentication. In the config file
`/etc/exports` the folder which should be exposed can be defined:

```txt
/mnt/raid/media 192.168.42.0/24(secure,sync,mountpoint=/mnt/raid,root_squash,anonuid=65534,anongid=65534,ro) 192.168.13.0/24(secure,sync,mountpoint=/mnt/raid,root_squash,anonuid=65534,anongid=65534,ro)
```

With this, the folder `/mnt/raid/media` is made accessible from two IP networks. The `root_squash` option
denies access with a root user, the correct user with the correct group memberships must be used.
Also the access from both networks is only allowed read-only.

After restarting `rpcbind`, `nfs-server` and `nfs-mountd` NFS should now expose the file 
permissions correctly.

Example entry for the `/etc/fstab` on a Linux client machine:

```txt
192.168.13.16:/mnt/raid/media /mnt/media nfs auto,nofail,noatime,ro,nolock,intr,tcp,actimeo=1800,acl,vers=3 0 0
```

After a `systemctl daemon-reload` it should now be possible to mount the share with
`mount /mnt/media` and if the package `acl` is installed, 
`getfacl /mnt/media` should also show the ACL entries from the NAS share.
