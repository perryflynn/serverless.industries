---
author: christian
language: german
title: Geräte über IPv6 finden
tags: [ network, ipv6, gpn19 ]
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

## IPv6 Multicast Ping

Vorher sollte man einen IPv6 Multicast `ping` ausführen.
Dabei sendet man einfach einen ping an die Adresse `ff02::1%interfacename`.
Dies sorgt dafür, dass die Link-Local IPv6 Adresse garantiert in der Neighbor
Liste auftaucht. 

Unter Linux ist der Interfacename die übliche Bezeichnung (`eth0`, `wlan0`, `usb0`, ...),
unter Windows ist es eine ID welche man über `ipconfig` herausfinden kann:

```
Ethernet-Adapter Ethernet:
   Verbindungslokale IPv6-Adresse  . : fe80::9059:69ff:fed5:8dc9%3
```

In dem Beispiel hat das Interface die ID `3`, zu erkennen an dem `%3` hinter der
IPv6 Adresse.

```
# linux
ping6 ff02::1%br0
# windows
ping ping6 ff02::1%3
```

Handelt es sich bei beiden Systemen (Sender und Empfänger) um Linux, findet man
jetzt im `ping` schon die IP Adresse in den Antworten:

```
64 bytes from fe80::9059:69ff:fed5:8dc9%br0: icmp_seq=1 ttl=64 time=0.153 ms
64 bytes from fe80::84cd:88ff:fe97:b181%br0: icmp_seq=1 ttl=64 time=1.11 ms (DUP!)
```

In der Zeile mit dem `(DUP!)` Eintrag findet man mit hoher
Wahrscheinlichkeit die IP des Zielgerätes.

## Neighbors auflisten

```
# windows
netsh interface ipv6 show neighbors
# linux
ip -6 neigh show
```

```
# windows
Interface 3: Ethernet 2

Internet Address                              Physical Address   Type
--------------------------------------------  -----------------  -----------
fe80::9059:69ff:fed5:8dc9                     aa-c6-cf-a9-30-fa  Stale

# linux
fe80::9059:69ff:fed5:8dc9 dev usb0 lladdr aa:c6:cf:a9:30:fa REACHABLE
```

In der Liste der Neighbors müsste sich mindestens ein Eintrag
befinden, wo die IP mit `fe80:` beginnt. Mit hoher Wahrscheinlichkeit
ist das die IP des Zielgerätes.
