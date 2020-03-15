---
author: christian
title: "dingetun.net Lite: Yay or Nay?"
language: german
tags: ['projects']
---

Als Ergänzung zu [dingetun.net][dingetun] gibt es seit gestern
das Mini-Projekt [Yay or Nay?][yaynay]. Es ist eine simple Single-Page
Anwendung wo man einfache Ja/Nein Fragen beantworten kann.

Das Tool soll das Koordinieren von Dingen über WhatsApp und Co.
vereinfachen.

[dingetun]: https://dingetun.net/
[yaynay]: https://yaynay.dingetun.net/

## Verwendung von Cookies genehmigen

Das Tool verwendet Cookies um die Auswahl zu speichern. So wird ermöglicht,
dass man die Auswahl noch nachträglich ändern oder zurückziehen kann.

Man muss der Nutzung von Cookies zustimmen, bevor das Tool verwendet werden kann.

## Wie funktionierts

Wenn Du [https://yaynay.dingetun.net/][yaynay] aufrufst, wirst Du automatisch
auf eine zufällig generierte URL umgeleitet, welche die Stimmen deiner Umfrage
speichert.

Man kann aber auch eine beliebige (`^[A-Za-z0-9\-_]{3,64}$`) eigene Zeichenkette
in der URL verwenden.

## One-Click

Will man es den Benutzern maximal einfach machen, kann man in dem jeweiligen
Chat auch einfach zwei URLs posten, welche jeweils schon die Stimme enthalten.

- Für Ja-Stimme: [https://yaynay.dingetun.net/changeme?yay](https://yaynay.dingetun.net/changeme?yay)
- Für Nein-Stimme: [https://yaynay.dingetun.net/changeme?nay](https://yaynay.dingetun.net/changeme?nay)

Das hat allerdings den Nachteil, dass die User nicht mehr das Ergebnis anschauen können,
ohne selbst abzustimmen. Das könnte gegebenenfalls das Ergebnis verfälschen.

## Datenspeicherung

Das "Cookies sind erlaubt"-Cookie hat eine Laufzeit von **einem Jahr** und enthält keine
personenbezogenen Daten. Lediglich eine `1`.

Das Session Cookies hat eine Laufzeit von **14 Tagen** und enthält alle getätigen votings,
sodass vortings korrigiert oder zurückgezogen werden können.

Ein Yay/Nay wird nach **30 Tagen inaktivität** gelöscht.
