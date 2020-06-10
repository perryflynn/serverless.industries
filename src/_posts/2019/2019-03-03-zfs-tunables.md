---
author: christian
title: ZFS Tunables
lang: de
ref: zfs-tunables
tags: [linux, zfs, server, hardware]
---

In diesem Beitrag erkläre ich einige Punkte, welche die Performance von ZFS
deutlich beeinträchtigen können. Tatsächlich hatte ich genau diese Fehler bei meinem Setup auch
gemacht. Hier eine kurze Zusammenfassung, auf was man unbedingt achten sollte.

## Benchmark

<div markdown="1" class="table-responsive">

{:.table .table-bordered}
4GiB Testfile bs=1M | Write (no cache) | Write (cache) | Read (no cache) | Read (cache)
--|--|--|--|--
Vorher | 162 MB/sec | 841 MB/sec | 288 MB/sec | 1.800 MB/sec
Nachher | 169 MB/sec | 1.400 MB/sec | 776 MB/sec | 6.400 MB/sec
Nachher (24h später) | 3.400 MB/sec | 4.200 MB/sec | 12.200 MB/sec | 12.600 MB/sec
Zuwachs % | 2.098,77% | 499,41% | 4.236,11% | 700,00%

</div>

<div markdown="1" class="table-responsive">

{:.table .table-bordered}
16GiB Testfile bs=1M | Write (no cache) | Write (cache) | Read (no cache) | Read (cache)
--|--|--|--|--
Vorher | 170 MB/sec | 266 MB/sec | 270 MB/sec | 684 MB/sec
Nachher | 307 MB/sec | 513 MB/sec | 508 MB/sec | 2.400 MB/sec
Nachher (24h später) | 3.000 MB/sec | 3.200 MB/sec | 12.600 MB/sec | 12.500 MB/sec
Zuwachs % | 1.764,71% | 1.203,01% | 4.666,67% | 1.827,49%

</div>

Kann man mit leben, oder? :-)

Vor allem, dass sich die Performance zirka 24 Stunden nachdem
das ZFS neu initialisiert wurde noch einmal regelrecht explodiert
ist, finde ich sehr beeindruckend.

Der Benchmark wurde mit meinem [iobench.sh](https://github.com/perryflynn/iobench) Script erstellt.

## Aufbau des ZPool

Mein Setup besteht aus vier Western Digital WD Red Pro Festplatten
mit je 6 Terabyte Kapazität.
Je zwei sind zu einem Mirror vDev zusammen gefasst. Zusätzlich sind
zwei Samsung 960 EVO NVME SSDs mit je 250GB Kapazität als Cache
verbaut.

```text
NAME                                              STATE     READ WRITE CKSUM
zpoolprime                                        ONLINE       0     0     0
  mirror-0                                        ONLINE       0     0     0
    ata-WDC_WD6002FFWX-68TZ4N0_NCGWXXXX           ONLINE       0     0     0
    ata-WDC_WD6002FFWX-68TZ4N0_NCGWXXXX           ONLINE       0     0     0
  mirror-1                                        ONLINE       0     0     0
    ata-WDC_WD6002FFWX-68TZ4N0_NCGWXXXX           ONLINE       0     0     0
    ata-WDC_WD6002FFWX-68TZ4N0_NCGWXXXX           ONLINE       0     0     0
cache
  nvme-Samsung_SSD_960_EVO_250GB_S3ESNX0J306XXXX  ONLINE       0     0     0
  nvme-Samsung_SSD_960_EVO_250GB_S3ESNX0J401XXXX  ONLINE       0     0     0
```

## Advanced Format (AF) Disks und ashift

So genannte Advanced Format Festplatten nutzen nativ 4096 Byte
anstatt der üblichen 512 Byte für einen Sektor. Allerdings
emuliert die Firmware der Festplatte standardmäßig weiterhin
512 Byte pro Sektor.

Das kann zusammen mit der automatischen Erkennung der Sektorengröße
in ZFS zu massiven Performanceverlusten führen.

Eine explizite Sektorgröße kann bei der Erstellung eines
neuen Pools oder beim Hinzufügen von neuen Geräten über die
Option `ashift` angegeben werden:

```sh
zpool create -o ashift=12 tankname mirror sda sdb
zpool add -o ashift=12 tankname mirror sdc sdd
```

Der Wert von `ashift` kann zwischen 9 und 12 liegen. Bei 512 Byte
pro Sektor ergibt sich die Rechnung `2^9 = 512`, bei 4096 Byte
pro Sektor ergibt sich die Rechnung `2^12 = 4096`.

Wie groß die Sektoren der Festplatten sind, lässt sich mit
`smartctl` herausfinden:

```txt
root@eisenbart:~# smartctl -i /dev/sdb
Device Model:     WDC WD6002FFWX-68TXXXX
[...]
Sector Sizes:     512 bytes logical, 4096 bytes physical
[...]
```

Die physikalische Sektor Größe ist hierbei interessant.

Quelle: [zfsonlinux faq](https://github.com/zfsonlinux/zfs/wiki/FAQ#advanced-format-disks)

## Extended Filesystem Attributes (xattr)

ZFSOnLinux speichert Standardmäßig die erweiterten Dateisystem
Attribute in einem verschteckten Ordner als Dateien, welches in
einigen Fällen negative Auswirkungen auf die Performance haben kann.

Mit folgender Einstellung kann dies geändert werden:

```sh
zfs set xattr=sa tankname
```

Anschließend werden die Attribute ganz normal als Inodes gespeichert.

Quellen: [nerdblog.com](http://www.nerdblog.com/2013/10/zfs-xattr-tuning-on-linux.html) & `man zfs`

## Access Time Update (atime)

Gerade bei vielen kleinen Dateien, auf welche sehr oft
zugegriffen wird, bietet sich das Deaktivieren der
Access Time Updates an.

```sh
zfs set atime=off tankname
```

Quelle: [prefetch.net](https://prefetch.net/blog/index.php/2006/07/25/disabling-access-time-atime-updates-on-zfs-file-system/)

## Filesystem Compression

Bringt minimale (nicht merkbare) Geschwindigkeitseinbußen, dafür wird Speicher gespart.

```sh
zfs set compression=lz4 tankname
```

Quelle: `man zfs`

## Samba & Filesystem ACLs

Eher weniger ein Performance- als ein Usability Problem.
Folgende Befehle sorgen dafür, dass Dateiberechtigungen über
Samba von einem Windows PC aus änderbar sind.

```sh
zfs set acltype=posixacl tankname
zfs set aclinherit=passthrough tankname
```

Man beachte auch die Änderungen am Samba Setup, welche Jascha
[in seinem Blog](https://www.ja-ki.eu/2016/09/19/gedaechtnisstuetze-acls-mit-zfs-on-linux-und-samba-4-5/)
beschreibt.

Quelle: [ja-ki.eu](https://www.ja-ki.eu/2016/09/19/gedaechtnisstuetze-acls-mit-zfs-on-linux-und-samba-4-5/)