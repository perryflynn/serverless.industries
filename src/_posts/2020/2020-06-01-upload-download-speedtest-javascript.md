---
author: christian
title: "Upload + Download Speedtest in JavaScript"
locale: de
ref: speedtest-project
tags: ['http', 'html', 'javascript', 'projects']
---

Auf github habe ich den [Speedtest von Franklin van de Meent][original]
gefunden und ein wenig erweitert. Diese neue Version mit mehr Features
gibt es nun auf [meiner github Seite][my].

[original]: https://github.com/fvdm/speedtest
[my]: https://github.com/perryflynn/speedtest
[byte]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests

![Speedtest Demo]({{'/assets/speedtest-demo.gif' | relative_url}}){:.img-fluid}

## Automatische Größenermittlung

Auf dem Server muss nur noch eine fünf Gigabyte grüße
Datei angelegt werden, welche zum Testen verwendet wird.
Das Script kann dann mit [HTTP Byte Range Requests][byte]
die richtige Menge vom Server anfordern.

Das Script lädt dabei erst fünf Megabyte Daten herunter,
misst wie lange dies dauert und berechnet daraus die Dateigröße
für einen Test welcher 15 Sekunden dauert.

## Upload Test

Auch ein Upload Test ist nun möglich. Auf dem Server muss
dafür ein entsprechender Endpunkt vorhanden sein, welcher
die Daten nach `/dev/null` schickt.

## Infos für Nerds

Detailiertere Informationen was der Test genau macht, kann
man sich in den Developer Tools anschauen:

![Speedtest Nerdinfo]({{'/assets/speedtest-nerdinfo.gif' | relative_url}}){:.img-fluid}

## Code Refactoring

Der Code nutzt nun etwas modernere Funktionen von Java Script
wie zum Beispiel Promises. Auch sind Logik und HTML durch Events
voneinander getrennt.

## Download

Den Code gibt es auf meiner github Seite: [perryflynn/speedtest][my]
