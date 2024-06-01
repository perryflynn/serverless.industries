---
author: christian
title: "DNS Updates mit nsupdate"
locale: de
ref: nsupdate-howto
tags: [linux, dns, projects, projects:nsupdate-interactive]
---

Seit einiger Zeit betreue ich ein paar DNS Zones, wo der Besitzer
mir kein Web Interface zur Verfügung stellt, sondern einen
HMAC Key für [RFC2136][rfc2136] nsupdate.

[rfc2136]: https://tools.ietf.org/html/rfc2136
[axfr]: https://en.wikipedia.org/wiki/DNS_zone_transfer

## Vorbereitungen im Nameserver

Der Besitzer der Domain hat dabei den Key in seinem Nameserver
(bind9) hinterlegt und für `update` (Records verändern)
und `transfer` (gesamte Zone via dig anzeigen) berechtigt.

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

Der Name des Keys und der Key selbst müssen dann bei `dig` Abfragen
oder beim Aufruf von `nsupdate` angegeben werden. Sie dienen sozusagen
als Benutzername und Passwort.

## Den authoritative Name Server finden

Updates können nur an authoritative DNS Server gesendet werden.
Welcher Server dies ist, ist im `SOA` record der Zone hinterlegt.

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

Der authoritative DNS Server ist also `ns1.exampleprovider.com`.

## Zone Einträge anzeigen

Sofern der HMAC Key `allow-transfer` Rechte besitzt, kann man
mit `dig` die komplette Zone anzeigen lassen.
Dafür wird der DNS Query Type `AXFR` ([siehe hier][axfr]) verwendet.

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

## DNS Updates senden

Mit `nsupdate` können Änderungen an der DNS Zone an den DNS Server
gesendet werden. Auch hier wieder mit Angabe des DNS Servers und des
HMAC Keys.

```sh
HMAC=hmac-sha256:my-awesome-keyname:THEKEYINBASE64FORMAT
nsupdate -y $HMAC
```

Dann geht es interaktiv weiter:

```txt
server ns1.exampleprovider.com
update delete example.com.   900  IN  TXT   "Hello Nerds, how are you going?"
update add example.com.   900  IN  TXT   "Hello Nerds, how are you going? :-)"
send
```

Der `send` Befehl beendet den interaktiven Modus von `nsupdate` und sendet
das Update an den DNS Server. Erscheinen keine Fehlermeldungen sollte
das Update erfolgreich gewesen sein und man kann sich das Ergebnis in `dig`
anschauen.

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

Mit [nsupdate-interactive.py](https://github.com/perryflynn/nsupdate-interactive)
habe ich dazu ein kleines Python Script geschrieben, welches automatisch eine
Update Datei für `nsupdate` erzeugt, welche mit einem Editor bearbeitet werden kann.

Danach wird `named-checkzone` verwendet, um das Zonefile auf Syntaxfehler zu überprüfen.
Sofern keine Fehler gefunden wurde, erzeugt das Script anschließend aus einem Diff ein
nsupdate Batch File.

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

Wird der Diff mit `ENTER` bestätigt, führt das Script automatisch `nsupdate` aus, welches die
Änderungen an den Nameserver sendet.
