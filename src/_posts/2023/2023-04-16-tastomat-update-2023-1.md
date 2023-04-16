---
author: christian
title: "TaskOMat: Update 2023.1"
locale: de
tags: [projects, gitlab]
toc: true
---

[TaskOMat][taskomat] ist eine Sammlung von Scripts zur Verwaltung und automatisierten Erzeugung von Issues
in GitLab. Als Bot sorgen die Scripts dafür, dass bestimmte Regeln für die Nutzung von
Labels, Due Dates und andere Einstellungen eingehalten werden.

[taskomat]: https://github.com/perryflynn/taskomat
[scoped]: https://docs.gitlab.com/ee/user/project/labels.html#scoped-labels

![TaskOMat 2023]({{'assets/taskomat-changes.png' | relative_url}}){:.img-fluid}

Alle Features lassen sich einzeln aktivieren und konfigurieren.

## Benutzer zuordnen

`--assignee 42`

Jede nicht zugewiesene Issue wird dem Benutzer mit der ID 42 zugewiesen.

## Label Gruppen

`--label-group "low,medium*,high"`

Label Gruppen implementieren die [Scoped Labels][scoped] aus GitLab Premium nach. Von einer
Gruppe ist immer nur ein Label erlaubt, ist eines der Labels mit einem Sternchen markiert,
wird dieses der Issue hinzugefügt, wenn keines der genannten Labels vorhanden ist.

## Label Kategorien

`--label-category "Green,Red,Yellow,Color"`

Label Kategorien fügen sobald eines der Labels `Green`, `Red` oder `Yellow` zugewiesen wurden,
auch das Label `Color` der Issue hinzu. Ebenso wird `Color` entfernt, wenn keines der
untergeordneten Labels mehr dem Issue zugewiesen sind.

## Labels von geschlossenen Issues entfernen

`--closed-remove-label "Workflow:Work in Progress"`

Wird ein Issue geschlossen, wird auch das Label `Workflow:Work in Progress` entfernt.
Schließt man ein Issue außerhalb der GitLab Board, werden so automatisch die Board Status
Labels entfernt.

## Obsolete Issues schließen

`--close-obsolete`

Wird einem Issue das Label `Obsolete` zugewiesen, wird dieses automatisch geschlossen.

## Notes von geschlossenen Issues sperren

`--lock-closed`

Bei geschlossenen Issues wird automatisch die Kommentarfunktion gesperrt.

## Geschlossene Issues zuweisen

`--assign-closed`

Wird ein Issue geschlossen welches keinen Benutzer zugeordnet hat, wird automatisch der Benutzer
zugewiesen, welcher die Issue geschlossen hat.

## Vertraulich setzen

`--set-confidential`

Sofern ein Issue nicht das Label `Public` zugewiesen hat, wird es automatisch auf
Vertraulich gesetzt. Dies erlaubt es Gästen des Issue Trackers den Zugriff auf einzelne Issues
zu erlauben.

## Fällige Issues benachrichtigen

`--notify-due`

Wenn das Fälligkeitsdatum einer Issue erreicht ist, wird eine Note erzeugt um dem Besitzer
der Issue ein @mention zu schicken.

## Dinge zählen

`--counters`

Ist einem Issue das Label `Counter` zugewiesen, sucht der Bot nach Chat Befehlen in den Notes
der Issue und erzeugt daraus eine Auszählung. So lassen sich Aktivitäten wie Fahrrad Touren
zählen.

Beispiel:

```txt
!countunit km
!countgoal 1000
!count 20
[...]
```

Ausgabe:

`TaskOMat:countersummary` :tea: Here is the TaskOMat counter summary:

**Processed:** 65 items
**Time range:** 2022-05-28 - 2022-12-21
**Smallest Amount:** 2.0 km
**Largest Amount:** 102.0 km

**Goal:**
![grand progress](https://progress-bar.dev/123/?scale=100&width=260&color=0072ef&suffix=%25%20%281231km%20of%201000km%29)

| Month | Items | Amount |
|---|---|---|
| 2022-05 | 9 | 162.0 km |
| 2022-06 | 13 :tada: | 383.0 km :tada: |
| 2022-07 | 5 | 108.0 km |
| 2022-08 | 13 | 208.0 km |
| 2022-09 | 12 | 147.0 km |
| 2022-10 | 7 | 124.0 km |
| 2022-11 | 5 | 67.0 km |
| 2022-12 | 1 | 32.0 km |

**Total:** 1231.0 km (+32.0 km last)

## Automatisiert Issues erstellen

Gesteuert mit YAML Dateien lassen sich automatisiert neue Issues erzeugen.
Diese können zur Erinnerung an regelmäßig wiederkehrende Aufgaben genutzt werden.

Dem Script wird ein Ordner mit YAML Dateien übergeben, diese enthalten alle nötigen Parameter
um eine neue GitLab Issue zu erstellen bzw eine vorhandene zu finden und einen due alert als
Kommentar zu posten.

```yml
taskomat:
  title: Zähler ablesen
  labels:
    - prio:medium
    - Kind:Wohnung
  due: 14
  assignees: [ 2 ]
  description: |
    Zähler ablesen und Werte aufschreiben.
```

Wir oft diese Issue erstellt wird, entscheidet der Cron Job / CI Schedule, welches das Script
aufruft.
