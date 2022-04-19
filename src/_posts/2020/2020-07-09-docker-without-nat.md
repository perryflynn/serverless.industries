---
author: christian
title: "Docker: Performance-Probleme durch NAT/Conntrack"
locale: de
ref: docker-bad-nat
tags: [linux, docker, network]
toc: true
---

Auf meinem primären Docker Host hatte ich ab und an massive Probleme mit Wartezeiten von
über drei Sekunden beim Aufbau von TCP Verbindungen. Das Problem trat ausschließlich
beim initialen Verbindungs&shy;aufbau auf. Alle weiteren Verbindungen wurden mit einer
normalen Geschwindigkeit verarbeitet.

```txt
root@docker01 ~ # curl -L https://dingetun.net/ > /dev/null
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 54831    0 54831    0     0   460k      0 00:00:04 00:00:04 --:--:--  461k
```

Nach längerem Rumprobieren stellte sich [NAT][nat] bzw [Conntrack][conntrack]
als Ursache heraus. Was auch erklärt, wieso dies nur beim ersten Request auftritt.
Bei allen folgenden Requests sorgen [Keepalive][keepalive] und Conntrack dafür,
dass keine neue Verbindung aufgebaut werden muss.

## Ein bisschen Theorie

Die verschiedenen Projekte auf dem Server verursachen im Schnitt zirka
6000 TCP Verbindungen, die von Conntrack verwaltet werden müssen.

```txt
root@docker01 ~ # conntrack -L | awk '{print $4}' | sort | uniq -c
conntrack v1.4.4 (conntrack-tools): 6615 flow entries have been shown.
    257 CLOSE
      2 CLOSE_WAIT
    553 ESTABLISHED
      3 FIN_WAIT
    470 LAST_ACK
      7 SYN_RECV
   5320 TIME_WAIT
```

Der Webserver Container ist ganz klassisch auf dem Server eingerichtet:

```sh
# create the container
# map hosts ports 80/tcp and 443/tcp into the container
docker create --name webserver -p 80:80 -p 443:443 nginx:latest
# connect the container to internal network
docker network connect internal webserver
# start the container
docker start webserver
```

Der NGINX Container nimmt eingehende Verbindungen entgegen und leitet diese
in seiner Rolle als Reverse Proxy an die Container der eigentlichen
Anwendungen weiter.

Der Docker Daemon verwendet [DNAT][dnat], um Verbindungen welche auf der
öffentlichen IP Adresse des Docker Hosts eingehen an den NGINX Container
durchzureichen.

Dabei verändert der Linux Kernel die Ziel IP Adresse der IP
Pakete auf die NGINX Container IP, sodass der Container die Pakete annehmen kann.
Sendet der Container eine Antwort, verändert der Linux Kernel auch hier wieder die
IP Adresse, damit die Antwort beim ursprünglichen Absender akzeptiert wird.

Auf dem Docker Host wird ein zufälliger Quellport geöffnet,
über dem die angepassten IP Pakete an den Webserver Container gesendet werden.

Genau dieser Prozess wird vom Linux Kernel in Listen protokolliert. Welche Pakete auf
welchen Verbindungen über welche Ports geleitet werden. Dadurch kann der Kernel später
widerum entscheiden, wie die Antwortpakete verändert werden müssen.

Für den Anwender und dem Webserver Container ist dieser Prozess transparent.

## Das Problem

Bei der Erzeugung von Quellports
kann eine [Race Condition][rccon] entstehen. Zwei Verbindungen versuchen dabei
den gleichen Port zum Weiterleiten der Pakete an den Container zu verwenden, was
zum Verwerfen von IP Paketen führt.

Dieses Verhalten kann den Verbindungs&shy;aufbau mehrere Sekunden verzögern,
da die Öffnung des Quellports dadurch im schlimmsten Fall mehrmals versucht werden muss.

Und siehe da, da sind die drei Sekunden Verzögerung:

> This was explaining very well the duration of the slow requests since the
> retransmission delays for this kind of packets are 1 second for the second
> try, 3 seconds for the third, then 6, 12, 24, etc.
>
> <cite>[A reason for unexplained connection timeouts on Kubernetes/Docker][xing]</cite>

In meinem Fall ist das NATing also so überfordert, dass der initiale Verbindungs&shy;aufbau im Schnitt
drei Mal Versucht wird, bevor diese erfolgreich hergestellt ist.

([hier][xingwf] findet sich eine genauere Beschreibung des Workflows)

## Optimierungsversuche in iptables

Bei XING wurde das Problem mit dem netfilter Flag `NF_NAT_RANGE_PROTO_RANDOM_FULLY`
gelöst, welche die Portvergabe randomisiert.

> the number of errors dropped from one every few seconds for a node,
> to one error every few hours on the whole clusters.
>
> <cite>[A reason for unexplained connection timeouts on Kubernetes/Docker][xing]</cite>

Ich habe leider keine Möglichkeit gefunden, dies auf einem einfachen Docker Host
einzustellen. Daher habe ich mich dazu entschieden, komplett auf NAT zu verzichten.

## NAT vermeiden

Mit der Option `--network host`, kann einem Docker Container erlaubt werden, den Network
Stack des Host Systems zu verwenden. Dienste können in dem Modus direkt die IP Adressen des Hosts
zum Binden von Diensten verwenden.

Dabei gibt es keine Einschränkung. **Alle Netzwerk Interfaces, egal ob Internet, VPN
oder interne Bridges sind im Container verfügbar.** Man muss den im Container betriebenen Dienst also
sorgfältig Konfigurieren, sodass der Dienst die korrekten Interfaces benutzt. Ansonsten
könnte dies ein **Sicherheitsproblem** sein.

Ein weiterer Nachteil ist, dass der **Docker DNS Service nicht verfügbar** ist. Andere
Container müssen via IP Adresse angesprochen werden. Dieser Schmerz kann aber
mit `--add-host="myapp:10.0.0.100"` gelindert werden. Die Option erstellt einen Eintrag in
`/etc/hosts` des Containers. So sind andere Container weiterhin per Hostname erreichbar.

```sh
# create a network with a known IP Subnet
docker network create --driver=bridge --subnet=10.0.0.0/24 containers0

# connect the existing application container with the network
# and assign a static IP address
docker network connect --ip 10.0.0.101 containers0 dingetun
docker network connect --ip 10.0.0.102 containers0 myip

# create the new webserver container
docker run --name webserver -d \
    --add-host dingetun:10.0.0.101 \
    --add-host myip:10.0.0.102 \
    --network host \
    nginx:latest
```

Das einzige was sich an der NGINX Konfiguration ändert, sind explizite bindings, sodass
der Webserver nur auf den öffentlichen IPs erreichbar ist. Reverse Proxy Setups welche
Containernamen benutzen können so bleiben wie sie sind.

## Fazit

Der Geschwindigkeits&shy;unterschied ist wahnsinn. Die Requests sind nun meistens in unter
250ms abgearbeitet, egal ob klassische PHP- oder .NET Core Anwendung. Statische Dateien
in zirka 120ms.

## Danke

Vielen Dank an die Menschen bei XING, welche dieses Problem im Artikel
"[A reason for unexplained connection timeouts on Kubernetes/Docker][xing]" sehr
detailiert analysiert haben.

Danke an Claas für die gedankliche Unterstützung. :-)

[dnat]: https://en.wikipedia.org/wiki/Network_address_translation#DNAT
[keepalive]: https://en.wikipedia.org/wiki/Keepalive#TCP_keepalive
[nat]: https://en.wikipedia.org/wiki/Network_address_translation
[conntrack]: https://en.wikipedia.org/wiki/Netfilter#conntrack-tools
[rccon]: https://en.wikipedia.org/wiki/Race_condition
[xing]: https://tech.xing.com/a-reason-for-unexplained-connection-timeouts-on-kubernetes-docker-abd041cf7e02
[xingwf]: https://tech.xing.com/a-reason-for-unexplained-connection-timeouts-on-kubernetes-docker-abd041cf7e02#d507
[addhost]: https://docs.docker.com/engine/reference/run/#network-settings
