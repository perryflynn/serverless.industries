---
author: christian
title: Ursachen für Verbindungsprobleme
lang: de
tags: [ 'software development', server, network, linux ]
toc: true
---

Oft sagen die Fehlermeldungen schon, was das Problem ist.
Und wenn nicht, gibt es Tools welche bei jeder Linux Distribution dabei
sind und einem beim debuggen helfen können.

## Fehlermeldungen

Alleine aus den Fehlermeldungen kann man schon eine Menge herauslesen
und eingrenzen ob es ein Benutzer-, Verbindungs-, Server- oder Firewallproblem ist.

### Address/Network unreachable

- Netzwerkproblem
- IP Adresse / Hostname richtig geschrieben?
- Bist Du im richtigen LAN/WLAN/VPN?
- Ist das Zielsystem angeschaltet?
- Ist das Zielsystem im richtigen LAN/WLAN/VPN?
- Sind die IP Routen richtig gesetzt?

### Connection timed out

- In fast allen Fällen ein Firewall Problem
- Kann auch ein Problem beim Internet Provider oder Transit Providern sein

### Connection refused

- Problem auf dem Zielsystem oder der falsche Port wird vom Quellsystem angesprochen
- Ist der Service auf dem Zielsystem gestartet?
- Horcht der Service auf dem richtigen (nicht localhost) Netzwerk Interface?

Unwahrscheinlich aber möglich: Eine Firewall kann eine Verbindung auch ablehnen (REJECT),
anstatt sie komplett zu ignorieren (DROP) und in ein Timeout laufen zu lassen.
Das kann auch ein `Connection refused` Fehler hervorrufen.

### Connection closed by remote host

- Der Serverdienst hat sich aktiv dazu entschieden die Verbindung abzuweisen
- Könnte ein Sicherheitsfeature des Service sein
- Könnte `/etc/hosts.deny` und/oder `/etc/hosts.allow` sein

### Certificate Authority Invalid

- Sieht man oft im Browser bei selbst betriebenen Services
- Der Dienst macht TLS/SSL aber das Zertifikat oder dessen Certificate Authority ist
  nicht im Browser hinterlegt
- Wenn das ein lokaler Dienst ist kann das oft ignoriert werden
- Wenn das ein Dienst im Internet ist wo man das nicht erwartet, Vorsicht!
  Könnte ein Versuch sein an Deine Daten zu kommen.
- Domains können je nach Netz auch auf unterschiedliche Ressourcen zeigen.
  Ist der aufgerufene Dienst vielleicht nur aus einem bestimmten LAN/VPN erreichbar?

### DNS Probe finished: NXDOMAIN

- Domain Name konnte nicht aufgelöst werden
- Domain richtig geschrieben?
- Bist Du im richtigen LAN/VPN und benutzt somit den richtigen DNS Server?

### DNS Probe finished: SERVFAIL

- Problem mit dem DNS Server

## Tools

Die Tools finden sich in allen gängigen Linux Distributionen in den Paket Quellen.

### ping / ping6

- Verbindungstest über ICMP
- Hilfreich für einen "Funktioniert überhaupt irgendetwas?" Test

Gerade in Unternehmensnetzwerken mit Firewalls sagt ping aber nichts aus.
Ping kann funktionieren, ein HTTP/HTTPS Service aber trotzdem nicht.

Man sollte lieber ein Tool passend zum Protokoll verwenden.

```txt
$ ping example.com
PING example.com (93.184.216.34) 56(84) bytes of data.
64 bytes from 93.184.216.34 (93.184.216.34): icmp_seq=1 ttl=56 time=97.3 ms
64 bytes from 93.184.216.34 (93.184.216.34): icmp_seq=2 ttl=56 time=97.4 ms
64 bytes from 93.184.216.34 (93.184.216.34): icmp_seq=3 ttl=56 time=97.3 ms
^C
--- example.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 97.309/97.367/97.402/0.258 ms
```

### telnet

- Prüft ob ein TCP (HTTP, SSH, ...) Port geöffnet ist
- Wird eine Verbindung hergestellt ist der Service erreichbar
- Erscheint eine [Fehlermeldung](#fehlermeldungen), ist der Service nicht erreichbar

```txt
$ telnet example.com 80
Trying 93.184.216.34...
Connected to example.com.
Escape character is '^]'.

$ telnet localhost 8123
Trying 127.0.0.1...
telnet: Unable to connect to remote host: Connection refused
```

### tcpdump

Mit `tcpdump` kann man sich den Traffic auf einem Netzwerk Interface anschauen.
Im folgenden Beispiel wird auf dem Server auf dem Interface `eth0` jeglicher
Traffic angezeigt, welcher auf Port `53` (egal ob UDP oder TCP) ankommt.

Auch die Antwort wird angezeigt.

```txt
# tcpdump -n -i eth0 port 53
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
22:59:38.499103 IP 84.177.249.123.61685 > 93.184.216.34.53: 29536+ A? example.com. (28)
22:59:38.499367 IP 93.184.216.34.53 > 84.177.249.123.61685: 29536 Refused- 0/0/0 (28)
```

### nslookup

Prüft ob eine Domain aufgelöst werden kann und welche IP Adresse 
sich dahinter verbirgt.

Als zweiten Parameter kann man auch einen abweichenden DNS Server angeben.
Hilfreich wenn man sicher gehen will, dass es nicht am eigenen DNS Server
liegt.

```txt
$ nslookup example.com
Server:     127.0.0.53
Address:    127.0.0.53#53

Non-authoritative answer:
Name:    example.com
Address: 93.184.216.34

$ nslookup example.com 8.8.8.8
Server:     8.8.8.8
Address:    8.8.8.8#53

Non-authoritative answer:
Name:    example.com
Address: 93.184.216.34
Name:    example.com
Address: 2606:2800:220:1:248:1893:25c8:1946
```

### nmap

- Ein Port Scanner
- Findet offene Ports auf einem System

```txt
$ nmap 192.168.42.1 -PN

Starting Nmap 7.60 ( https://nmap.org ) at 2021-08-08 13:40 CEST
Nmap scan report for _gateway (192.168.42.1)
Host is up (0.00042s latency).
Not shown: 995 filtered ports
PORT    STATE SERVICE
22/tcp  open  ssh
53/tcp  open  domain
80/tcp  open  http
199/tcp open  smux
443/tcp open  https

Nmap done: 1 IP address (1 host up) scanned in 4.56 seconds

$ nmap 192.168.42.1 -p 443 -PN

Starting Nmap 7.60 ( https://nmap.org ) at 2021-08-08 13:39 CEST
Nmap scan report for _gateway (192.168.42.1)
Host is up (0.00033s latency).

PORT    STATE SERVICE
443/tcp open  https

Nmap done: 1 IP address (1 host up) scanned in 0.05 seconds
```
