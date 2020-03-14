---
author: christian
title: "$PATH Cache in Bash neu laden"
language: german
tags: ['linux', 'shell', 'bash']
---

Die Bash cached eine Liste aller ausführbaren Programme innerhalb der Pfade,
welche in der Environment Variable `$PATH` definiert sind.

Werden Programme gelöscht, neu hinzugefügt oder ändert sich ein Symlink, kann es
passieren das ein Script nicht gefunden wird obwohl es in einem Ordner abgelegt ist,
welcher in `$PATH` enthalten ist.

Mit `hash -r` kann man den Cache leeren, sodass die Liste der Programme
neu eingelesen wird.
