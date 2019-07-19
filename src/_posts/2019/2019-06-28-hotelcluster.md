---
author: christian
title: Cluster im Hotel
language: german
tags: [linux, netzwerk, gpn19, "raspberry pi"]
---

Es fing an mit einer bekloppten Idee. Kann man in einem Hotel WLAN einen
Server (Raspberry Pi) betreiben? Ja, kann man. :-D

Hotel WLANs sind, je nach dem welcher Anbieter das Ganze verwaltet, entweder extrem
restriktiv oder offen wie ein Scheunentor. Mein Hotel zur [GPN19](https://entropia.de/GPN19)
war so ein Mittelding. Offenes WLAN, Captive Portal, aber kein Zugangscode.
Nur den Nutzungsbedingungen musste man per Klick zustimmen.

## Vorbereitungen

Im Hotel muss man irgendwie auf Raspberry zugreifen. Und das ohne ein funktionierendes WLAN/LAN zu haben.
Auf der GPN19 habe ich gelernt, dass dies am einfachsten mit [IPv6 Link Local][ipv6linklocal]
funktioniert. Egal ob Windows oder Linux.

Ist man erst mal via SSH auf dem Raspberry, muss das WLAN Netzwerk zur wpa_supplicant
konfiguration hinzugefügt werden.

```
# /etc/wpa_supplicant/wpa_supplicant.conf
# WLAN Netz definition mit der entsprechenden SSID
# und keiner Passphrase
network={
    ssid="Awesome Hotel"
    key_mgmt=NONE
}
```

Spätestens nach einem Neustart des Raspberrys sollte das Wifi Interface eine IP besitzen.

[ipv6linklocal]: {{ site.baseurl }}{% post_url 2019-05-30-find-device-ipv6-link-local %}

## Erstes Hindernis: Captive Portal

Viele Firmen und Hotels scheinen die Portal Software von iacbox.com zu benutzen. Zu erkennen
an der URL der Portalwebsite, welche meist mit `/logon/cgi/index.cgi` endet.

Für diese Portal Software hatte ich bereits für ein anderes Projekt ein Shellscript gebaut,
welches den Login automatisieren kann. Allerdings für ein WLAN welches mit Vouchers arbeitet.

Nach kleineren Anpassungen funktionierte das Script dann auch mit dem Hotel WLAN.

Vielleicht stelle ich die Scripte bald mal auf [github](https://github.com/perryflynn).

## Zweites Hindernis: NAT

Der Zugriff aus dem Internet auf die WLAN Endgeräte ist meistens gesperrt,
intern können die WLAN Geräte aber fleißig miteinander Kommunizieren.
Manchmal ist der Zugriff vom Gerät auf Internetdienste (SMTP, VPN, Steam) gesperrt, manchmal funktionieren
nur ausgewählte Dienste, manchmal funktioniert alles.

Im Falle meines Hotels habe ich keine Einschränkungen festgestellt.

Außer natürlich, dass man nicht vom Internet auf die WLAN Geräte zugreiffen konnte.

Um dies zu umgehen, habe ich mir kurzerhand einen Cloud Server bei Hetzner geklickt und
dort einen OpenVPN Tunnel eingerichtet. Dieser wird vom Raspberry Pi in Richtung Internet aufgebaut,
dementsprechend stört weder NAT noch sperrt die Firewall den Verbindungsversuch.

## Build

Ein kleines Bild des Aufbaus:

```
   +----------+
   | Internet |
   +----+-----+
        |
        v
  +-----+------+
  | VPN Server |
  +-----+------+
        |
        v
+-------+--------+
| Hotel Internet |
+-------+--------+
        |
        v
  +-----+------+
  | Hotel WLAN |
  +-----+------+
        |
        v
 +------+-------+
 | Clusterberry |
 +------+-------+
        |
        v
    +---+-----+
    | Pi Zero |
    +---+-----+
        |
        v
   +----+------+
   | Webserver |
   +-----------+
```

## Bild

Mein Raspberry Pi ist mit einem [ClusterHAT](https://clusterhat.com/) ausgestattet, welcher vier
Raspberry Pi Zero tragen kann. Der HAT verbindet die 5 Raspberrys via USB miteinander. Über
[Ethernet USB Gadget][usbgadget] können die Raspberrys via Netzwerk miteinander kommunizieren.

![Clusterberry]({{'/assets/clusterberry.jpg' | relative_url}}){:.img-fluid}

[usbgadget]: https://learn.adafruit.com/turning-your-raspberry-pi-zero-into-a-usb-gadget/ethernet-gadget

## Clusterberry network config

Der große Raspberry spannt eine Bridge um die vier Pi Zero USB Ethernet Interfaces und gibt sich selbst
die IP `10.178.193.1`. Die Pi Zeros haben die IPs `10.178.193.11` bis `10.178.193.14` zugewiesen.

```
# ethernet interface
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp

# wifi interface
allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

# pi zero usb interfaces
allow-hotplug usb0
iface usb0 inet manual

allow-hotplug usb1
iface usb1 inet manual

allow-hotplug usb2
iface usb2 inet manual

allow-hotplug usb3
iface usb3 inet manual

# create a bridge from all pi zero usb interfaces
auto br0
iface br0 inet static
address 10.178.193.1
netmask 26
bridge_ports usb0 usb1 usb2 usb3
bridge_stp off
bridge_fd 0
```

## Clusterberry OpenVPN config

Der OpenVPN Client ist mit einem statischen RSA Key als TCP Client konfiguriert
und versucht eine Verbindung zum Hetzer Cloud Server auf dem Port 443 aufzubauen.
Die Hotel Firewall hält das für einen ganz normalen `https://` Verbindungsaufbau
und lässt diesen zu.

**Ein Verbindungsversuch über 1194/udp hat NICHT funktioniert.**

Außerdem wird nach erfolgreichem Verbindungsaufbau jeglicher Traffic durch
den Tunnel geleitet.

```
dev tun
proto tcp-client

remote 116.203.xx.yyy
port 443

ifconfig 192.168.254.200 192.168.254.199

cipher AES-256-CBC
auth SHA512
verb 5
persist-key
persist-tun
persist-local-ip
keepalive 10 60
ping-timer-rem
comp-lzo adaptive

reneg-sec 3600
fast-io

# redirect ALL traffic to vpn gateway
redirect-gateway def1

user root
group root

<secret>
[...]
</secret>
```

## Clusterberry Rules

Die Firewall auf dem großen Raspberry lässt eine Auswahl an Verbindungen
auf sich selbst und auf die Pi Zeros zu. Zum Beispiel SSH und die Webserver,
welche auf Port 8080/tcp horchen.

**Achtung: Vorher sollte SSH entsprechend abgesichert werden!**

```
*filter
:INPUT DROP [19:4262]
:FORWARD DROP [2:152]
:OUTPUT ACCEPT [76:9906]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -s 127.0.0.0/8 -j ACCEPT
-A INPUT -d 127.0.0.0/8 -j ACCEPT

# allow access from cluster subnet
-A INPUT -s 10.178.193.0/26 -j ACCEPT
# allow ssh from everywhere
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT

# IMPORTANT! You need to set the following sysctl variable
# The variable enables traffic routing
# net.ipv4.ip_forward=1
-A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -p icmp -j ACCEPT

# allow forwarding from cluster subnet
-A FORWARD -s 10.178.193.0/26 -j ACCEPT
# allow cluster webservers from everywhere
-A FORWARD -d 10.178.193.0/26 -p tcp --dport 8080 -j ACCEPT
# allow cluster ssh from everywhere
-A FORWARD -d 10.178.193.0/26 -p tcp --dport 22 -j ACCEPT

COMMIT
```

## VPN Gateway OpenVPN config

Auf dem Hetzner Cloud Server ist der OpenVPN Server auf Port 443/tcp konfiguriert
und setzt bei erfolgreichem Verbindungsaufbau eine route auf das Raspberry Netzwerk.
Der OpenVPN Server muss mit root Rechten laufen, da ein Port **kleiner gleich 1024**
benutzt wird.

```
dev tun
proto tcp-server

ifconfig 192.168.254.199 192.168.254.200
route 10.178.193.0 255.255.255.192

lport 443

cipher AES-256-CBC
auth SHA512
verb 5
persist-key
persist-tun
persist-local-ip
keepalive 10 60
ping-timer-rem
comp-lzo adaptive
resolv-retry infinite
reneg-sec 3600
fast-io

user root
group root

<secret>
[...]
</secret>
```

## VPN Gateway Rules

Die Firewall des VPN Servers macht ein bisschen mehr Magie.

Hier werden mit entsprechenden NAT Regeln...

- die SSH Ports aller Raspberrys aus dem Internet erreichbar gemacht.
- der Webserver welcher auf Zero Nr. 1 läuft auf Port 80 aus dem Internet erreichbar gemacht.
- jeglicher Internet der Raspberrys ins Internet weitergeleitet.

Für das Umleiten des auf dem Gateway eingehenden Traffics auf die Raspberrys habe ich eine
**zweite IP Adresse** auf den Hetzner Cloud Server buchen lassen, welche als Einstiegspunkt aller
NAT Regeln dient. So können SSH und HTTP auf den "echten" Ports laufen, ohne das dies
auf der eigentlichen Server IP stört.

**Achtung: Dienste wie SSH müssen auch auf dem VPN Gateway abgesichert werden!**

```
*nat
:PREROUTING ACCEPT [36687:1720083]
:INPUT ACCEPT [30794:1277447]
:OUTPUT ACCEPT [353:25657]
:POSTROUTING ACCEPT [2439:139010]

# IMPORTANT! You need to set the following sysctl variable
# The variable enables traffic routing
# net.ipv4.ip_forward=1

# nat'ing webserver to pi zero 01
-A PREROUTING -d 116.203.aaa.bbb/32 -i eth0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 10.178.193.11:8080
# nat'ing ssh ports of pi zero 01-04
-A PREROUTING -d 116.203.aaa.bbb/32 -i eth0 -p tcp -m tcp --dport 2211 -j DNAT --to-destination 10.178.193.11:22
-A PREROUTING -d 116.203.aaa.bbb/32 -i eth0 -p tcp -m tcp --dport 2212 -j DNAT --to-destination 10.178.193.12:22
-A PREROUTING -d 116.203.aaa.bbb/32 -i eth0 -p tcp -m tcp --dport 2213 -j DNAT --to-destination 10.178.193.13:22
-A PREROUTING -d 116.203.aaa.bbb/32 -i eth0 -p tcp -m tcp --dport 2214 -j DNAT --to-destination 10.178.193.14:22
# nat'ing everything else to clusterberry
-A PREROUTING -d 116.203.aaa.bbb/32 -i eth0 -j DNAT --to-destination 10.178.193.1

# nat'ing outgoing internet traffic for all raspberrys
-A POSTROUTING -s 10.178.193.0/26 -o eth0 -j MASQUERADE
-A POSTROUTING -s 192.168.254.200/32 -o eth0 -j MASQUERADE
COMMIT
```
