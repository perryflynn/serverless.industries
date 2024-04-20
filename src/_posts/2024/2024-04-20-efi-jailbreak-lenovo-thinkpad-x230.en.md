---
author: christian
title: Jailbreaking the Thinkpad X230 UEFI to replace the Wifi Chip
locale: en
tags: [ hardware, lenovo thinkpad, uefi ]
image: /assets/x230_wifi_cmos.jpg
---

I wanted to reactivate my old Lenovo Thinkpad X230 as a "Burner Laptop". Put a Linux on it,
use it on events like conferences and reinstall it afterwards. The main reason why I replaced it
was the outdated WiFi chip, which only supported 802.11 a/b/g/n.

*tl;dr: There is the project [1vyrain](https://1vyra.in/) which allows a UEFI downgrade,
jailbreak and patch to allow third party Wi-Fi Chips.*

**Attention: The described actions will touch the UEFI BIOS of your machine. Any mistake will
end in a bricked device. As always, use at own risk!**

## UEFI Downgrade

At least on my X230 Laptop was a UEFI version installed, which had the vulnerability patched
required for the jailbreak.

[IVprep](https://github.com/n4ru/IVprep/) is a toolchain to downgrade the UEFI to a vulnerable
version. It requires a Windows 10+.

Also you have to allow the UEFI downgrade in the UEFI settings:

> Go into your BIOS setup. Navigate to `Security -> UEFI BIOS Update` option. 
> Set `Flash BIOS Updating by End-Users` to enabled, and `Secure RollBack Prevention` to disabled.

After that, download the whole IVprep Repo and execute the downgrade.bat file in a
CMD with administrative pivileges.

## Jailbreak

[1vyrain](https://1vyra.in/) itself can be downloaded on its website and comes as a bootable
disk image. It has to be flashed to a USB disk with a tool like [etcher](https://etcher.balena.io/).

The USB Disk then has to be booted on UEFI Mode from a onboard USB port.

The instructions on the screen should guide you through the process.

Details can be found on [the GitHub Page](https://github.com/n4ru/1vyrain/tree/master?tab=readme-ov-file#installing).

## Replace the Wi-Fi chip

After successfully patching the UEFI, I've replaced the Wi-Fi chip with a 
**Intel AC7260 Mini-PCIex Adapter**. It is located below the right palm rest.

There are some videos on YouTube, how the Keyboard and Touchpad can be removed.

How to check if a Wi-Fi connection is using 802.11ac on Linux, can be found on
[ask Ubuntu](https://askubuntu.com/a/1263384/443450).

## Replace the CMOS battery

Also the CMOS battery was empty. A replacement is offered by multiple distributors online.
Search for "CMOS Battery Thinkpad X230".

![Lenovo Thinkpad X230 Wi-Fi and CMOS battery replacement]({{'assets/x230_wifi_cmos.jpg' | relative_url}}){:.img-fluid}
