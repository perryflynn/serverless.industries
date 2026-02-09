---
author: christian
title: "Year of the Linux Desktop"
locale: en
tags: [ linux, debian, desktop, laptop ]
image: /assets/yotld.jpg
---

Since 2005-ish every single of my PCs always had Linux installed. 
When I bought a "ThinkPad T14 Gen 2 (Intel)" Laptop in 
2022, I really wanted to use two 4K screens with a Thunderbolt Dock, but unfortunately it 
didn't worked neither on Debian nor on Manjaro/Arch Linux.

After erroring around for a few days, I just decided to install Windows 10 and try it again later.
This later is now, four years later. **And everything works!** 🎉

Well, almost. For personal preference, I chose to use Debian 13 (Trixie) with KDE Plasma.
I am certain, that the out-of-the-box experience would be better in Linux Mint for example.

Anyway, the installer missed some non-free driver packages, 
so I had to install the following packages:

- `firmware-misc-nonfree`
- `firmware-iwlwifi`
- `firmware-intel-sound`
- `firmware-sof-signed`

*Note: I don't use the Nvidia GPU!*

After a quick reboot Sound, Wifi and Graphics worked correctly.

Before that, I had for example the following error message, when I tried to 
launch the note app Obsidian:

> nvc0_screen_create:899 - Base screen init failed: -19

Next was Sleep and Hibernate, both didn't worked when a second user session (like a root shell) 
was active. The solution here was to pick some configs from 
[fuyujitaku](https://github.com/suikan4github/fuyujitaku/).

```js
/* /etc/polkit-1/rules.d/50-hibernate.rules */
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.hibernate" ||
        action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
        action.id == "org.freedesktop.upower.hibernate" ||
        action.id == "org.freedesktop.login1.handle-hibernate-key" ||
        action.id == "org.freedesktop.login1.hibernate-ignore-inhibit")
    {
        return polkit.Result.YES;
    }
});
```

This allows a regular user to trigger hibernation, even when other login sessions are active.

```ini
# /etc/systemd/sleep.conf
[Sleep]
HibernateDelaySec=3600
HibernateOnACPower=yes
```

This triggers hibernation when the laptop is in sleep mode for longer than one hour.
(Really cool IMHO!)

The rest looks really great so far.

Some quick notes:

- KDE Plasma 6 is awesome
- Multi Screen works, Wayland works, Ultrawide monitor via Thunderbolt works
- `Win + .` triggers the emoji chooser! Just like on Windows!
- `Win + Shift + S` opens a really great screenshot tool. Just like on Windows!
- For wireguards `wg-quick` to work, I had to install the package `resolvconf`
- The energy management settings are very detailed and very awesome!
- Same for sound and volume settings!
- In the tray on "Power and Battery" there is a "Block sleep on inactivity" button.
  It even displays which applications are blocking sleep (like Firefox on video playback)
- The integration of Samba is not that great, I probably have to switch my NAS access
  to NFS.

It's only three days, so I am still in the onboarding phase, but so far it looks awesome. If you don't
want to use Windows 11, just try it. In the last five years the whole Linux experience improved alot!

*Disclaimer: I don't play games on my Laptop, you may want to check Cachy OS, Pop! OS or one of the other gaming-focused distributions.*

![Serial Blinkenlights]({{'assets/yotld.jpg' | relative_url}}){:.img-fluid}
