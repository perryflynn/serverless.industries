---
author: christian
title: Cluster im Hotel
language: german
tags: [linux, netzwerk, gpn19]
---

## Build

```
   +----------+
   | Internet |
   +----+-----+
        |
        |
        v
  +-----+------+
  | VPN Server |
  +-----+------+
        |
        |
        v
+-------+--------+
| Hotel Internet |
+-------+--------+
        |
        |
        v
  +-----+------+
  | Hotel WLAN |
  +-----+------+
        |
        |
        v
 +------+-------+
 | Clusterberry |
 +------+-------+
        |
        |
        v
    +---+-----+
    | Pi Zero |
    +---+-----+
        |
        |
        v
   +----+------+
   | Webserver |
   +-----------+
```

## Clusterberry Rules

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

## Clusterberry OpenVPN config

```
dev tun
proto tcp-client

remote 116.203.23.169
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

## Clusterberry network config

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

## VPN Gateway Rules

```
*nat
:PREROUTING ACCEPT [36687:1720083]
:INPUT ACCEPT [30794:1277447]
:OUTPUT ACCEPT [353:25657]
:POSTROUTING ACCEPT [2439:139010]

# nat'ing webserver to pi zero 01
-A PREROUTING -d 116.203.164.230/32 -i eth0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 10.178.193.11:8080
# nat'ing ssh ports of pi zero 01-04
-A PREROUTING -d 116.203.164.230/32 -i eth0 -p tcp -m tcp --dport 2211 -j DNAT --to-destination 10.178.193.11:22
-A PREROUTING -d 116.203.164.230/32 -i eth0 -p tcp -m tcp --dport 2212 -j DNAT --to-destination 10.178.193.12:22
-A PREROUTING -d 116.203.164.230/32 -i eth0 -p tcp -m tcp --dport 2213 -j DNAT --to-destination 10.178.193.13:22
-A PREROUTING -d 116.203.164.230/32 -i eth0 -p tcp -m tcp --dport 2214 -j DNAT --to-destination 10.178.193.14:22
# nat'ing everything else to clusterberry
-A PREROUTING -d 116.203.164.230/32 -i eth0 -j DNAT --to-destination 10.178.193.1

# nat'ing outgoing internet traffic for all raspberrys
-A POSTROUTING -s 10.178.193.0/26 -o eth0 -j MASQUERADE
-A POSTROUTING -s 192.168.254.200/32 -o eth0 -j MASQUERADE
COMMIT
```

## VPN Gateway OpenVPN config

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
