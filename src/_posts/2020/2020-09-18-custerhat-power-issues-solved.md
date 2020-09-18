---
author: christian
title: "ClusterHAT: Solving power issues with Pi Zeros when rebooting Pi 4"
lang: en
ref: clusterhat-power
tags: ['raspberry pi', linux]
toc: true
---

[The ClusterHAT][hat] allows to connect up to four Rasperry Pi Zero
to a Raspberr Pi with a integrated USB Hub. The Pi Zeros are capable to
communicate via [USB Ethernet Gadget][gadget]. So it is possible
to connect the devices via Ethernet.

With a Raspberry Pi 3, it was possible to reboot the Pi 3, without loosing
power on the Pi Zeros. After switching to a Raspberry Pi 4, this didn't worked
anymore. The Zeros lost power and crash.

This article describes a workaround for the ClusterHAT v2.3 with a Raspberry Pi 4
and the latest Raspbian (Debian Buster).

![Clusterberry]({{'/assets/clusterberry-alt.jpg' | relative_url}}){:.img-fluid}

[hat]: https://clusterhat.com/
[gadget]: https://learn.adafruit.com/turning-your-raspberry-pi-zero-into-a-usb-gadget/ethernet-gadget
[fconf]: https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2711_bootloader_config.md
[fflash]: https://www.raspberrypi.org/documentation/hardware/raspberrypi/booteeprom.md
[3v3]: https://groups.google.com/g/clusterhat/c/HYZ5KvayFco/m/i-VY7zJuAQAJ
[3v3b]: https://github.com/raspberrypi/linux/issues/3065
[3v3c]: https://community.blokas.io/t/pisound-with-raspberry-pi-4/1238/12
[newver]: https://groups.google.com/g/clusterhat/c/HYZ5KvayFco/m/i-VY7zJuAQAJ

## Part 1: Power management settings in firmware

Fist issue is the changed behaviour of the power management in the Raspberry Pi firmware.
To save power, some features will now powered off. Depending on the firmware version,
two options need to be changed.

```txt
# show it should look like
root@clusterberry:~# vcgencmd bootloader_config | grep -P "(WAKE_ON_GPIO|POWER_OFF_ON_HALT)"
WAKE_ON_GPIO=1
POWER_OFF_ON_HALT=0
```

[See the configuration documentation][fconf]

If the settings are not correct, this causes a power interruption on
[the 3.3V pin which is powering the I2C expander on the ClusterHAT][3v3].
This will reset the I2C expander and power off the Pi Zeros. The 5V can be
affected as well.

To change the configuration, it must be extracted from the current firmware
and flashed again afterwards.

```sh
# extract the configuration from the
# eeprom image into a text file
rpi-eeprom-config /lib/firmware/raspberrypi/bootloader/critical/pieeprom-2020-04-16.bin > bootconf.txt
# set WAKE_ON_GPIO=1
# set POWER_OFF_ON_HALT=0
vim bootconf.txt
# create a new eeprom image for the new configuration
rpi-eeprom-config --out pieeprom-2020-04-16-bb.bin --config bootconf.txt /lib/firmware/raspberrypi/bootloader/critical/pieeprom-2020-04-16.bin
# flash the image
rpi-eeprom-update -d -f pieeprom-2020-04-16-bb.bin
# reboot
sudo reboot
# check if the config is applied
vcgencmd bootloader_config
```

[More infos about firmware updates][fflash]

## Part 1.5: 3.3V power still interrupted

Because of a [another issue][3v3b], the 3.3V pin still resets when a HAT is connected to the
Raspberry Pi 4. The workaround described in the linked GitHub issue is a kernel flag.

The option `sdhci.debug_quirks2=4` must be appended to the end of the line in
`/boot/cmdline.txt`:

```txt
dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=9dc0f4ed-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait sdhci.debug_quirks2=4
```

> The sdhci.debug_quirks2=4 disables ‘1.8V’ mode for SD card, so that makes UHS SD
> cards to be used at lower speeds, but this config also prevents power being
> cut off on the GPIO’s 3.3V supply, avoiding the reboot issue.

See [here][3v3b] and [here][3v3c].

## Part 2: Unstable 5V power supply

Next issue is a unstable 5V power. In some cases it interrups, in other cases
not. So it would be a good idea to build a own power supply for the HAT.

Per default the HAT is powered via 5V GPIO. This can be changed to USB with the `PWR` jumper.
The connection between `RPi` and `PWR` must be cutted, the connection between `USB`
and `PWR` must be established with a soldering iron.

![Clusterberry Power]({{'/assets/clusterberry-usbpower.jpg' | relative_url}}){:.img-fluid}

Now it is possible to power the HAT through USB. With a custom USB cable, this is still
possible with one single official Raspberry Pi USB power supply.

![Clusterberry Power Cable]({{'/assets/clusterberry-powercable.jpg' | relative_url}}){:.img-fluid}

The cable serves power to the HAT and to the Pi 4 through the normal USB ports and also
connects the HAT via USB to the Pi 4 (data lines only), so that the integrated
USB Hub still works.

![Clusterberry Power Supply]({{'/assets/clusterberry-powersupply.jpg' | relative_url}}){:.img-fluid}

Now any component of the cluster can be rebooted without affection the other ones.

**But attention:** You **must** use a "dumb" power supply as in this setup only the power
lines are connected. So no smart negotiation or something like that possible! It works quite
good with the official power supply from the Raspberry Pi Foundation.

## ClusterHAT v2.4 fixes this issue

[This post][newver] says, that the newer Version 2.4 fixes this issue.
So no workarounds required if this version is used.
