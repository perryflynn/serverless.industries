---
author: christian
title: Bash History konfigurieren
language: german
tags: ['linux', 'bash', 'shell']
---

Für [Borg Backup][borg] stand ich vor der Frage, wie ich Environment Variablen
definieren kann, ohne dass diese in der `~/.bash_history` landen.
In der man page stieß ich dann auf `HISTCONTROL`.

Standards auf einer Debian Buster Installation:

```
borg@borg:~$ set | grep HIST
HISTCONTROL=ignoreboth
HISTFILE=/mnt/backup/borg/.bash_history
HISTFILESIZE=2000
HISTSIZE=1000
```

## HISTCONTROL

Diese Environment Variable steuert wie die ausgeführten Befehle in der
Historie abgelegt werden. Die Befehle können mit einem Doppelpunkt getrennt
kombiniert werden.

- `ignorespace`: Alle Befehle welche mit Leerzeichen beginnen
  werden nicht in die History aufgenommen. Praktisch für das definieren
  von Environment Variablen welche Passwörter enthalten.
- `ignoredups`: Wird ein Befehl Zeichengenau wiederholt, wird die Wiederholung
  nicht in die History aufgenommen.
- `erasedups`: Bevor der zuletzt ausgeführte Befehl in die History gespeichert
  wird, werden alle Duplikate in der Historie entfernt.

Beispiel:

```sh
HISTCONTROL="ignorespace:erasedups"
export HISTCONTROL
```

## HISTFILE

Der Pfad der Datei in welche die History gespeichert wird.

Ist die Variable nicht definiert, wird keine History gespeichert.

## HISTSIZE & HISTFILESIZE

Anzahl der Befehle welche in der History bzw der History-Datei gespeichert werden.

[borg]: https://borgbackup.readthedocs.io/en/stable/usage/general.html#environment-variables
