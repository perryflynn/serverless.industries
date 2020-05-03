---
author: christian
title: "Windows: Befehle mit Systemrechten ausführen"
lang: de
ref: windows-run-as-system
tags: ['windows']
---

Beim Debuggen des [Invoke-WebRequest Problems][invoke] wollte ich das Script
mit dem System Account von Windows starten.

Von Haus aus hat Windows dafür kein Werkzeug an Bord. Aber in den
[Sysinternals gibt es das Tool PsExec][psexec].

```sh
psexec -i -s cmd.exe
```

So lässt sich ein Command Line Fenster mit System Rechten öffnen.

Quelle: [stackoverflow.com][source]

[source]: https://stackoverflow.com/questions/77528/how-do-you-run-cmd-exe-under-the-local-system-account
[psexec]: https://docs.microsoft.com/en-us/sysinternals/downloads/psexec
[invoke]: {% post_url 2020/2020-03-12-powershell-invoke-webrequest-systemservice %}
