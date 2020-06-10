---
author: christian
title: "OPNSense/FreeBSD und Bridges"
lang: de
ref: freebsd-bridges
tags: ['opnsense', 'freebsd', 'network']
---

Kommt man als langjähriger Linux User das erste Mal mit Bridges unter FreeBSD
(in Form von pfSense bzw OPNSense) in Berührung, ist man mit
hoher Wahrscheinlichkeit verwirrt.

Zwischen den Interfaces der Bridge kann keine Kommunikation stattfinden, außer man setzt
Firewall Regeln für die beteiligten Interfaces. Richtig gehört: FreeBSD filtert auf OSI Layer 3
den Traffic innerhalb einer Bridge.

Das Ganze nennt sich [Filtering Bridges][bsdbridge]
und soll Hilfreich sein, um ein physikalisches Netz in mehrere Segmente zu unterteilen.

Mit verschiedenen `sysctl` Flags kann eingestellt werden, was auf OSI Layer 2 und OSI Layer 3
gefiltert werden soll. So ist es zum Beispiel möglich Layer 3 (IP, TCP, UDP) zu filtern,
Layer 2 (Ethernet, ARP, ...) jedoch ungehindert durch die Bridge laufen zu lassen.

Ich lasse die Frage, ob das eine gute Idee ist, einfach mal im Raum stehen.

Ein Kumpel meinte dazu folgendes:

> Sind die auf Crack?

Unter pfSense und OPNSense kann das Standardverhalten, wie man es von Linux kennt, mit der Änderung von
zwei System Tunables (`sysctl` Variablen) herbei geführt werden:

```txt
net.link.bridge.pfil_member = 0
net.link.bridge.pfil_bridge = 0
```

Anschließend behandelt das System Bridges ganz normal auf OSI Layer 2. Sprich man hat einen
virtuellen Switch, der Traffic wird nicht gefiltert.

Weitere `sysctl` Variablen finden sich in der FreeBSD Manpage.

**Dieser Artikel stammt aus meinem alten Blog und wurde am 16.03.2018 verfasst.**

Quellen:

- [FreeBSD Documentation][bsdbridge]
- [FreeBSD if_bridge Manpage](https://www.freebsd.org/cgi/man.cgi?query=bridge&sektion=4&manpath=FreeBSD+11.1-RELEASE+and+Ports)
- [OPNSense Documentation](https://docs.opnsense.org/manual/how-tos/transparent_bridge.html)

[bsdbridge]: https://www.freebsd.org/doc/en_US.ISO8859-1/articles/filtering-bridges/index.html
