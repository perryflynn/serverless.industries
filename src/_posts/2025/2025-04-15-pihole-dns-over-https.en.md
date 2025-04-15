---
author: christian
title: Force Devices to use Pi-hole
locale: en
tags: [ dns, opnsense, network ]
---

Setting up [Pi-hole](https://pi-hole.net) on a Raspberry Pi or as Docker Container is not hard. 
The howto's are great and there is not much to do in a Terminal. But some devices just denying to 
use the Pi-hole DNS. They have DNS Servers hardcoded in or even use
[DNS over HTTPS][doh] / [DNS over TLS][dot].

[doh]: https://de.wikipedia.org/wiki/DNS_over_HTTPS
[dot]: https://en.wikipedia.org/wiki/DNS_over_TLS

## Redirect DNS Queries

DNS Queries are sent unencrypted on Port 53/udp. Sometimes also on Port 53/tcp, 
but that's mostly DNS Updates and other unusual stuff. So we can just redirect all DNS Queries 
which leaving our network to the Pi-hole IP.

This requires to have a "proper" router like OPNSense or pfSense which allows it to setup custom 
[NAT rules][nat]. We have to create a Source NAT (SNAT) Rule.

- Interface: The LAN Devices Interface/VLAN
- Source IP: A list of devices to enforce Pi-hole
- Destination IP: NOT (192.168.0.0/16 or 10.0.0.0/8 or 172.16.0.0/12)
- Destination Port: 53 UDP
- Redirect Target IP: Your Pi-hole IP
- Redirect Target Port: 53

OPNSense &#8594; Firewall &#8594; NAT &#8594; Port Forward:

![OPNSense SNAT Configuration]({{'assets/pihole-snat.jpg' | relative_url}}){:.img-fluid}

If done correct, any DNS server should return the blocked results:

```sh
$ nslookup doubleclick.net

Name:    doubleclick.net
Addresses:  ::
          0.0.0.0

$ nslookup doubleclick.net 8.8.8.8

Name:    doubleclick.net
Addresses:  ::
          0.0.0.0
```

## Block DNS over TLS (DoT)

This can easily blocked by the Firewall:

- Interface: The LAN Devices Interface/VLAN
- Source IP: any
- Destination IP: NOT (192.168.0.0/16 or 10.0.0.0/8 or 172.16.0.0/12)
- Destination Port: 853 TCP
- Action: Drop

## Block DNS over HTTPS (DoH)

Blocking DNS over HTTPS is very, very hard. These queries cannot be distinguished 
to normal HTTP requests.
Here the [hagezi/dns-blocklist](https://github.com/hagezi/dns-blocklists) project comes to 
the rescue. It offers many different lists to block certain services on DNS level. 

Used Lists:

- Pro Plus
- TIF (Threat Intelligence Feeds)
- DoH/VPN/Proxy Bypass

Pi-hole &#8594; Adlists:

![Pi-hole Adlist Configuration]({{'assets/pihole-adlist.jpg' | relative_url}}){:.img-fluid}

## Bonus: Run your own Recursive Resolver

DNS is organized in a tree structure. On top is [a fixed list of Root Servers][root] which know which 
TLD (.com, .de, .eu) is served by which DNS servers. The TLD DNS servers then know which Domain 
(serverless.industries, neu-deli.de) is served by which hosting providers DNS server. 

This is called [recursive resolving][recur], as every query causes actually two or more real DNS queries. 
Normally a router is just using the Internet Providers DNS server, this can be a privacy issue 
if this provider is logging and selling the customers requests.

We can just run our own recursive DNS resolver with software like 
[Unbound](https://nlnetlabs.nl/projects/unbound/about/). It's also shipped 
with OPNSense, Debian or RasperryOS for example.

Add the Unbound IP in Pi-hole &#8594; Settings &#8594; DNS as custom upstream DNS Server.

[Alot more details on that in the Pi-hole docs](https://docs.pi-hole.net/guides/dns/unbound/)

[root]: https://en.wikipedia.org/wiki/Root_name_server
[recur]: https://en.wikipedia.org/wiki/Name_server#Recursive_Resolver
[nat]: https://en.wikipedia.org/wiki/Network_address_translation
