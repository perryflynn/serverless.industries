---
author: christian
title: PerrysNetConsole aktualisiert
lang: de
ref: perrysnetconsole-update1
tags: [projects, dotnet, software development]
---

Meine [Sammlung von Controls für .NET Console Applications][netcon] und
die dazu passende [HTML Erweitertung][netconhtml] haben eine Aktualisierung
erhalten.

Die größte Änderung ist der Wechsel auf .NET Standard und somit der Support
von .NET Core bzw Linux und Mac. Aber auch das eine oder andere neue Feature ist
dazu gekommen.

[netcon]: https://github.com/perryflynn/PerrysNetConsole
[netconnuget]: https://www.nuget.org/packages/PerrysNetConsole
[netconhtml]: https://github.com/perryflynn/PerrysNetConsoleHtml
[netconhtmlnuget]: https://www.nuget.org/packages/PerrysNetConsoleHtml

## PerrysNetConsole

\[ [GitHub Repository][netcon] \] \| \[ [nuget Package][netconnuget] \]

- Migration zu .NET Standard 2
- Fehlerbehandlung bei Windows-Exklusiven Features
- `TryXYZ()`-Methoden für Windows-Exklusive Features, welche `false` zurück geben
  falls das Feature nicht unterstützt wird, anstatt eine Exception zu werfen
- Horizontale Breite fix definieren (hilfreich wenn das Programm nicht in einem
  Fenster läuft und somit keine Dimensionen bekannt sind)
- Neues Control: Graph
- Viele Bugfixes

![Graph Control]({{'/assets/perrysnetconsole-graph.png' | relative_url}}){:.img-fluid}

## PerrysNetConsoleHtml

\[ [GitHub Repository][netconhtml] \] \| \[ [nuget Package][netconhtmlnuget] \]

- Migration zu .NET Standard 2
- Integration des Standard HTML Templates als Resource in die DLL
- Option um Farben zu unterdrücken
- HTML Template nutzt jetzt Bootstrap 4
- Diverse Bugfixes
