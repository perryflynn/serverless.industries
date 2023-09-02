---
author: christian
title: "minimon Update 2023.1: Job Parallelisierung und JSON Config Files"
locale: de
tags: [ monitoring, bash, projects ]
---

[minimon.sh](https://github.com/perryflynn/minimon) unterstützt in der neusten Version
Job Parallelisierung und das Laden von Checks aus JSON Files. Das soll vor allem die
Nutzung mit einer größeren Menge von Checks erleichtern.

## Parallelisierung

Mit dem Parameter `--parallel 10` kann angegeben werden, wie viele Checks gleichzeitig
ausgeführt werden. Standardmäßig ist dieser Wert auf 10 eingestellt.

Realisiert wird dies über Bash Background Jobs:

```sh
curl https://example.com &
curl https://serverless.industries &
wait
echo "Both jobs are done"
```

Das `&` am Ende der Zeilen verschiebt den entsprechenden Befehl in den Hintergrund,
in einen neuen Prozess. Mit `wait` kann dann auf das Fertigstellen aller aktiven Jobs
gewartet werden.

## JSON Config Files

Mit dem Parameter `--config` können fast alle Einstellungen aus einer JSON Datei
geladen werden. 

```json
{
    "$schema": "https://files.serverless.industries/schemas/minimon.json",
    "checks": [
        { "type": "icmp", "url": "127.0.0.1", "alias": "localhost" },
        { "type": "http", "url": "https://serverless.industries", "alias": "blog" },
        { "type": "script", "url": "./plugins/certexpire serverless.industries:443", "alias": "blog_cert" }
    ],
    "interval": 10,
    "parallel": 2,
    "timeout": 5,
    "connect-timeout": 2,
    "short-timestamps": true
}
```

Geöffnet in einem Editor wie VSCode, ermöglicht der `$schema` Parameter Autovervollständigung
und Syntaxprüfung der JSON Datei.
