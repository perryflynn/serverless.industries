---
author: christian
title: "Systemauslastung von Webspaces"
locale: de
ref: webspace-sysinfo
tags: ['php', 'webspace', 'linux', 'projects', 'server']
---

Um [Performance Probleme auf einem Webspace][nc] besser analysieren zu können,
habe ich ein kleines Script mit dem Namen [perrylfynn/sharedinfo][git] gebaut.

Es ermittelt die aktuelle Systemlast aus dem `/proc` Verzeichnis
von Linux und errechnet daraus eine Zusammenfassung:

```txt
Bootup Time:
    2020-05-14 15:44
CPU Clock:
    1799.997 MHz
CPU Core Count:
    16
Load Average:
    3.43 (1m); 3.23 (5m); 3.28 (15m)
System usage (5 minutes load average):
    20.19%
System Usage (5 seconds average):
    17.84% busy, 82.16% idle, 6.65% iowait, 0.02% steal
Total Memory:
    64,433.62 MByte
Available Memory:
    35,043.76 MByte
Used Memory:
    29,389.86 MByte
Committed Memory:
    93,162.57 MByte
```

[Demo][demo]

Have fun.

[nc]: https://forum.netcup.de/anwendung/wcp-webhosting-control-panel/p137503-load-auf-webhosting-8000/#post137503
[git]: https://github.com/perryflynn/sharedinfo
[demo]: https://hacks.hosting109020.a2f12.netcup.net/
