---
author: christian
title: "ClusterHAT: Solving power issues with Pi Zeros when rebooting Pi 4"
lang: de
ref: clusterhat-power
tags: ['raspberry pi', linux]
toc: true
---

[Der ClusterHAT][hat] erlaubt das Verbinden von bis zu vier Raspberry
Pi Zeros über einen integrierten USB Hub mit einem normalen Raspberry Pi.
Mit dem [USB Ethernet Gadget][gadget] Feature können die Pi Zeros via Ethernet
mit dem Raspberry Pi kommunizieren.

Einen Raspberry Pi 3 konnte man neustarten, ohne dass die Pi Zeros davon
etwas mitbekommen haben. Nach Wechsel auf einen Raspberry Pi 4 verloren
die Pi Zeros allerdings ihre Strom&shy;versorgung und stürzten ab.

Dieser Artikel beschreibt einen Workaround für den ClusterHAT v2.3 mit
einem Raspberry Pi 4 und dem neusten Raspbian (Debian Buster).

![Clusterberry]({{'/assets/clusterberry-alt.jpg' | relative_url}}){:.img-fluid}

[hat]: https://clusterhat.com/
[gadget]: https://learn.adafruit.com/turning-your-raspberry-pi-zero-into-a-usb-gadget/ethernet-gadget
[fconf]: https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2711_bootloader_config.md
[fflash]: https://www.raspberrypi.org/documentation/hardware/raspberrypi/booteeprom.md
[3v3]: https://groups.google.com/g/clusterhat/c/HYZ5KvayFco/m/i-VY7zJuAQAJ
[3v3b]: https://github.com/raspberrypi/linux/issues/3065
[3v3c]: https://community.blokas.io/t/pisound-with-raspberry-pi-4/1238/12
[newver]: https://groups.google.com/g/clusterhat/c/HYZ5KvayFco/m/i-VY7zJuAQAJ

## Teil 1: Energieeinstellungen in der Firmware

Erstes Problem war das geänderte Verhalten in der Firmware. Um Strom zu sparen
schaltet der Raspberry Pi nach dem Herunter&shy;fahren diverse Funktionen ab.
Abhängig von der Firmware Version müssen diese Stromspar&shy;funktionen wieder
deaktiviert werden.

```txt
# so it should look like
root@clusterberry:~# vcgencmd bootloader_config | grep -P "(WAKE_ON_GPIO|POWER_OFF_ON_HALT)"
WAKE_ON_GPIO=1
POWER_OFF_ON_HALT=0
```

[Siehe die Dokumentation der Firmware Einstellungen][fconf]

Wenn die Einstellungen nicht korrekt gesetzt sind, verursacht dies eine Unterbrechung
der Strom&shy;versorgung am 3.3V GPIO Pin, [welcher den I2C Expander des ClusterHAT versorgt][3v3].
Ebenso kann der 5V Pin betroffen sein.

Um die Einstellungen zu ändern, muss die Konfiguration aus der Firmware extrahiert
werden und nach der Anpassung neu geflasht werden.

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

[Mehr Details zum flashen von Firmwares][fflash]

## Teil 1.5: 3.3V Strom weiterhin instabil

Wegen eines [anderen Problems][3v3b] wird die 3.3V Strom&shy;versorgung weiterhin unterbrochen,
sofern ein HAT mit dem Raspberry Pi verbunden ist. Der Workaround ist das Setzen eines
Kernel Flags.

Das Flag `sdhci.debug_quirks2=4` muss an das Ende der Zeile in `/boot/cmdline.txt`
ergänzt werden:

```txt
dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=9dc0f4ed-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait sdhci.debug_quirks2=4
```

> The sdhci.debug_quirks2=4 disables ‘1.8V’ mode for SD card, so that makes UHS SD
> cards to be used at lower speeds, but this config also prevents power being
> cut off on the GPIO’s 3.3V supply, avoiding the reboot issue.

Siehe [hier][3v3b] und [hier][3v3c].

## Teil 2: Instabile 5V Versorgung

Nächster Punkt ist die instabile 5V Strom&shy;versorgung. Manchmal wird diese
unterbrochen, manchmal nicht. Es ist also eine gute Idee, den ClusterHAT
mit einer eigenen Strom&shy;versorgung zu versehen.

Standard&shy;mäßig wird der HAT über 5V GPIO mit Strom versorgt. Mit dem `PWR`
Jumper kann dies geändert werden. Die Verbindung zwischen `RPi` und `PWR`
muss mit einem Skalpell unterbrochen werden, anschließend muss die Verbindung
zwischen `USB` und `PWR` mit einem Lötkolben hergestellt werden.

![Clusterberry Power]({{'/assets/clusterberry-usbpower.jpg' | relative_url}}){:.img-fluid}

Nun kann der HAT über den MicroUSB Port mit Strom versorgt werden. Mit einem
selbst hergestellten USB Kabel ist es nun möglich, den HAT mit Strom vom Netzteil
zu versorgen und trotzdem die Daten&shy;leitungen mit dem USB Port des Raspberry Pi zu verbinden.

![Clusterberry Power Cable]({{'/assets/clusterberry-powercable.jpg' | relative_url}}){:.img-fluid}

Das Kabel versorgt Raspberry Pi und ClusterHAT von einem gemeinsamen Netzteil mit Strom,
die beiden Daten&shy;leitungen `Data+` und `Data-` werden trotzdem mit einem der USB Ports des
Raspberry Pi 4 verbunden, sodass der USB Hub des HAT weiterhin funktioniert.

![Clusterberry Power Supply]({{'/assets/clusterberry-powersupply.jpg' | relative_url}}){:.img-fluid}

Nun kann jede Komponente des Clusters neugestartet werden, ohne das eine
andere davon beeinträchtigt wird.

**Vorsicht:** Es **muss** ein "dummes" Netzteil verwendet werden, da das Kabel ausschließlich
die Strom&shy;leitungen mit HAT und Raspberry Pi verbindet. Es ist also keine "smart negotiation"
möglich. Zum Beispiel funktioniert es mit dem offiziellen Netzteil der Raspberry Pi Foundation
ohne Probleme.

## ClusterHAT v2.4 löst das Problem

[Dieser Beitrag][newver] sagt, dass die neuere Version 2.4 des HATs das Problem löst,
und somit keine Hacks mehr nötig sind.
