---
author: christian
title: "Netcup KVM Server und Proxmox LXC Container"
lang: de
ref: netcup-lxc-proxmox
tags: ['linux', 'proxmox', 'server']
---

Letztens habe ich versucht, auf einem [KVM Server bei Netcup][netcup] Linux Container (LXC) zu nutzen.
Zur einfacheren Bedienbarkeit habe ich mich für [Proxmox][Proxmox] entschieden.
KVM Maschinen gehen dort zwar nur mit Aufpreis (VMX Option), aber die möchte ich
ja auch nicht nutzen.

[Proxmox]: https://www.proxmox.com/en/
[netcup]: https://www.netcup.de/vserver/
[addipv4]: https://www.netcup.de/bestellen/produkt.php?produkt=1072

**Dieser Artikel stammt aus meinem alten Blog und wurde am 29.04.2017 verfasst.**

## Hauptproblem

Wie viele andere Anbieter auch erlaubt Netcup ausgehenden Traffic nur mit der MAC Adresse des
KVM Netzwerk Interface. Legt man also eine virtuelle Netzwerkkarte für einen Container an,
wird dieser Traffic verworfen, da Netcup diese MAC Adresse nicht erlaubt.

**Hinweis: Proxmox wurde auf ein minimales Debian installiert.**

## Kernel Flags

Folgende Kernel Flags sind notwendig:

```
# /etc/sysctl.conf auf dem Netcup KVM Guest

# IPv4 Traffic forwarden/routen
net.ipv4.ip_forward=1

# IPv6 Traffic forwarden/routen
net.ipv6.conf.all.forwarding=1

# IPv6 NDP weiterleiten
net.ipv6.conf.all.proxy_ndp=1
```

Damit diese ohne Systemneustart wirksam werden:

```
# In der Netcup KVM Server Shell als root ausführen
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.proxy_ndp=1
```

## IPv4

Für "öffentliche" IPv4 Adressen in einem Container muss man eine
[zusätzliche IPv4 Adresse][addipv4] buchen. Anschließend
kann diese im VCP/SCP dem vServer zugewiesen werden.

Da zusätzliche IPv4 Adressen über die Haupt IP des KVM Servers geroutet
werden, gibt es hier keinerlei Probleme. Man kann eines der unzähligen
Beispiel Konfigurationen nutzen, die man bei Google findet.

### VServer Konfiguration

```
# /etc/network/interfaces auf dem Netcup VServer
allow-hotplug eth0
iface eth0 inet manual

auto vmbr1
iface vmbr1 inet static
        # Haupt IP des KVM Servers
        address  188.68.xxx.xxx
        netmask  22
        gateway  188.68.xxx.1
        bridge_ports eth0
        bridge_stp off
        bridge_fd 1
        # Gleiche Angabe wie bei gateway
        pointopoint  188.68.xxx.1
        bridge_hello 2
        bridge_maxage 12
        bridge_maxwait 0
        # Zusätzliche IP Adressen
        post-up route add 37.120.xxx.xxx dev vmbr1
        post-up route add 37.120.xxx.xxy dev vmbr1
        post-up route add 37.120.xxx.xxz dev vmbr1
```

Die Bridge `vmbr1` kann später in Proxmox in der Netzwerk
Konfiguration ausgewählt werden.

Für jede [zusätzliche IPv4 Adresse][addipv4] muss eine Route in der
Konfiguration hinzugefügt werden. Diese IP Adressen können dann in der
Netzwerk Konfiguration von Proxmox einem Container zugewiesen werden.

### Linux Container Konfiguration

Hier ist nichts besonderes zu beachten.
Einfach die zusätzliche IPv4 Adresse und die
IP des KVM VServers als Gateway.

```
# /etc/network/interfaces im Container
# Netzwerkinterface für IPv4
# Nutzt die vmbr1 Bridge
auto eth0
iface eth0 inet static
        address 37.120.xxx.xxx
        netmask 255.255.255.255
        # 188.68.xxx.xxx = IP des KVM VServers
        post-up ip route add 188.68.xxx.xxx dev eth0
        post-up ip route add default via 188.68.xxx.xxx dev eth0
        pre-down ip route del default via 188.68.xxx.xxx dev eth0
        pre-down ip route del 188.68.xxx.xxx dev eth0
```

## IPv6

Hier ist es bei Netcup aufwändiger. Das `/64` IPv6 Subnetz wird direkt auf den KVM Server
gerouted, ohne den Umweg über eine einzelne IPv6 Adresse. Man sich sein eigenes
Routing über die Netzwerkschnittstelle des KVM VServers basteln.

Dafür ist ein wenig [Subnetting][subnetting] nötig. Subnetting bedeutet,
dass das mitgelieferte `/64` IPv6 Subnetz in mehrere kleinere aufgeteilt wird.

[subnetting]: https://de.wikipedia.org/wiki/Subnetz

### Beispiel

- IPv6 Subnetz des KVM Servers: `2a03:4000:XXX:XXX::/64`
- Ziel Subnetzmaske: `/80`
- Neue Subnetze:
    - `2a03:4000:XXX:XXX::/80`
    - `2a03:4000:XXX:XXX:1::/80`
    - `2a03:4000:XXX:XXX:2::/80`
    - `2a03:4000:XXX:XXX:3::/80`
    - und so weiter

Das Ergebnis sind 65536 kleinere `/80` Subnetze, die alle beliebig gerouted
werden können. Eigentlich viel zu viel, man könnte auch eine kleinere Netzmaske
nutzen, allerdings fällt einem so das "ausrechnen" leichter.

Für die faulen gibt es auch einen [IPv6 Subnetting Calculator][v6calc].

[v6calc]: http://subnettingpractice.com/ipv6_subnetting.html

### KVM VServer IPv6 Konfiguration

Der KVM VServer selbst bekommt eine einzelne IPv6 Adresse aus dem
Subnetz `:1::/80`. So ist der KVM VServer inklusive
der Proxmox Verwaltung auch via IPv6 erreichbar. Diese IP dient
später auch als Gateway.

```
# /etc/network/interfaces auf dem Netcup KVM VServer
iface vmbr1 inet6 static
        address  2a03:4000:XXX:XXX:1::1
        netmask  128
        gateway  fe80::1
        post-up ip -6 route add fe80::1 dev vmbr1
        post-up ip -6 route add default via fe80::1 dev vmbr1
        post-down ip -6 route del fe80::1 dev vmbr1
        post-down ip -6 route del default via fe80::1 dev vmbr1
```

### Reine IPv6 Bridge für Proxmox

Nun muss eine weitere Bridge angelegt werden, welche sich um das
Container IPv6 Subnetz kümmert und als Bridge für die Proxmox
Netzwerk Konfiguration dient.

**Wichtig:** Dem Container muss später ein zweites Netzwerk
Interface zugewiesen werden, welches `vmbr2` nutzt. Exklusiv für IPv6.

```
# /etc/network/interfaces auf dem Netcup KVM VServer
auto vmbr2
iface vmbr2 inet6 static
        address 2a03:4000:XXX:XXX:2::1
        netmask 80
        bridge_stp off
        pre-up brctl addbr vmbr2
        post-down brctl delbr vmbr2
        # Muss für jede Container IPv6 Adresse kopiert werden
        post-up ip -6 neigh add proxy 2a03:4000:XXX:XXX:2::104 dev vmbr1
```

In der Bridge muss noch je verwendete Container IPv6 Adresse ein Eintrag für
das [IPv6 Neighbor Discovery Protocol][neigh] erstellt werden. Wieso genau
habe ich bisher leider nicht 100%ig verstanden.

[neigh]: https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol

### Linux Container Konfiguration

Auch hier Standard. Das einzig besondere ist die
**separate Netzwerkschnittstelle für IPv6**.

```
# /etc/network/interfaces im Container
# Separates Netzwerk Interface extra für IPv6
# Nutzt die vmbr2 Bridge
auto eth1
iface eth1 inet6 static
        address 2a03:4000:XXX:XXX:2::104
        netmask 80
        gateway 2a03:4000:XXX:XXX:2::1
```

Quelle: [netcup Forum, Post von Firestorm87 vom 28.02.2013 14:39](https://forum.netcup.de/administration-eines-server-vserver/vserver-server-kvm-server/4975-nested-virtualization-unter-kvm/#post52910)

## Nachtrag 2018-04-08

Per Email hat mir Dominic ein Beispiel für die Realisierung des
[IPv6 Neighbor Discovery Protocol][neigh] über den ndppd Daemon
geschickt. Ich zitiere einfach mal:

> Ich möchte einen Punkt zum IPv6 Neighbor Discovery Protocol ergänzen.
> Da es mir zu umständlich war für jeden Container einen Eintrag anzulegen und du selber schreibst,
> dass du das nicht "100% verstanden hast" habe ich noch etwas gesucht und bin auf eine Lösung gestoßen.
> Ich habe das Debian Paket "ndppd" installiert und mittels "update-rc.d ndppd defaults" aktiviert.
> Die Konfiguration unter /etc/ndppd.conf sieht dann bei mir wie folgt aus:

```
route-ttl 30000
proxy vmbr0 {
    router no
    timeout 500
    ttl 30000
    rule 2a03:4000:XXXX:XXXX:2::/80 {
    auto
    }
}
```

Vielen Dank für den Tipp.
