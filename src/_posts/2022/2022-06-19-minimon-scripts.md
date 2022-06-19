---
author: christian
title: minimon.sh mit Script Support
locale: de
tags: [ monitoring, bash, projects ]
---

[minimon.sh][minimon] unterstützt nun eigene Shell Script zur Überwachung von
Services. Das Script kann dabei eine Zeile Text und einen Status Code zurück
geben. 

[minimon]: https://github.com/perryflynn/minimon

Beispiel Script (`scrdemo`):

```sh
#!/usr/bin/env bash
echo "script output here"
exit 1

# exit 0 = OK
# exit 1 = WARN
# exit 2 = NOK
# exit 3 = UNKNOWN
```

Der Aufruf:

```sh
./minimon.sh --script "./scrdemo;demo"
```

```
[2022-06-19T23:30:56+02:00] script_demo - ./scrdemo - WARN (1) - 0.226s - script output here
```

Ein Anwendungsbeispiel wäre zum Beispiel die Überwachung einer SQL Abfrage und dessen
Performance.
