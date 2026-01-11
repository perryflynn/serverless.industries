---
author: christian
title: "File Access via Samba with ACLs"
locale: en
tags: [ linux, debian, server, projects, projects:linas ]
series:
  tag: series:linas
  index: 3
---

If the [File Permissions are set correctly][acls], it is straight forward, to expose file shares
via Samba to Windows and Linux Clients without granting "any-access" to the folder structure.
The Unix Accounts using, just like on the local filesystem, their group memberships.

[acls]: {% post_url 2026/2026-01-11-nas-posix-acls.en %}

Preparations:

- Install Debian Trixie
- Create the groups `nasguest`, `nasusers` and `shrmedia`
- Create the user `nasguest`, give it membership in group `nasguest`
- Create a user for yourself and add it to the `shrmedia` and `nasusers` groups
- Set samba password for user via `smbpasswd -a youruser`

Configuration notes:

- The min/max protocol, `server signing` and `server smb encrypt` settings ensure a
  encrypted and (mostly) secure connection
- The user `nasguest` is used for guest access, so you have to grant group membership for `nasguest`
  to allow write access then
- The `IPC$` share is special and must access to make samba work properly
- With `map acl inherit` it is even possible to change ACLs from a Windows Client

The full configuration:

```ini
[global]
server string = fileserver
workgroup = WORKGROUP
wins support = yes
dns proxy = no
log file = /var/log/samba/log.%m
max log size = 1000
syslog = 0
panic action = /usr/share/samba/panic-action %d
netbios name = fileserver
name resolve order = bcast host

server signing = mandatory
server smb encrypt = required
client max protocol = default
client min protocol = SMB3
server max protocol = SMB3
server min protocol = SMB3

####### Authentication #######
server role = standalone server
passdb backend = tdbsam
obey pam restrictions = yes
unix password sync = yes
passwd program = /usr/bin/passwd %u
passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
pam password change = yes

restrict anonymous = 0
security = user
map to guest = Bad User
guest ok = yes
guest account = nasguest
browse list = yes

usershare allow guests = yes
usershare path =

disable netbios = yes
disable spoolss = yes
invalid users = root
load printers = no
printable = no
printcap name = /dev/null
printing = bsd
read raw = yes
aio read size = 1
aio write size = 1
server multi channel support = yes
show add printer wizard = no
strict allocate = no
strict sync = no
sync always = no
unix password sync = yes
use sendfile = yes
usershare allow guests = no
vfs objects = io_uring acl_xattr
map acl inherit = yes
write raw = yes

####### Shares #######
[IPC$]
guest ok = yes
read only = yes
valid users = @nasguest @nasusers
hosts allow = 192.168.0.0/16 127.0.0.0/8 172.16.0.0/12 10.0.0.0/8
hosts deny  = 0.0.0.0/0

[media]
path = /mnt/raid/media
comment = Some media
available = yes
browseable = yes
read only = no
writable = yes
guest ok = no
valid users = @shrmedia
case sensitive = yes
hide dot files = yes
hosts allow = 192.168.0.0/16 127.0.0.0/8 172.16.0.0/12 10.0.0.0/8
hosts deny  = 0.0.0.0/0
```
