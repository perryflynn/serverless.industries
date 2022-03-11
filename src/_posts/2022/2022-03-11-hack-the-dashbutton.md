---
author: christian
title: 'Amazon Dashbutton als IoT Button'
lang: de
tags: [ linux, network, 'amazon dash button', projects ]
---

Seit kurzem sind Amazons Dash Buttons auch in Deutschland verfügbar.
Ein daumengroßer Button, welcher sich in ein WLAN einbucht und ein Event abschickt.

Eigentlich ist dieser dazu gedacht, nach Einrichtung mit der Amazon App,
Produkte im Amazon Store im einem Klick bestellbar zu machen. Man soll diese Buttons
im Haus verteilen, und damit Verbrauchsprodukte nachbestellen.

**Dieser Artikel wurde 2017 in meinem alten Blog anysrc.net veröffentlicht.**

## Netzwerk Setup - Normaler Haushalt

Der Trick ist einfach, bei der Einrichtung kein Produkt zu wählen.
So wird bei Betätigung des Buttons passiert dann einfach nichts.

- Amazon App installieren
- Login
- Mein Konto -> Meine Geräte -> Neuer Dash Button
- Anweisungen folgen
- Bei der Auswahl der Produkts **nichts wählen und App schließen**
- Fertig

## Hack, der keiner ist

Anstatt die Firmware des Dash Buttons anzugreifen, machen wir uns einfach der Stromsparfunktion
des Button zunutze. Der Button ist nur ganz kurz im Netzwerk online um die Bestellung abzusenden.
Danach geht dieser direkt wieder offline, um Strom zu sparen.

Unser Linux Rechner muss sich im Subnetz des Dash Buttons befinden. Mit iptables wird das DHCPDISCOVER,
ein Datenpaket welches eine IP Adresse vom DHCP Server anfordert, geloggt und anschließend von 
unserem Script weiterverarbeitet. Aus diesem Log Eintrag geht die MAC Adresse des Buttons hervor,
welche zur Identifikation genutzt wird.

### MAC Adresse herausfinden

Die MAC Adresse des Dash Buttons brauchen wir für die Scripte. Entweder man schaut im DHCP Server in der Liste
der aktuellen Leases, oder loggt kurz den Traffic im Subnetz mit Wireshark.

Das sollte ungefähr so aussehen:

```sh
$ tshark -i eth1
  1   0.000000 50:f5:da:xx:xx:xx -> Broadcast    LLC 60 S P, func=RNR, N(R)=64; DSAP NULL LSAP Individual, SSAP NULL LSAP Command
  2   0.031323      0.0.0.0 -> 255.255.255.255 DHCP 303 DHCP Request  - Transaction ID 0x6ce7ec6b
```

### ulogd

Geloggt wird natürlich nicht einfach in eine Datei. Der ulogd kann auch mit FIFO Pipes umgehen,
sodass der Logeintrag direkt ohne Verzögerung an ein Shellscript weiter gegeben werden kann.

Damit der User welcher das Script ausführt und auch ulog auf das FIFO File zugreifen können,
muss ulog Mitglied in der Gruppe des amdash Users befinden.

```sh
apt-get install ulogd
groupapp amdash
useradd -G amdash -s /bin/bash -d /home/amdash -m amdash
gpasswd -a ulog amdash
mkfifo /tmp/ulogdash.fifo
chmod ug=rw,o=- /tmp/ulogdash.fifo
```

ulogd Konfiguration:

```
stack=logdash:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str1:IP2STR,print1:PRINTPKT,emudash:LOGEMU

[logdash]
group=1

[emudash]
file="/tmp/ulogdash.fifo"
sync=1
```

Neustart von ulogd nicht vergessen. Anschließend im syslog prüfen ob alles korrekt
gestartet ist.

### iptables

In iptables wird eine neue Chain erstellt, auf welche anhand der MAC Adresse des Gerätes
weitergeleitet wird. Innerhalb der Chain wird der Log Eintrag für das DHCP Discover abgesendet.

```
iptables -N AMDASH
iptables -A INPUT -m mac --mac-source ac:63:be:xx:xx:xx -j AMDASH
iptables -A INPUT -m mac --mac-source ac:63:b3:xx:xx:xx -j AMDASH
iptables -A AMDASH -d 255.255.255.255 -j NFLOG --nflog-group 1 --nflog-prefix "AMDASH"
iptables -A AMDASH -j RETURN
```

### Script

Das Script liest in einer Endlosschleife das FIFO File Zeile für Zeile.
Es wird aus dem Log Eintrag die MAC Adresse extrahiert und versucht,
einen Symlink für diese MAC Adresse zu finden, welcher dann auf das eigentliche
Script zeigt.

Anschließend wird das Script dann ausgeführt.

[Vollständiges Script mit Beschreibung auf github](https://github.com/perryflynn/amazon-dashbutton-pipe)

### Mapping

Durch den Mapping Mechanismus weiß man schon durch das simple Auflisten des
Verzeichnisinhalts, welche MAC Adresse hinter welchem Dash Button steckt.

```sh
amdash@iot:~/dash$ ls -lisa by-mac/
2752545 4 drwxr-xr-x 12 amdash amdash 4096 Apr  7 22:17 .
2752546 4 drwxr-xr-x  8 amdash amdash 4096 Jul 20 08:46 ..
2752548 4 drwxr-xr-x  2 amdash amdash 4096 Sep 23  2016 ac:63:be:e3:ff:ff

amdash@iot:~/dash$ ls -lisa by-id/
2752561 4 drwxr-xr-x 2 amdash amdash 4096 Apr  7 22:18 .
2752546 4 drwxr-xr-x 8 amdash amdash 4096 Jul 20 08:46 ..
2752550 0 lrwxrwxrwx 1 amdash amdash   28 Sep 22  2016 001 -> ../by-mac/ac:63:be:e3:ff:ff/

amdash@iot:~/dash$ ls -lisa by-name/
2752549 4 drwxr-xr-x 2 amdash amdash 4096 Jul 20 00:06 .
2752546 4 drwxr-xr-x 8 amdash amdash 4096 Jul 20 08:46 ..
2752551 0 lrwxrwxrwx 1 amdash amdash   13 Sep 22  2016 radio-bath -> ../by-id/001/
```

Die einzelnen Symlinks erlauben es dann, den Dash Button über eine Nummer oder einen Alias Namen zu
identifizieren. Im Logging taucht auch immer die Nummer und der Klarname mit auf. Die MAC benötigt
man also nach der ersten Einrichtung nicht mehr.

## Alternative ARP Sniffing

Ein Kumpel hatte mich auf die Idee mit iptables und ulog gebracht. 

Fast alle Beispiele die man im Netz findet suchen wiederholt nach der MAC Adresse
des Dash Buttons indem entsprechende ARP anfragen abgefeuert werden.

Im Gegensatz dazu verwendet dieser Ansatz den Linux Kernel bzw iptables, welche ja sowieso vorhanden sind.
Es werden wenig bis gar keine Ressourcen verwendet, solange sich das Script im Leerlauf befindet.

## Fallstricke seitens Amazon

- Amazon App zur Einrichtung der Buttons benötigt
- Einrichtung nur möglich, wenn das WiFi Netzwerk / der Dash Button Internetzugang hat
- Ohne Produkt wird bei jedem Drücken auf den Button eine Push Nachricht in der Amazon App verursacht
- Entfernt man den Button aus seinem Konto ohne vorher das Internet für den Button zu sperren, wird beim nächsten Drücken des Buttons die Konfiguration gelöscht

## Netzwerk Setup - Profi Haushalt

Ich beschreibe die Einrichtung des Netzwerks nicht im Detail.
Wer die Technik daheim hat um das umzusetzen, weiß auch wie man das macht.

Mich hat es gestört, dass bei jeder Betätigung des Dash Buttons eine Anfrage an Amazon gesendet wird.
Mein UniFi AP erlaubt das erstellen von mehreren WiFi Netzen. Also ein neues VLAN im Router eingerichtet
und ein IoT Wifi Netzwerk erstellt.

Im gleichen Netzwerk befindet sich auch der Linux Rechner, welcher per getaggten LAN Port angebunden ist.
Alternativ kann hier ein WLAN fähiger Rechner (RPi + WLAN Stick) benutzt werden, wenn man nicht die Möglichkeit
hat, VLANs einzurichten.

Im DHCP Server dieses IoT Netzwerks wird dann mein Linux Rechner welcher auf das DHCPDISCOVER wartet als
Standardgateway eingerichtet. So kann man mit tcpdump und Wireshark den Traffic des Dash Buttons mitlesen.

Ein paar weitere Ausführungen gibt es [auf github](https://github.com/perryflynn/amazon-dashbutton-pipe).

### Netzwerk Traffic

Mit Wireshark aufgezeichnete Verbindungsversuche:

```sh
84.581865 ac:63:be:xx:xx:xx -> Broadcast    LLC 60 S P, func=RNR, N(R)=64; DSAP NULL LSAP Individual, SSAP NULL LSAP Command
84.609697      0.0.0.0 -> 255.255.255.255 DHCP 303 DHCP Request  - Transaction ID 0x41d3be87
84.629735 ac:63:be:xx:xx:xx -> Broadcast    ARP 60 Who has 192.168.26.2?  Tell 192.168.26.103
84.639013 192.168.26.103 -> 192.0.2.1    DNS 75 Standard query 0x2330  A time-c.nist.gov
84.639890    192.0.2.1 -> 192.168.26.103 DNS 91 Standard query response 0x2330  A 129.6.15.30
85.130081 192.168.26.103 -> 192.0.2.1    DNS 83 Standard query 0xe6df  A parker-gw-eu.amazon.com
85.131157    192.0.2.1 -> 192.168.26.103 DNS 99 Standard query response 0xe6df  A 54.239.39.76
85.134154 192.168.26.103 -> 54.239.39.76 TCP 60 50197→443 [SYN] Seq=0 Win=4338 Len=0 MSS=1446
85.134198 54.239.39.76 -> 192.168.26.103 TCP 58 443→50197 [SYN, ACK] Seq=0 Ack=1 Win=29200 Len=0 MSS=1460
85.140781 192.168.26.103 -> 54.239.39.76 TCP 60 50197→443 [ACK] Seq=1 Ack=1 Win=4338 Len=0
85.140817 192.168.26.103 -> 54.239.39.76 SSL 128 Client Hello
85.140825 54.239.39.76 -> 192.168.26.103 TCP 54 443→50197 [ACK] Seq=1 Ack=75 Win=29200 Len=0
85.142401 54.239.39.76 -> 192.168.26.103 TLSv1.2 1403 Server Hello, Certificate, Server Key Exchange, Server Hello Done
85.150187 192.168.26.103 -> 54.239.39.76 TCP 60 50197→443 [FIN, ACK] Seq=75 Ack=1350 Win=4338 Len=0
85.150299 54.239.39.76 -> 192.168.26.103 TCP 54 443→50197 [FIN, ACK] Seq=1350 Ack=76 Win=29200 Len=0
85.152582 192.168.26.103 -> 54.239.39.76 TCP 60 50197→443 [ACK] Seq=76 Ack=1351 Win=4338 Len=0
85.401907 192.168.26.103 -> 54.239.39.76 TCP 60 50198→443 [SYN] Seq=0 Win=4338 Len=0 MSS=1446
85.401949 54.239.39.76 -> 192.168.26.103 TCP 58 443→50198 [SYN, ACK] Seq=0 Ack=1 Win=29200 Len=0 MSS=1460
85.404891 192.168.26.103 -> 54.239.39.76 TCP 60 50198→443 [ACK] Seq=1 Ack=1 Win=4338 Len=0
85.404909 192.168.26.103 -> 54.239.39.76 SSL 128 Client Hello
85.404914 54.239.39.76 -> 192.168.26.103 TCP 54 443→50198 [ACK] Seq=1 Ack=75 Win=29200 Len=0
85.406437 54.239.39.76 -> 192.168.26.103 TLSv1.2 1403 Server Hello, Certificate, Server Key Exchange, Server Hello Done
85.414446 192.168.26.103 -> 54.239.39.76 TCP 60 50198→443 [FIN, ACK] Seq=75 Ack=1350 Win=4338 Len=0
85.414583 54.239.39.76 -> 192.168.26.103 TCP 54 443→50198 [FIN, ACK] Seq=1350 Ack=76 Win=29200 Len=0
85.416918 192.168.26.103 -> 54.239.39.76 TCP 60 50198→443 [ACK] Seq=76 Ack=1351 Win=4338 Len=0
```

Die Verbindung läuft verschlüsselt ab, was uns aber nicht weiter stören soll. Wir sollen ja einfach
nur eine Verbindung zu Amazon verhindern.

### Einfaches wegfiltern reicht nicht

Filtert man alle Verbindungsversuche einfach weg, dauert es ewig bis der Dash Button sich wieder abschaltet.
Man muss dem Button also vermitteln, dass die Requests fehlschlagen. Aber durch einen Serverfehler, und nicht
durch einen Netzwerkfehler.

Ein REJECT in iptables reicht da leider nicht.

Ich habe einfach auf meinem Linux Rechner lokal einen Webserver mit selbstsigniertem SSL Zertifikat eingerichtet,
sodass es einen Server auf Port 443 gibt, welcher SSL Verbindungen annimmt.

Anschließend werden die drei IP Adressen via DNAT auf die lokale Maschine umgeleitet.

So bekommt der Dash Button schnellstmöglich eine fehlerhafte Antwort und die Aktivität 
dauert nur 3-5 Sekunden anstatt über 30 Sekunden.

Ein iptables Beispiel gibt es [auf github](https://github.com/perryflynn/amazon-dashbutton-pipe).

## Aus Amazon löschen

Sobald der Button keinen Internetzugriff mehr hat, kann dieser aus dem
Amazon Konto gelöscht werden.
