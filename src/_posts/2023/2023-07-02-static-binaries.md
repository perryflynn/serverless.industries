---
author: christian
title: Static Binaries
locale: de
ref: static-binaries
tags: [ linux, server, shell, debugging, projects, projects:static-binaries ]
excerpt_separator: <!-- more -->
---

Beim debuggen von Problemen in Container Umgebungen oder auf Geräten wie Routern gibt es immer
das gleiche Problem: Die ganzen Standardwerkzeuge fehlen.

Die Software Pakete zu installieren ist oft keine Option, insbesondere in Umgebungen wo es
aus Sicherheitsgründen kein Internet gibt.

<!-- more -->

Abhilfe können hier statische Builds der Programme sein. Kompiliert man ein Programm statisch,
enthält eine einzelne Programmdatei alle sonst benötigen Abhängigkeiten und kann einfach
kopiert werden und funktioniert.

Nachteil ist die Dateigröße der Programme. Ein statisch kompiliertes `dig` ist knapp 6 Megabytes
groß, wohingegen das `dig` aus den Paketquellen nur 200KB groß ist.

[files]: https://files.serverless.industries/bin/
[info]: https://files.serverless.industries/bin/info.txt
[qemu]: https://github.com/multiarch/qemu-user-static
[code]: https://github.com/perryflynn/static-binaries

## Downloads

Die statischen Programme gibt es hier: [https://files.serverless.industries/bin/][files]

Unterstützte CPU Architekturen: `x86` (`i386`), `x86_64` (`amd64`), 
`ARM32v7` (`armv7`), `ARM64v8` (`aarch64`)

Programme: `busybox`, `curl`, `dig`, `htop`, `iperf2`, `iperf3`, `jq`, `rsync`, `scp`, `sftp`, 
`ssh-keygen`, `ssh-keyscan`, `ssh`, `tcpdump`, `vim`

Mehr Details gibt es in der [info.txt][info].

## Build Scripts

Die Builds laufen in meiner privaten Gitlab Instanz in CI Pipelines mit Docker Containers.
Andere CPU Architekturen werden mit Hilfe von [multiarch/qemu-user-static][qemu] gebaut.

Der Build Prozess erzeugt für jede CPU Architektur ein Basis Image welches alle nötigen
Werkzeuge zum kompilieren der Programme enthält, kompiliert anschließend die Programme und
[lädt diese hoch][files].

Einen Mirror des Pipeline Codes gibt es auf [meinem GitHub Account][code].
