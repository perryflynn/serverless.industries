---
author: christian
title: UDL - Ein eigenes Basisimage erstellen
language: german
tags: [docker, linux]
---

In einer Reihe **Ultimativer Docker Leitfaden** moechte ich den 
kompletten Workflow von der Erstellung eigener Images bishin 
zum Betrieb von Containern, Docker Netzwerken und dem definieren 
von Ressourcen Limits erklaeren.

Und das in Deutsch. Unter Linux.

## Ein Basisimage

Jede Software benötigt eine gewisse Basis um zu funktionieren.
Sei es die klassische libc Bibliothek oder eine Shell wie die Bash.
Genau diese Basis liefert ein Basisimage, in dem man anschließend
seine eigene Software installieren und starten kann.
