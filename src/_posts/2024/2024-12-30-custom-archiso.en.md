---
author: christian
title: Use archiso for custom Linux boot disks
locale: en
tags: [ linux, shell, projects, projects:iac ]
series:
  tag: series:iacbootstrap
  index: 1
---

After [reviving my old Thinkpad X230][thinkpad] I looked for a way to automate the installation 
of a Linux system with a minimal desktop. The idea was to have a "conference laptop" which can 
be reinstalled after each use.

**tl;dr:** The code including a detailed README can be found [on my GitHub profile][iac].

[iac]: https://github.com/perryflynn/iac
[thinkpad]: {% post_url 2024/2024-04-20-efi-jailbreak-lenovo-thinkpad-x230.en %}

## Installation Media

Some media to boot the installer from is necessary. I decided to use [archiso][archiso], the
live system used by Arch Linux to run it's installer. Arch Linux also ships
[debootstrap][debootstrap] in the package repository, which makes it possible to install
Arch Linux, Ubuntu and Debian from the same live system.

[archiso]: https://wiki.archlinux.org/title/Archiso
[debootstrap]: https://wiki.debian.org/Debootstrap

## The easy way

The subfolder [archiso][docker] in my repo contains a Dockerfile and some shell scripts to
build the ISO image inside of a Docker container.

For an easy start, my [iac repo][iac] can be cloned to a machine with Docker installed.

- Build the Docker Container: `./archiso/build.sh`
- Build the ISO image: `./archiso/pack.sh`

[docker]: https://github.com/perryflynn/iac/tree/main/archiso

## The manual way

The Arch Linux package `archiso` provides the tool `mkarchiso`.

To begin with a custom ISO image, the profile which is also used to create the official Arch Linux
ISOs can be copied: `cp -r /usr/share/archiso/configs/releng/ ~/archiso`.

The file `packages.x86_64` controls which packages will be installed in the ISO image, in
`profiledef.sh` various metadata and other settings can be set. The folder `airootfs/` contains
all custom files and folders which should be added to the ISO.

To execute commands at build time, the script `airootfs/root/customize_airootfs.sh` can be used.
For example enabling systemd services or to make changes on configuration files.

Then build the ISO image: `mkarchiso -v -w ~/archiso-tmp -o ~/output ~/archiso`

More details can be found on the [archiso wiki page][archiso].
