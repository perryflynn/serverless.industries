---
author: christian
title: Bind9 Rekursion über IPv6 verhindern
locale: de
tags: [ linux, server, dns ]
---

Wer einen rekursiven DNS Resolver (einen DNS Server für Endanwender Geräte)
betreibt, wird eventuell schon mal über folgende Fehler gestolpert sein.

Diese erscheinen immer dann, wenn bind versucht eine DNS Abfrage an
einen anderen DNS Server über dessen IPv6 Adresse weiterzuleiten,
obwohl der eigene Internet Anschluss nicht IPv6-fähig ist.

```txt
Oct  3 22:58:45 ns named[13968]: network unreachable resolving 'ns-1289.awsdns-33.org/AAAA/IN': 2600:9000:5300:a100::1#53
Oct  3 22:58:45 ns named[13968]: network unreachable resolving 'ns-568.awsdns-07.net/A/IN': 2600:9000:5307:8700::1#53
Oct  3 22:58:45 ns named[13968]: network unreachable resolving 'production.cloudflare.docker.com/AAAA/IN': 2600:9000:5305:900::1#53
Oct  3 22:58:45 ns named[13968]: network unreachable resolving 'ns-207.awsdns-25.com/AAAA/IN': 2600:9000:5306:d900::1#53
```

In dem man in die `/etc/bind/named.conf` folgende Zeile einfügt, kann
dieses Fehlverhalten verhindert werden:

```conf
server ::/0 { bogus yes; };
```

Damit wird jegliche Kommunikation die via IPv6 versendet oder empfangen wird,
als "bogus", also fake/quatsch/sinnlos ignoriert.
