---
author: christian
title: "Webhosting: Nur ein Cronjob erlaubt"
lang: de
ref: webhosting-cron-limit
tags: [linux, php, webspace]
---

Diverse Webhoster sind im Jahr 2010 hängen geblieben, und limitieren
die Webhosting Tarife weiterhin sinnlos. In diesem Fall erlaubte
ein Anbieter nur einen einzigen Cronjob pro Webhosting Account.

Da der Webserver selbst recht Standard ist und es keine großen
Einschränkungen gibt, lässt sich das mit einem PHP Script
sehr einfach umgehen.

```php
<?php

// enforce execution by CLI
if (php_sapi_name() !== 'cli')
{
    echo "This script is CLI-only.";
    exit;
}

// change directory to prevent open_basedir issues
chdir("/var/www/web165/html");

// execute our commands
echo shell_exec('nohup php first-cron.php 2>&1 &')
echo shell_exec('nohup php second-cron.php 2>&1 &')
```

Mit `nohup` wird das `HUP` Signal welches Linux an alle Kindprozesse
sendet wenn das PHP Script beendet wird unterdrückt. Das heißt,
alle hier gestarteten Prozesse laufen so lange weiter, wie es nötig ist.

Da `shell_exec` nur den Standard Output zurück gibt, wird mit `2>&1` der
Standard Error Output an den Standard Output umgeleitet, sodass in der
Ausgabe auch Fehler angezeigt werden.

Das `&` Zeichen am Ende des Befehls bewirkt, dass ein Background Job
erzeugt wird. `shell_exec` beendet sich dadurch direkt nach dem Start des
Befehls, der Befehl läuft aber im Hintergrund weiter.

So ist es möglich, beliebig viele Prozesse **parallel** zu starten.
Möchte man die Prozesse zu unterschiedlichen Zeiten starten, muss man
natürlich das Script noch ein wenig erweitern.
