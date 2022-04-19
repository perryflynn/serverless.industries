---
author: christian
title: Raspberry Pi 4 Benchmark
locale: de
ref: rpi4-benchmark
tags: [linux, hardware, "raspberry pi"]
---

Hier ein erster Benchmark welcher Raspberry Pi 3B und 4B vergleicht.

## SD Karte und USB Stick

<div markdown="1" class="table-responsive">

{:.table .table-bordered}
4 GiB Testfile bs=1M | Write (no cache) | Write (cache) | Read (no cache) | Read (cache)
--|--|--|--|--
Pi 3B SD | 14,6 MByte/s | 15,1 MByte/s | 23,6 MByte/s | 23,5 MByte/s
Pi 4B SD | 30,0 MByte/s | 30,5 MByte/s | 45,8 MByte/s | 60,0 MByte/s
Pi 3B USB | 9,2 MByte/s | 8,0 MByte/s | 27,1 MByte/s | 28,1 MByte/s
Pi 4B USB | 66,0 MByte/s | 54,1 MByte/s | 259 MByte/s | 265 MByte/s

</div>

- Getestet mit [iobench.sh](https://github.com/perryflynn/iobench)
- SD Karte: SanDisk Ultra 64 GB microSDXC, Class 10, U1, A1
- USB Stick: Patriot 128 GB Supersonic Rage 2 Serie USB 3.1 Gen 1

## Netzwerk Interface

<div markdown="1" class="table-responsive">

{:.table .table-bordered}
iperf3 | pc zu pi | pi zu pc
--|--|--
Pi 3B | 97,3 MBit/s | 94,7 MBit/s
Pi 4B | 905 MBit/s | 903 MBit/s

</div>

- Getestet mit iperf3
- Gigabit Netzwerk über CAT 6 Kabel, reines Layer 2
