---
author: christian
title: "LiNAS: Self-made Linux NAS"
locale: en
tags: [ linux, debian, ansible, server, projects, projects:linas ]
series:
  tag: series:linas
  index: 0
---

I looked for a new NAS and once again I was not happy with the available solutions. I bought
a UGREEN 4800 Plus which is a upgradable x86 4-bay NAS with a propitary OS installed on it.

The OS is quite good and will work for most people. But I wanted to take the chance to test
TrueNAS. So I just disabled the Watchdog in the EFI BIOS and replaced the OS. TrueNAS
is okay, but for a small NAS too much IMHO.

I didn't wanted to use ZFS, the NAS should work without any caching devices or huge RAM demand.

On the way back to the UGREEN OS I found out, that I need to request a installer ISO from 
UGreen Support which is unqiue for my Hardware and **only works once**. Crazy. What when the 
NVME dies in a few years and UGREEN ends support for this Model?

So I decided to create my own very simple but feature-rich NAS solution.

## The Plan

- Just use the latest Debian
- Configuration with Ansible
- NFS for Services like Jellyfin
- Samba and HTTPS for Access from PCs
- Simple Permission system based on read-only and read-write groups per share
- Permissions must work on all file transfer protocols

Later:

- rsync Server to replicate Files to other storage systems
- WebDAV for mobile devices?

And all this just with tech which is part of Debian. No custom scripts, services or software, if
possible.

## Presenting: LiNAS

The Core of LiNAS is a Ansible Playbook which expects a installed Debian Linux and mounted storage.
Setting up a RAID is explicitly **not part of the Playbook**, since I didn't wanted to disk data loss
because of a bug in the Playbooks code.

You can find the Code on Codeberg at [pery/linas](https://codeberg.org/pery/linas).

The Ansible code works, I use it on my NAS at home, but it is definitely Alpha and should only used
by people with Knowledge in Linux and Ansible.

I would be very grateful if you could test it in a VM and give me Feedback on Codeberg or via Email.

Thanks!

*The next posts in this series explain all the small tweaks to create a good experience on all transfer protocols. Enjoy!*
