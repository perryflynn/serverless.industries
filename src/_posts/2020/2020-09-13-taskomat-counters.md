---
author: christian
title: "TaskOMat Counters: Dinge zählen"
locale: de
ref: taskomat-gitlab-counters
tags: [projects, gitlab, projects:taskomat]
published: false
---

[Mein TaskOMat Projekt][about]
unterstützt seit wenigen Tagen den Bot Command `!count`, mit dem sich beliebige
Dinge zählen lassen.

Ich zähle damit zum Beispiel meine Fahrradkilometer.

![TaskOMat Counter Command]({{'/assets/taskomat-countercommand.png' | relative_url}}){:.img-fluid}

Der Bot erzeugt dann in einem Note eine tabellarische Auswertung.
Es wird monatlich zusammengezähltund eine Gesamtsumme gebildet.

![TaskOMat Counter Summary]({{'/assets/taskomat-countersummary2.png' | relative_url}}){:.img-fluid}

Den Code dazu gibt es [in meinem GitHub Account][taskomat], eine detailiertere Beschreibung
in [einem älteren Beitrag][about].

[taskomat]: https://github.com/perryflynn/taskomat
[about]: {% post_url 2020/2020-08-09-taskomat-gitlab-personal-todo %}
