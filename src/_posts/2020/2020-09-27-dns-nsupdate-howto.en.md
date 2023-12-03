---
author: christian
title: "DNS Updates with nsupdate"
locale: en
ref: nsupdate-howto
tags: [linux, dns, projects]
excerpt_separator: <!-- more -->
---

A few DNS zone which I maintain don't have a web interface to edit
the records. I am required to use [RFC2136][rfc2136] nsupdate.

[rfc2136]: https://tools.ietf.org/html/rfc2136
[axfr]: https://en.wikipedia.org/wiki/DNS_zone_transfer

## Preparations in Nameserver

The domain owner assigned me a HMAC key in his nameserver (bind9)
configuration which has the permission to perform updates and
Zone Transfers (show all records in dig).

<!-- more -->

```txt
key "my-awesome-keyname" {
    algorithm hmac-sha256;
    secret "THEKEYINBASE64FORMAT";
};

zone "example.com" {
    type master;
    file "/var/lib/bind/db.example.com";
    allow-query { any; };
    allow-transfer {
        192.168.94.254;
        key my-awesome-keyname;
    };
    update-policy {
        grant my-awesome-keyname zonesub ANY;
        grant rndc-key zonesub ANY;
    };
};
```

The name of the key and the key itself must be specified in `dig` and
`nsupdate` to perform queries and update. They are the username and
password.

## Find the authoritative name server

To make updates, we need to know the authoritative dns server of the Zone.
Their address can be found in the zones `SOA` record.

```sh
dig -t SOA example.com
```

```txt
; <<>> DiG 9.11.3-1ubuntu1.13-Ubuntu <<>> -t SOA example.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 15096
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;example.com.            IN    SOA

;; ANSWER SECTION:
example.com.        3599    IN    SOA    ns1.exampleprovider.com. webmaster.exampleprovider.com. 2020100405 3600 900 2419200 60

;; Query time: 18 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Sun Oct 25 21:33:54 CET 2020
;; MSG SIZE  rcvd: 107
```

In this case, the authoritative name server is `ns1.exampleprovider.com`.

## Show all zone entries

If the key has `allow-transfer` permissions, it is possible to
perform a `AXFR` query ([see here][axfr]) with dig. This will
return all records from the given Zone.

```sh
HMAC=hmac-sha256:my-awesome-keyname:THEKEYINBASE64FORMAT
dig @ns1.exampleprovider.com -y $HMAC -t AXFR example.com
```

```txt
; <<>> DiG 9.11.3-1ubuntu1.13-Ubuntu <<>> @ns1.exampleprovider.com -y hmac-sha256 -t AXFR example.com
; (1 server found)
;; global options: +cmd
example.com.         3600  IN  SOA   ns1.exampleprovider.com. webmaster.exampleprovider.com. 2020051216 3600 900 2419200 60
example.com.          900  IN  TXT   "v=spf1 +mx -all"
example.com.          900  IN  TXT   "Hello Nerds, how are you going?"
example.com.         3600  IN  MX    10 example.com.
example.com.         3600  IN  AAAA  ::1
example.com.         3600  IN  A     127.0.0.1
example.com.         3600  IN  NS    ns1.exampleprovider.com.
example.com.         3600  IN  NS    ns2.exampleprovider.com.
example.com.         3600  IN  NS    ns3.exampleprovider.com.
*.example.com.       3600  IN  AAAA  ::1
*.example.com.       3600  IN  A     127.0.0.1
gitlab.example.com.   900  IN  AAAA  ::2
gitlab.example.com.   900  IN  A     127.0.0.2
meet.example.com.     900  IN  AAAA  ::3
meet.example.com.     900  IN  A     127.0.0.3
```

## Send DNS Updates

`nsupdate` makes it possible to perform changes on a DNS zone without
restarting the DNS Server. Like with dig, it requires a HMAC key
and dns server address.

```sh
HMAC=hmac-sha256:my-awesome-keyname:THEKEYINBASE64FORMAT
nsupdate -y $HMAC
```

Now a interactive shell appears:

```txt
server ns1.exampleprovider.com
update delete example.com.   900  IN  TXT   "Hello Nerds, how are you going?"
update add example.com.   900  IN  TXT   "Hello Nerds, how are you going? :-)"
send
```

The `send` command ends the interactive mode and sends all commands to the
name server. If there are no error messages, everything was successful.
This can be checked with `dig`.

```sh
dig @ns1.exampleprovider.com example.com TXT
```

```txt
; <<>> DiG 9.11.3-1ubuntu1.13-Ubuntu <<>> @exampleprovider.com example.com TXT
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12843
;; flags: qr aa rd; QUERY: 1, ANSWER: 2, AUTHORITY: 3, ADDITIONAL: 7
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 3090d108ac14015b0332e54e5f6fb5300322a213a7e360c1 (good)
;; QUESTION SECTION:
;example.com.            IN    TXT

;; ANSWER SECTION:
example.com.  900  IN  TXT  "v=spf1 +mx -all"
example.com.  900  IN  TXT  "Hello Nerds, how are you going? :-)"
```

Success. :-)

## nsupdate-interactive.py

[nsupdate-interactive.py](https://github.com/perryflynn/nsupdate-interactive)
is a Python Script which I have developed to make editing zones by `nsupdate`
much more easier.

It creates a Zone file and opens this file in you perferred editor. Afterwards
it checks the syntax of the zone file with `named-checkzone` and creates a
`nsupdate` batch file by diff your changes.

```diff
--- nsupdate_ns1.example.com_example.com_20200926T222019Z.org    2020-09-26 22:20:19.369097326 +0200
+++ nsupdate_ns1.example.com_example.com_20200926T222019Z.new    2020-09-26 22:20:33.768947883 +0200
@@ -49,7 +49,7 @@
 ;; Create new records
 ;; Feel free to add/modify records here
 update add example.com.   900  IN  TXT   "v=spf1 +mx -all"
-update add example.com.   900  IN  TXT   "Hello Nerds, how are you going?"
+update add example.com.   900  IN  TXT   "Hello Nerds, how are you going? :-)"
 update add example.com.  3600  IN  MX    10 example.com.
 update add example.com.  3600  IN  AAAA  ::1
 update add example.com.  3600  IN  A     127.0.0.1
```

If the changes are confirmed by pressing `ENTER`, the script sends the changes
to the dns server.
