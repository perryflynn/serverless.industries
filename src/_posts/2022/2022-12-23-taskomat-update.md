---
author: christian
title: "TaskOMat: Kleine Anpassungen & Webhooks"
locale: de
tags: [projects, gitlab]
published: false
---

Mein GitLab Bot [TaskOMat]({% post_url 2020/2020-08-09-taskomat-gitlab-personal-todo %}) verwaltet nun
schon zwei Jahre meine persönlichen Aufgabenliste und hat jetzt ein paar Updates bekommen.

[boards]: https://docs.gitlab.com/ee/user/project/issue_board.html

- Alle Tickets werden standardmäßig auf "Vertraulich" gesetzt,
  sofern das Ticket nicht das Label `Public` zugewiesen hat.
- Bei geschlossenen Tickets wird das Label `Work in Progress` entfernt.
- Das `housekeep.py` Script wird über einen Web Hook anstatt eines Cronjobs
  ausgeführt, was die Umsetzung der Regeln fast in Echtzeit ermöglicht.

Durch die Änderungen kann ich nun Gäste mit der GitLab Rolle `Guest` in meiner Aufgabenliste 
erlauben, welche nur ausgewählte Tickets sehen dürfen.

Das `Work in Progress` Label wird durch die [Issue Boards von GitLab][boards] gesetzt und 
nicht entfernt, wenn ein Ticket außerhalb des Boards geschlossen wird. 
Nun wird es automatisch entfernt.

Die Nutzung eines Web Hooks zum starten der Bot Pipeline reduziert die Wartezeit auf wenige
Sekunden. Auch muss nun nicht mehr durch die ganze Ticketliste iteriert werden, da
der Web Hook die Ticketnummer mitliefert.

Der [Source Code von TaskOMat](https://github.com/perryflynn/taskomat) und ein detailiertes Read Me 
kann auf GitHub eingesehen werden.
