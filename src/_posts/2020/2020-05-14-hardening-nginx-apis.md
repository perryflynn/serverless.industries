---
author: christian
title: "HTTP APIs mit NGINX härten"
language: german
tags: ['linux', 'nginx', 'api', 'http']
---

Wenn ich in den letzten Monaten eins gelernt habe, dann dass einige User
undankbare Arschlöcher sind. Ich betreibe seit einigen Jahren eine
["Wie ist meine IP" API][api], welche super einfach die aktuelle
IP Adresse und einige andere Informationen in verschiedenen Formaten bereit stellt.

Begonnen hat das kleine Projekt mal auf dem 28C3 in Hamburg. Ich brauchte kurzfristig
einen DynDNS Zugang und mein damaliger Anbieter bot keinen entsprechenden Dienst an.

Mittlerweile erreichen die API, auch wegen [bösen Jungs][virus], zwischenzeitlich über 800 Anfragen pro Sekunde. Ein klassischer Webserver mit php-fpm als Backend kann damit im Normalfall nicht umgehen.

[api]: https://ip.anysrc.net
[virus]: https://www.symantec.com/security_response/writeup.jsp?docid=2016-101811-2408-99&tabid=2

**Dieser Artikel stammt aus meinem alten Blog und wurde am 17.08.2017 verfasst.**

## Eckdaten

- NGINX Webserver
- PHP-FPM Backend, via FastCGI an NGINX angebunden, eigener FPM Pool exklusiv für die API
- Einfaches PHP Script welches Informationen in Plain Text, XML, JSON und anderen Formaten ausliefert
- Zwischen 30 und 40 Millionen Requests pro Woche (via goaccess)
- Durchschnittlich 500 Requests pro Sekunde (via check\_mk)

## Stage 1: Caching

Ein erster Versuch Last von der API zu nehmen, war die Cache Funktion von NGINX zu aktivieren.

```
fastcgi_cache_path /var/www/cache levels=1:2 keys_zone=myipc:100m inactive=10m max_size=1000m;
fastcgi_cache_key $scheme$request_method$host$request_uri$remote_addr$http_user_agent;
fastcgi_cache_lock on;
fastcgi_cache_use_stale error timeout invalid_header updating http_500;
fastcgi_cache_valid 5m;
fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

server {
    [...]
    location ~ ^(/.*[^/]\.php)(/|$) {
        [...]
        fastcgi_pass unix:/var/run/php5-fpm-myip.sock;
        fastcgi_index index.php;
        fastcgi_cache myipc;
        fastcgi_cache_valid 200 1m;
        fastcgi_cache_valid any 1m;
        [...]
    }
}
```

Der Cache sorgt dafür, dass Anfragen nur alle 60 Sekunden an das PHP Backend
weiter gegeben werden. Dazwischen beantwortet NGINX die Anfragen selbst aus dem
Cache heraus. Dies entlastet das PHP Backend erheblich.

Natürlich muss man von Fall zu Fall mit den `fastcgi_cache_valid` Werten und
den Einstellungen oberhalb des `server {}` Blocks experimentieren. In meinem
Fall hat allerdings eine höhere Einstellung als 60 Sekunden keinen Sinn gemacht.
Schließlich soll die API ja weitestgehend korrekte Daten liefern.

[NGINX Dokumentation zu Caching][nginxcache] |
[Anleitung zur Einrichtung von NGINX Caching][digicache]

[nginxcache]: http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_cache
[digicache]: https://www.digitalocean.com/community/tutorials/how-to-setup-fastcgi-caching-with-nginx-on-your-vps

## Stage 2: Rate Limiting

Irgendwann reichte der Cache nicht mehr. Das PHP-FPM Backend stieg immer öfter
mit einem HTTP Error 500 aus, da nicht genug PHP-Threads im FPM Pool zur Verfügung standen.
NGINX bietet als letzte Möglichkeit noch ein Modul an, um die Anfragen
pro Zeitraum zu beschränken (so genanntes Rate Limiting).

```
limit_req_zone $binary_remote_addr zone=myip:50m rate=12r/m;
server {
    [...]
    location ~ ^(/.*[^/]\.php)(/|$) {
        [...]
        limit_req zone=myip burst=2 nodelay;
        [...]
    }
}
```

Die Konfiguration beschränkt die Anfragen auf 12 Requests pro
Minute und Client IP. Probleme kann es hier noch geben, wenn sich
viele Clients eine IP teilen. Hier gilt dann "Pech gehabt".

Alle Clients welche das Limit überschreiten bekommen im entsprechenden
Zeitfenster statt einer normalen Antwort einen HTTP 503 Error.
Diesen liefert NGINX selbst und sehr performant aus. Das PHP-FPM
Backend bekommt davon nichts mit.

[NGINX Dokumentation zum rate limiting](http://nginx.org/en/docs/http/ngx_http_limit_req_module.html)

## Stage 3: Sonderfälle

Irgendeine Malware nutzte die API und hat damit so viel Traffic verursacht,
dass der Server ins straucheln gekommen ist. Zwischenzeitlich musste ich den Dienst
sogar abschalten, da andere Projekte auf dem gleichen Webserver beeinträchtigt wurden.

Nach weiterer Analyse viel mir ein Muster auf. Und zwar sendeten die meisten
der Requests welche mutmaßlich von der Malware kamen keinen User Agent mit.
Folgende Abfrage in NGINX weist alle Anfragen mit einem HTTP Error 400 ab,
welche keinen User Agent im HTTP Header enthalten.

```
server {
    [...]
    error_page 480 = @noagent;
    if ($http_user_agent = "") {
        return 480;
    }
    location @noagent {
        return 400 "Bad Request: Useragent header is required";
    }
    [...]
}
```

Dabei hat es mit Sicherheit auch einige unschuldige getroffen. Doch es sorgte
dafür das meine API, und der komplette Webserver gleich mit, wieder nutzbar waren.
Diese Änderung ist gut ein halbes Jahr her, bisher funktioniert es.
Ich denke mal, dass die Malware welche das verursachte mittlerweile weitestgehend
ausgerottet wurde.

Vor ein paar Wochen hat ein einzelner Client dann so viele Anfragen gesendet,
dass fast die Festplatte (LXC Container, 15GB) des Servers voll gelaufen wäre.
Mein Monitoring (check\_mk) warte mich jedoch rechtzeitig.
Der muss wirklich in einem Script ohne Pause Anfragen rausgehauen haben.
Da half tatsächlich nur eine manuelle Blockade via iptables.

## Fazit und Zahlen

Es ist scheiß egal was man auf die Website von wegen "Fair use" oder
"Bitte nicht übertreiben" schreibt. Die User halten sich eh nicht dran.
Man muss wirklich harte Begrenzungen in Dienste einbauen, wenn man nicht
die Stabilität des Servers riskieren oder 200 Euro für einen fetten
Server ausgeben will.

Als Beispiel die Zahlen der letzten 7 Tage:

{:.table .table-bordered}
Zugriffe | Zugriffe % | Status
--|--|--
35.978.380 | 86.57% | 503 - Rate Limit erreicht
3.798.257 | 9.14% | 400 - Kein User Agent / ungültige Anfrage
1.781.350 | 4.29% | 200 - Erfolgreiche Anfrage

Ganze **5%** der Anfragen erreichen also die API.
Das PHP Backend verarbeitet also im Schnitt **nur 25** der 500 Anfragen pro Sekunde.
Alles andere wird verworfen.

Keine Ahnung wieso die User nicht merken, dass die meisten Ihrer Anfragen
überhaupt nicht erfolgreich sind. Normal müsste das doch zu Fehlern in den
Scripten / Programmen führen, oder?

Egal, ich habe durch das ganze Thema eine Menge gelernt. Auch wenn ich hier
nur eine, im vergleich zu Facebook oder Twitter, winzig winzig kleine API
betreibe, muss man trotzdem das Eine oder Andere beachten.

Gerade wenn auf dem Server noch andere Dinge laufen.
