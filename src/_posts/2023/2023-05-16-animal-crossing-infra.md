---
author: christian
title: Animal Crossing Fan Projekte
locale: de
tags: [ games, animal crossing, api, web service ]
---

Um die Zeit zum Release von "Legend of Zelda: Tears of the Kingdom" zu überbrücken, habe ich vor
einigen Wochen wieder mit "Animal Crossing: New Horizons" (ACNH) angefangen. Auch ohne COVID-Loch ein
wunderschönes Spiel, in das man viel Zeit versenken kann.

[flipperamiibo]: https://github.com/Gioman101/FlipperAmiibo
[acnhapi]: https://github.com/alexislours/ACNHAPI
[acnhapiapi]: https://acnhapi.com/
[npapi]: https://api.nookipedia.com/
[npapigh]: https://github.com/Nookipedia/nookipedia-api
[npdev]: https://nookipedia.com/wiki/Nookipedia:Development
[sheet]: https://nookipedia.com/wiki/Community:ACNH_Spreadsheet
[sheetjson]: https://github.com/NooksBazaar/google-sheets-to-json
[reversefrontend]: https://github.com/Treeki/CylindricalEarth
[reversebackend]: https://github.com/ZekeSnider/NintendoSwitchRESTAPI
[cdn]: https://acnhcdn.com/

Dabei habe ich mich für einen Neustart entschieden. Also den Spielstand gelöscht aber Sternis,
Meilentickets und ein paar wichtige Ressourcen bei einer Freundin zwischen geparkt und später auf
die neue Insel geholt.

Nach dem Neustart bin ich beim Wühlen in den großen Wikis auf ein paar super interessante Fan
Projekte gestoßen.

Den Start macht die Meta Platform [acnh.directory](https://acnh.directory/), welche
eine filterbare Liste mit vielen ACNH Fan Projekten liefert.

## Wikis

Wikis gibt es ja mittlerweile für fast alle Spiele, der Detailgrad ist bei Animal Crossing aber
wirklich wahnsinn. Man findet Informationen über jeden Aspekt des Spiels.

- [https://nookipedia.com/](https://nookipedia.com/)
- [https://animalcrossing.fandom.com/](https://animalcrossing.fandom.com/)
- [https://animalcrossingwiki.de/](https://animalcrossingwiki.de/)

## Amiibos via Flipper Zero

Das GitHub Projekt [Gioman101/FlipperAmiibo][flipperamiibo] bietet eine Sammlung der NFC Tags
fast aller Amiibos. Amiibos sind Sammelfiguren bzw Sammelkarten, welche in verschiedenen Nintendo Spielen
für Zusatzinhalte verwendet werden können. 

In ACNH kann man mit den Amiibos die Lieblingsbewohner einladen und auf die eigene Insel 
ziehen lassen. Insgesamt gibt es in ACNH **413 unterschiedliche Bewohner**, alle mit unterschiedlichen
Eigenschaften und Wahrscheinlichkeiten ob diese die Insel besuchen. 

Seinen Wunsch-Bewohner ohne Amiibos auf die Insel zu bekommen, ist also extrem unwahrscheinlich.

![Notifications auf dem TV]({{'assets/acnh-amiibos.jpg' | relative_url}}){:.img-fluid}

## Datenbanken und APIs

Nookipedia nutzt im Wiki die Mediawiki Extension Cargo, um die Daten über Bewohner, Häuser, 
Möbel, uvm in einem [strukturierten Format bereit zu stellen][npdev]. Auf vielen der Wiki Seiten werden
diese Daten dann benutzt, um standardisierte Info Karten anzuzeigen.

Unter [api.nookipedia.com][npapi] gibt es außerdem eine REST API, wo man auf eben diese Daten
mit eigener Software zugreifen kann.

Den Code der API gibt es auf [GitHub][npapigh].

Das GitHub Projekt [alexislours/ACNHAPI][acnhapi] stellt eine weitere REST API bereit, welche aber
nicht mehr gepflegt wird. Zumindest für Bewohner kann man hier aber einfach an statische JSON Daten
und Bilder kommen und damit Dinge tun.

Unter [acnhapi.com][acnhapiapi] kann man die API zwar weiterhin nutzen, aber IMHO ist es nur eine
Frage der Zeit, bis dieses Projekt offline geht.

Eines der ältesten Projekte ist wohl die [ACNH Spreadsheet][sheet], welches eine Google Spreadsheet
mit ALLEN Ressourcen des Spiels bereit stellt. Die Daten wurden teilweise via Reverse Engineering
erzeugt, aber auch mit sehr viel Handarbeit.

Das GitHub Projekt [NooksBazaar/google-sheets-to-json][sheetjson] erlaubt es die Daten aus dem 
Google Spreadsheet in JSON umzuwandeln.

Das [acnhcdn.com][cdn] bietet ein Content Delivery Network mit allen Grafiken aus dem Spiel,
welches von vielen Fan Projekten benutzt wird. Details zur Funktionsweise gibt es leider nur auf
Discord.

## Reverse Engineering

Im GitHub Projekt [Treeki/CylindricalEarth][reversefrontend] gibt es haufenweise Informationen
wie ACNH unter der Haube funktioniert. Dieser Reverse Engineering Arbeit verdanken wir, soweit
ich das verstanden habe, auch einen Großteil der Daten im Spread Sheet und anderen Projekten.

Das GitHub Projekt [ZekeSnider/NintendoSwitchRESTAPI][reversebackend] schaut sich die APIs der
Nintendo Switch App genauer an. Auch die Issues sind dabei interessant, welche den Großteil
der Infos zu ACNH enthalten.

## Filterbare Listen

[nookdb.io](https://nookdb.io/) stellt eine schöne Website bereit um Bewohner, Insekten, Fische 
und vieles andere zu durchsuchen und zu filtern.

[critterpedia-plus.mutoo.im](https://critterpedia-plus.mutoo.im/) liefert eine Übersicht, welche 
Lebewesen wann gefunden werden können.
