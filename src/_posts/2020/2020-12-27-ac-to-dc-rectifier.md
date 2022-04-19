---
author: christian
title: Wechselstrom Gleichrichten
locale: de
tags: [ electronics ]
image: /assets/acdc-3.jpg
---

Für ein Projekt musste eine Schaltung an eine 12 Volt Wechstelstrom&shy;quelle
angeschlossen werden. Hier dokumentiere ich, wie das funktioniert, und welche
"Qualitätsstufen" es beim Gleichrichten gibt.

[scope]: https://de.wikipedia.org/wiki/Oszilloskop
[espdebounce]: https://esphome.io/components/sensor/index.html#throttle-heartbeat-debounce-delta

Auf einem [Oszilloskop][scope] sieht Wechselstrom wie folgt aus:

![Wechselstrom Sinuskurve]({{'assets/acdc-1.jpg' | relative_url}}){:.img-fluid}

Schließt man Wechselstrom an Komponenten an welche Gleichstrom erwarten,
kann das Bauteil im besten Fall nur teilweise funktionieren oder sogar
kaputt gehen.

## Stufe 1: Einzelne Diode

![Gleichrichter mit einer Diode]({{'assets/acdc-diode.jpg' | relative_url}}){:.img-fluid}

In der einfachsten Variante, reicht es eine einzelne Diode (zum Beispiel 1N4001)
zu verwenden. Die Diode unterdrückt den negativen Teil der Sinuswelle.

![Wechselstrom mit Diode]({{'assets/acdc-2.jpg' | relative_url}}){:.img-fluid}

Simple Komponenten funktionieren jetzt schon **so halb**. Da sich das
gleichgerichtete Signal mit 50 Hertz an-/ausschaltet, werden Komponenten wie Optokoppler
oder LEDs flackern.

Das kann man zum Beispiel in ESPHome mit [dem debounce Filter][espdebounce]
ausgleichen. Hat man also nicht die richtigen Teile zur Hand um es "richtig" zu machen,
geht es also auch so.

## Stufe 2: Brückengleichrichter

![Brückengleichrichter]({{'assets/acdc-bridge-rectifier.jpg' | relative_url}}){:.img-fluid}

Mit einem Brücken&shy;gleichrichter kann auch der unterdrückte, negative
Teil der Sinuskurve genutzt werden. Der negative Teil wird dabei "hochgeklappt",
positiv gemacht.

![Wechselstrom mit Brückengleichrichter]({{'assets/acdc-3.jpg' | relative_url}}){:.img-fluid}

Der Brücken&shy;gleichrichter steigert durch die Nutzung der negativen Welle den
Wirkungsgrad und ermöglicht es die Wechselstrom&shy;quelle zu verkleinern.

Steuert man nur einen Optokoppler oder vergleichbare kleine Schaltungen an, kann man
sich den Brücken&shy;gleichrichter sparen und mit einer einzelnen Diode und einem
Kondensator arbeiten, da es keinen Unterschied macht.

## Stufe 3: Mit Kondensator

![Brückengleichrichter]({{'assets/acdc-bridge-rectifier-capacitor.jpg' | relative_url}}){:.img-fluid} ![Brückengleichrichter]({{'assets/acdc-diode-capacitor.jpg' | relative_url}}){:.img-fluid}

Um das Flackern zu entfernen, muss jetzt noch ein Kondensator in die Schaltung eingebaut
werden, welcher als Stabilisator fungiert und aus der Kurve eine gerade Linie macht.

![Gleichstrom stabilisiert mit Kondensator]({{'assets/acdc-4.jpg' | relative_url}}){:.img-fluid}

Nun ist die "echte" Gleichspannung erreicht.

Bei der Wahl des Kondensators muss man darauf achten, die richtige Kapazität
zu wählen. Zu kleine Kondensatoren schwächen das Flackern nur ab, zu große Kondensatoren
sorgen für langes "nachglühen", was bei Optokopplern / LEDs zu verzögertem Ausschalten
führen kann.

Mit 50V, 47μF:

![Signal mit kleinem Kondensator]({{'assets/acdc-capsmall.jpg' | relative_url}}){:.img-fluid}

Mit 63V, 470μF:

![Signal mit großem Kondensator]({{'assets/acdc-capbig.jpg' | relative_url}}){:.img-fluid}

## Die Testschaltung

![Testschaltung]({{'assets/acdc-breadboard.jpg' | relative_url}}){:.img-fluid}
