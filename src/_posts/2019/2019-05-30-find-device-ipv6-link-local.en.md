---
author: christian
title: Find devices with IPv6
locale: en
ref: ipv6-device-lookup
tags: [ network, ipv6, gpn19 ]
---

When connecting a device to a PC which has a network interface
configured to DHCP, you can find out the IP address with link-local.

When connecting a Raspberry Pi to a Notebook for example,
both devices will get a `169.254.0.0/16` IPv4 address
and a `fe80::/10` IPv6 address.

So far, so good. But the IP ranges are so huge, that it would take hours to
find the Raspberry Pi by port scan.

So [IPv6 Neighbor Discovery Protocol][ndp] to the rescue! The protocol
makes it possible to list all devices which are connected to your
notebook.

[ndp]: https://de.wikipedia.org/wiki/Neighbor_Discovery_Protocol

## IPv6 Multicast Ping

The NDP list shows only devices, which had communicated to each other.
So we need to issue a multicast ping. This will trigger a answer
from all members of the subnet.

We need the interface name for this. In Linux it is just the normal
interface name (`eth0`, `wlan0`, `usb0`, ...), in Windows it is
a number, which can be found in `ipconfig`:

```txt
Ethernet-Adapter Ethernet:
   Verbindungslokale IPv6-Adresse  . : fe80::9059:69ff:fed5:8dc9%3
```

In this case the interface ID is `3`. It can be found behind the
IPv6 address, separated with a `%`.

Do the ping:

```sh
# linux
ping6 ff02::1%br0
# windows
ping ff02::1%3
```

If both devices running Linux, the IPv6 Address can be found in the
`ping` output:

```txt
64 bytes from fe80::9059:69ff:fed5:8dc9%br0: icmp_seq=1 ttl=64 time=0.153 ms
64 bytes from fe80::84cd:88ff:fe97:b181%br0: icmp_seq=1 ttl=64 time=1.11 ms (DUP!)
```

See the line with the `(DUP!)` at the end.

## List Neighbors

```sh
# windows
netsh interface ipv6 show neighbors
# linux
ip -6 neigh show
```

```txt
# windows
Interface 3: Ethernet 2

Internet Address                              Physical Address   Type
--------------------------------------------  -----------------  -----------
fe80::9059:69ff:fed5:8dc9                     aa-c6-cf-a9-30-fa  Stale

# linux
fe80::9059:69ff:fed5:8dc9 dev usb0 lladdr aa:c6:cf:a9:30:fa REACHABLE
```

Now it should be at least one entry in the list where the IPv6 address
starts with `fe80:`. This should be the address of the connected device.
