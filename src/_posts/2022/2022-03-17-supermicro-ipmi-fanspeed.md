---
author: christian
title: 'Lüftersteuerung für Supermicro IPMI'
locale: de
tags: [ linux, server, hardware ]
---

In meinem Selbstbau NAS steckt ein Supermicro Server Mainboard mit IPMI/BMC.
Das IPMI/BMC liefert das übliche. Web GUI womit man diversen Kram einstellen kann, den Server anschalten
kann, etc, etc, etc.

Zusätzlich steuert das IPMI/BMC auch die Sensoren und die Lüfter. Über die Web GUI lassen sich
Schwellwerte für Drehzahlen und Temperaturen einsehen, an denen die Lüfter hochgedreht oder
Alarm Emails versendet werden. Einstellen lässt sich dort aber nichts.

**Dieser Artikel wurde 2016 in meinem alten Blog anysrc.net veröffentlicht.**

## Die richtigen Lüfter

Im Gehäuse waren 3-polige Billiglüfter verbaut. Mangels PWM Pin haben diese natürlich nicht die Drehzahl
geregelt und liefen dauerhaft auf 1200rpm.

Mein erster Kauf PWM gesteuerter Lüfter war direkt ein Fehlschlag. Die "ARCTIC F14 PWM PST" **funktionieren
leider nicht** mit einem Supermicro X11SSL-F Board. Problem war hier, dass die Lüfter sich bei zu niedriger Drehzahl
abgeschaltet haben.

Die Board Sensoren haben sofort Alarm geschlagen, und drehten alle anderen Lüfter auf 1200rpm hoch, da ein
Lüfterschaden vermutet wurde. Nach wenigen Sekunden gingen sie wieder auf ~300rpm runter und somit wieder komplett aus,
wieder kam der Alarm, und immer so weiter.

Mein zweiter Versuch waren die "Noctua NF-A14 PWM". Diese funktionieren wunderbar und sind super leise.

### Vorbereitungen

Man sollte vor dem Abfeuern der ipmitool Befehle einen Fan Mode im IPMI Web GUI einstellen.

Ich habe dort "Optimal Speed" gewählt.

### Schwellwerte in rpm einstellen

Die Werte legen fest, ab welchen Drehzahlen das IPMI/BMC Alarm schlägt bzw eingreift.

```sh
# Sensoren auflisten
ipmitool sensor

# Fan Schwellwert einstellen
# ipmitool sensor thresh FANNAME WHAT NRRPM CRPM NCRPM
# WHAT = Sensor Name
# NRRPM = Non-Recoverable RPM
# CRPM = Critical RPM
# NCRPM = Non-Critical RPM
ipmitool sensor thresh FAN1 lower 500 600 700
```

Die Schwellwerte sollten natürlich so gewählt werden, dass diese zu den eingestellten
Drehzahlen passen. Meine Einstellungen liegen aktuell bei `0`, `100` und `200`.

### Drehzahlen in Prozent einstellen

```sh
# Standard Drehzahl CPU Zone zu ~38%
# Vorletzter Parameter: Lüfter Zone; 0x00 = CPU Zone
# Letzter Parameter: Drehzahl in Prozent; 0x00 (0%) - 0x64 (100%)
ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x24

# Standard Drehzahl Perpipheral Zone zu 50% Drehzahl
# Vorletzter Parameter: Lüfter Zone; 0x01 = Perpipheral Zone
# Letzter Parameter: Drehzahl in Prozent; 0x00 (0%) - 0x64 (100%)
ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x32
```

Mein Board teilt die Lüfter in CPU Zone (FAN1 bis FAN4) und Perpipheral Zone (FANA) auf.
Die Pins sind auch so im Board Handbuch bezeichnet. Für beide Zonen kann man eine Standard Drehzahl in Prozent
einstellen.

Im ipmitool Befehl wird dies als letzter Parameter zwischen `0x00` für 0 Prozent und `0x64` für 100 Prozent angegeben.

Was dabei rauskommt, hängt vom Lüfter ab. Ein regelbarer Lüfter, den ich noch rumliegen hatte,
drehte bei 25% (0x16) 900rpm (kann wahrscheinlich nicht weniger), während die Noctua Lüfter dort 300rpm leisten.

## Einstellungen prüfen

Die Einstellungen können mit `ipmitool` und `hddtemp` geprüft werden.
Ich habe mir dafür ein kleines Shellscript zusammen gestellt.

```sh
#!/bin/bash

echo
hddtemp /dev/sd{a,b,c,d,e,f}

echo
ipmitool sensor | grep -E "^FAN|^CPU Temp"

echo
```

**Ausgabe:**

```
root@eisenbart:~# rs

/dev/sda: TS128GSSD370S: 25°C
/dev/sdb: SanDisk SDSSDP064G: 30°C
/dev/sdc: WDC WD6002FFWX-68TZ4N0: 39°C
/dev/sdd: WDC WD6002FFWX-68TZ4N0: 38°C
/dev/sde: WDC WD6002FFWX-68TZ4N0: 39°C
/dev/sdf: WDC WD6002FFWX-68TZ4N0: 38°C

CPU Temp         | 22.000     | degrees C  | ok
FAN1             | na         |            | na
FAN2             | 800.000    | RPM        | ok
FAN3             | na         |            | na
FAN4             | 800.000    | RPM        | ok
FANA             | 800.000    | RPM        | ok
```

Das Script muss natürlich angepasst werden, sofern die Platten im System anderst betitelt sind.

## Quellen

- Schwellwerte: [forums.freenas.org](https://forums.freenas.org/index.php?threads/how-to-change-sensor-thresholds-with-ipmi-using-ipmitool.23571/)
- Drehzahlen: [forms.servethehome.com](https://forums.servethehome.com/index.php?resources/supermicro-x9-x10-x11-fan-speed-control.20/)
- Spezifikation Festplatten (pdf): [wdc.com](http://www.wdc.com/wdproducts/library/SpecSheet/ENG/2879-800022.pdf)
