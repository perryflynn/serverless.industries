---
author: christian
title: "ZFS: Defekte Festplatte ersetzen"
locale: de
ref: zfs-faulty-disk
tags: [ server, zfs, linux, hardware ]
---

Gestern ist nach 4,7 Jahren die erste Festplatte meines ZFS Pools kaputt gegangen.
Ersatz lag schon bereit, da die ersten SMART Warnungen bereits im Oktober kamen.

Ausgaben in `dmesg`:

```txt
[4306423.236738] blk_update_request: I/O error, dev sdd, sector 7925606840 op 0x1:(WRITE) flags 0x700 phys_seg 32 prio class 0
[4306423.237196] sd 4:0:0:0: [sdd] tag#23 FAILED Result: hostbyte=DID_OK driverbyte=DRIVER_SENSE
[4306423.237197] sd 4:0:0:0: [sdd] tag#23 Sense Key : Not Ready [current] 
[4306423.237198] sd 4:0:0:0: [sdd] tag#23 Add. Sense: Logical unit not ready, hard reset required
[4306423.237199] sd 4:0:0:0: [sdd] tag#23 CDB: Write(16) 8a 00 00 00 00 01 d8 67 2a b8 00 00 01 00 00 00
```

## Die kaputte Platte finden

Das Ersetzen ist super simpel, sofern man die Festplatten via Seriennummer 
(`/dev/disk/by-id/...`) in den Pool eingebunden hat. ZFS wird dann die Seriennummer
in den Fehlermeldungen mit anzeigen, und man braucht diese einfach nur mit
dem Etikett auf dem Festplattengehäuse vergleichen.

```txt
zpoolprime: One or more devices are faulted in response to persistent errors. Sufficient 
replicas exist for the pool to continue functioning in a degraded state. Replace the 
faulted device, or use 'zpool clear' to mark the device repaired., mirror-1 state: 
DEGRADED, zpoolprime state: DEGRADED, ata-WDC_WD6002FFWX-68TZ4N0_XXXXXXXX state: FAULTED
```

Alternativ kann man sich die Seriennummer auch über `smartctl -i /dev/sdb` holen. Ist die
entsprechende Festplatte aber so defekt, dass sie vom Kernel nicht mehr erkannt wird, muss
man sich alle vorhandenen Seriennummern aufschreiben und alle Festplatten durchgehen, bis
man die gefunden hat, die defekt ist.

Daher: **Nutzt in ZFS die Disk IDs** und schreibt die Seriennummer am besten 
**auf die Festplattengehäuse** drauf, sodass man das sehen kann ohne die Platten 
aus dem Gehäuse ziehen zu müssen.

## Ersetzen und vorbereiten

Die defekte Platte kann einfach im laufenden Betrieb durch die neue ersetzt werden.

Die sollte dann auch direkt vom Kernel erkennt werden:

```txt
[4331025.244614] ata5: SATA link up 6.0 Gbps (SStatus 133 SControl 300)
[4331025.251378] ata5.00: ATA-9: WDC WD6003FFBX-68MU3N0, 83.00A83, max UDMA/133
[4331025.251384] ata5.00: 11721045168 sectors, multi 0: LBA48 NCQ (depth 32), AA
[4331025.264655] ata5.00: configured for UDMA/133
[4331025.264720] scsi 4:0:0:0: Direct-Access     ATA      WDC WD6003FFBX-6 0A83 PQ: 0 ANSI: 5
[4331025.264997] sd 4:0:0:0: Attached scsi generic sg3 type 0
[4331025.265178] sd 4:0:0:0: [sdd] 11721045168 512-byte logical blocks: (6.00 TB/5.46 TiB)
[4331025.265179] sd 4:0:0:0: [sdd] 4096-byte physical blocks
[4331025.265208] sd 4:0:0:0: [sdd] Write Protect is off
[4331025.265210] sd 4:0:0:0: [sdd] Mode Sense: 00 3a 00 00
[4331025.265257] sd 4:0:0:0: [sdd] Write cache: enabled, read cache: enabled, doesn't support DPO or FUA
[4331025.327930] sd 4:0:0:0: [sdd] Attached SCSI disk
```

Nun muss mit `fdisk /dev/sdd` eine GPT Partitionstabelle auf der neuen Festplatte erstellt
werden, da 6TB für eine DOS Partitionstabelle zu viel ist.

## In ZFS einbinden

Zu guter Letzt wird die Platte in ZFS eingebunden und ZFS wird mit dem "resilvern" beginnen:

```sh
zpool replace zpoolprime ata-WDC_WD6002FFWX-68TZ4N0_XXXXXXXX /dev/disk/by-id/ata-WDC_WD6003FFBX-68MU3N0_YYYYYYYY
```

Beim resilvern spiegelt ZFS die Daten auf die neue Festplatte. In meinem Fall hat dies gute
11 Stunden gedauert. Den aktuellen Status kann man sich mit `zpool status` anzeigen lassen.

```txt
scan: resilvered 3.20T in 0 days 10:52:54 with 0 errors on Mon Apr 5 08:13:06 2021
```
