---
author: christian
title: "TaskOMat: GitLab als persönliche ToDo"
lang: de
ref: taskomat-gitlab
tags: [projects, gitlab]
toc: true
---

Seit einiger Zeit nutze ich den GitLab Issue Tracker als persönliche
ToDo für Haushalt und Dinge, die man mal gerne vergisst.

Neben **einem kleinen Bot** welcher automatisiert regelmäßig wiederkehrende
Tasks anlegt und verschiedene Einstellungen sicherstellt,
können auch diverse Standard&shy;funktionen zweckentfremdet werden.

## Links in Projektbeschreibung

Manchmal helfen auch einfache Dinge. Zum Beispiel unterstützt auch die
Projekt&shy;beschreibung Markdown. Man kann sich dort also einfach
Hyperlinks direkt zu den Issue Listen einfügem.

![Links in Projektbeschreibungen]({{'/assets/taskomat-projectdescription.png' | relative_url}}){:.img-fluid}

[quick]: https://docs.gitlab.com/ee/user/project/quick_actions.html
[taskomat]: https://github.com/perryflynn/taskomat

## Zeiterfassung & Milestones

Innerhalb von Issues können Zeiten erfasst werden. Sprich: Wie lange
man mit einer Aufgabe verbracht hat. Dazu verwendet man die [Quick Actions][quick]:

```txt
/spend 5h
/close
```

Sendet man diesen Kommentar ab, werden fünf Stunden erfasst und die Issue
geschlossen. Weist man der Issue einen Milestone zu, wird in diesem Milestone
automatisch **eine Summe aller erfassten Zeiten** angezeigt.

![Timetracking]({{'/assets/taskomat-timetracking.png' | relative_url}}){:.img-fluid}

## Deadlines

Jeder Issue kann ein Fälligkeits&shy;datum zugewiesen werden. Dieses taucht dann in der
Liste auf. Die Liste kann auch nach diesem Datum sortiert werden.

![Fälligkeitsdatum]({{'/assets/taskomat-duedate.png' | relative_url}}){:.img-fluid}

## Prioritäten

Klickt man den Stern in der Label Liste an, wird das Label zu einem priorisiertem
Label. Die Issues werden entsprechend sortiert dargestellt.

![Prioritäten]({{'/assets/taskomat-prio.png' | relative_url}}){:.img-fluid}

## TaskOMat: Wiederkehrende ToDos

Das Hauptscript meiner GitLab Bot Sammlung [TaskOMat][taskomat] legt via Cronjob
wiederkehrende Tasks als neue Issue an, und versucht dabei weitestgehend Intelligent
zu sein.

Aus folgender YAML Datei...

```yml
taskomat:
  title: Zähler ablesen
  labels:
    - medium
    - Wohnung
  due: 14
  assignees: [ 2 ]
  description: |
    Zähler ablesen und Werte aufschreiben.

    | Zähler         | Nummer   | Stand | Differenz |
    |----------------|----------|-------|-----------|
    | Wasser Wohnung | 00000000 | 0     |  +0       |
    | Wasser Keller  | 00000000 | 0     |  +0       |
    | Strom          | 00000000 | 0     |  +0       |
    | Gas            | 00000000 | 0     |  +0       |
```

... erstellt der Cronjob ein neues Issue, sofern es **kein bereits offenes Issue** gibt.
Ist bereits ein Issue vorhanden, wird ein Mention an den Besitzer der Issue gesendet.

![TaskOMat Neue Issue]({{'/assets/taskomat-new.png' | relative_url}}){:.img-fluid}

Außerdem listet der Bot alle Issues des gleichen Typs in einem Kommentar auf,
sodass man sich ältere, bereits abgeschlossene Tasks noch einmal anschauen kann.

![TaskOMat Related Issues]({{'/assets/taskomat-related.png' | relative_url}}){:.img-fluid}

Damit der Cron bereits angelegte Objekte wieder findet, werden in automatisch angelegten
Milestones und Issues Notes mit einem YAML Codeblock angelegt.

![TaskOMat Config]({{'/assets/taskomat-config.png' | relative_url}}){:.img-fluid}

## TaskOMat: Housekeeping

Das Housekeepingscript meiner GitLab Bot Sammlung [TaskOMat][taskomat] stellt via Cronjob
diverse Regeln sicher:

- Weise alle unzugewiesenen Issues einem bestimmten User zu
- Weise Issues mit einem bestimmten Label und ohne Milestone einem Label-Milestone zu, um
  damit eine Gesamtsumme des Timetrackings zu erhalten
- Geschlossene Issues sperren
- Geschlossene Issues als Confidential markieren
- Mention an den Besitzer der Issue erstellen, wenn die Deadline der Issue abgelaufen ist
- Existierende Past-Due-Mentions löschen, wenn die Deadline verlängert wurde

![TaskOMat Milestone]({{'/assets/taskomat-milestone.png' | relative_url}}){:.img-fluid}

## GitLab Pipelines + TaskOMat

Will man keine Cronjobs "irgendwo" anlegen, kann man dies auch direkt mit GitLab Pipelines
erledigen. Eine grobe Anleitung:

- Im ToDo Projekt Repositories und Pipelines aktivieren
- Scripte und YAML Collections einchecken
- `TASKOMAT_TOKEN` als Pipeline Variable hinterlegen
- `.gitlab-ci.yml` Datei anlegen

```yml
stages:
  - cron

cron:housekeep:
  stage: cron
  script: [ "./housekeep.py --gitlab-url \"$CI_SERVER_URL\" --project \"$CI_PROJECT_PATH\" --assignee 2 --milestone-label Bürokratie --milestone-label Wohnung --delay 900 --max-updated-age 2592000" ]
  only:
    refs:
      - master
    variables:
      - $CRON_MODE == "housekeep"

cron:taskomat:
  stage: cron
  script: [ "./taskomat.py --gitlab-url \"$CI_SERVER_URL\" --project \"$CI_PROJECT_PATH\" --collection-dir ./$CRON_COLLECTION" ]
  only:
    refs:
      - master
    variables:
      - $CRON_MODE == "taskomat"
      - $CRON_COLLECTION
```

- Pipeline Schedules mit entsprechenden Variablen anlegen

![TaskOMat Schedule]({{'/assets/taskomat-schedule.png' | relative_url}}){:.img-fluid}
