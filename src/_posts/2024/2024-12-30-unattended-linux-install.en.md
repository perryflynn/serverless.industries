---
author: christian
title: Install Linux unattended
locale: en
tags: [ linux, shell, ansible, projects, projects:iac, infrastructure code ]
series:
  tag: series:iacbootstrap
  index: 2
featured: true
---

After [reviving my old Thinkpad X230][thinkpad] I looked for a way to automate the installation 
of a Linux system with a minimal desktop. The idea was to have a "conference laptop" which can 
be reinstalled after each use.

**tl;dr:** The code including a detailed README can be found [on my GitHub profile][iac].

After building the [custom archiso][archiso], this article gives an overview of the Ansible code.

[iac]: https://github.com/perryflynn/iac
[thinkpad]: {% post_url 2024/2024-04-20-efi-jailbreak-lenovo-thinkpad-x230.en %}
[archiso]: {% post_url 2024/2024-12-30-custom-archiso.en %}

## Prepare configuration

On the ISO image the installatio process is started by the script `perrys-bootstrapper.sh`.
This script supports of course command line arguments, but it also can read configuration
from UEFI variables.

Define hostname:

```sh
echo -n myhostname > efi-hostname
efivar --name ed38a5bf-1135-4b0f-aa72-49d30b05dfd4-PerryHostname -w -f efi-hostname
```

Define flavor:

```sh
# one of: debian, ubuntu, archlinux
echo -n debian > efi-flavor
efivar --name ed38a5bf-1135-4b0f-aa72-49d30b05dfd4-PerryFlavor -w -f efi-flavor
```

Per default the bootstrapper is not started automatically. This can be changed by setting
the kernel command line parameter `script` in Grub:

```txt
script=/usr/local/sbin/perrys-bootstrapper.sh
```

The hostname is then used to find further configuration settings in the [inventorys][inventory]
`bootstrapparameters` object.

[inventory]: https://github.com/perryflynn/iac/blob/main/inventory/defaults.yml

## Bootstrapping process

The whole process is done by Ansible and consists of three stages.

The first stage will create the filesystem partitions. If `encryptedfs=true`, it will ask
for the passphrase and will then encrypt the root partition. Afterwards, depending on the
choosen flavor, `pacstrap` or `debootstrap` is executed.

The second stage will use Ansibles [chroot connection][chroot] to run Ansible tasks inside
of the newly created Linux system, install packages and bootloader, configure locales
and other necessary stuff. Also it will prepare the third stage as a one-shot systemd service.

See the [local.yml][local] playbook for more details.

Finally the system reboots and will execute the third stage at first boot to install more
stuff like a Desktop Environment. If the hostname is `retired`, the playbook [retired.yml][retired]
is pulled from the git repository for that.

The third stage can be changed and re-run at any time, since there is a script called 
`/usr/local/sbin/perrys-ansible-apply.sh` available on the installed system.

[chroot]: https://docs.ansible.com/ansible/latest/collections/community/general/chroot_connection.html
[retired]: https://github.com/perryflynn/iac/blob/main/retired.yml
[local]: https://github.com/perryflynn/iac/blob/main/local.yml
