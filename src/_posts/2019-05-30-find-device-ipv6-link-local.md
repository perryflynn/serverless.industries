---
author: christian
language: german
title: Geräte über IPv6 finden
tags: [ network, ipv6 ]
---

Möchte man sich auf ein Gerät verbinden welches auf DHCP
konfiguriert ist, jedoch steht kein DHCP Server zur Verfügung, 
bietet sich Link-Local an.

Schließt man zum Beispiel einen Raspberry Pi an ein
Notebook an, erhalten beide Seiten eine
`169.254.0.0/16` IPv4 Adresse und eine `fe80::/10` IPv6 Adresse.

Soweit so gut. Das Problem beginnt erst, wenn man die IP Adresse
des angeschlossenen Gerätes herausfinden will. Die IP Blöcke sind
so groß, daß ein Port Scan ewig dauert und nicht zielführend ist.

Hier kommt das [IPv6 Neighbor Discovery Protocol](https://de.wikipedia.org/wiki/Neighbor_Discovery_Protocol)
wie gerufen. Hierüber lassen sich die IPv6 Adressen aller angeschlossenen
Geräte auflisten.

```
# windows
netsh interface ipv6 show neighbors
# linux
ip -6 neigh show
```

## IPv6 Multicast Ping

Eine Alternative ist IPv6 Multicast Ping. 

In den Antworten die Ping anzeigt finden sich dann die IP Adressen aller im
Netzwerk befindlichen Geräte als `(DUP!)` Eintrag.

```
# linux
ping6 ff02::1%br0
```

```
64 bytes from fe80::9059:69ff:fed5:8dc9%br0: icmp_seq=1 ttl=64 time=0.153 ms
64 bytes from fe80::84cd:88ff:fe97:b181%br0: icmp_seq=1 ttl=64 time=1.11 ms (DUP!)
```

Hinter dem Prozentzeichen muss der Interface Name angegeben werden.
Mit Windows Geräten scheint diese Technik allerdings **nicht zu funktionieren**.
