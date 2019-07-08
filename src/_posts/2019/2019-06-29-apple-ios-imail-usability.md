---
author: christian
title: Apple iOS Email und Usability
language: german
tags: [apple, ios, usability, email]
---

Die Tage fragte mich jemand, wo die Ursache liegen könnte,
dass die Email App auf einem Apple iPad den Versand von Emails
mit der Info, dass die Mail vom Server abgelehnt wurde, abbricht.

Die genaue Fehlermeldung war wie folgt:

{:.blockquote}
> **E-Mails können nicht gesendet werden.**
> Eine Kopie wurde in dein Ausgangsfach gelegt.
> Der Empfänger [...] wurde vom Server abgelehnt.

![Apple iOS Email Fehler]({{'/assets/apple_ios_mail_denied.jpg' | relative_url}}){:.img-fluid}

Erst dachte ich an ein Blacklisting des Mailservers. Aber nein,
der Bekannte hatte schlicht **keine Zugangsdaten für den ausgehenden Server (SMTP) angegeben**,
da dies in den Kontoeinstellungen als optional markiert war.

Die UI macht den Eindruck, dass die Mail App ganz normal die bereits weiter oben
angegebenen Zugangsdaten nutzen würde, wenn die Felder für SMTP leer sind. Weit gefehlt.
Die Mail App versucht dann einen unauthentifizierten Versand, der natürlich abgelehnt wird.

Scheiß Fehlermeldung, scheiß UI.
