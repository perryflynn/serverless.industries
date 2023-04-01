---
author: christian
title: "TaskOMat: Kleine Anpassungen & Webhooks"
locale: de
tags: [server, zfs, linux, debian]
---

Disks in ZFS können mit dem Befehl `zfs replace` ganz leicht ausgetauscht werden.
Da die Festplatten in meinem Server über fünf Jahre alt waren, habe ich dies
aus Sicherheitsgründen getan.

```
zpool replace zpoolprime ata-WDC_WD6002FFWX-68TZ4N0_XXXXXX /dev/disk/by-id/ata-WDC_WD6003FFBX-68MU3N0_YYYYY
```

Aus *Gründen* befanden sich eine 8TB und eine 6TB Disk zusammen in einem vDev,
dies habe ich direkt korrigiert und eine neue 8TB Disk in das vDev eingebunden
und die frei gewordene 6TB in ein anderes geschoben und damit eine ältere Disk ersetzt.

Dadurch kann ZFS nun die vollen 8TB Speicher in dem vDev nutzen. Das vDev muss dafür
aber manuall vergrößert werden:

```
zpool online -e zpoolprime ata-WDC_WD8003FFBX-68B9AN0_XXXXXXX ata-WDC_WD8003FFBX-68B9AN0_YYYYYY
```

Nun sollte sich die unter `zpool list -v` angezeigte Kapazität vergrößert haben.
