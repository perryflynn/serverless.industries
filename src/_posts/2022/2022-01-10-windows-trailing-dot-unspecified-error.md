---
author: christian
title: 'Error 0x80004005: Unbekannter Fehler'
locale: de
ref: windows-file-trailing-dot
tags: [ windows, 'continuous integration', gitlab ]
---

Wir haben versucht eine [Docusaurus][docu] Website auf
einem Windows Server zu deployen. Zum Kopieren der HTML 
Dateien von GitLab Artifacts auf den Windows Server
verwenden wir dabei [chef-client][chef].

[chef]: https://docs.chef.io/chef_client_overview/
[docu]: https://docusaurus.io/

Wird die Website ein zweites Mal deployed, erscheint beim Löschen
der existiertenden Dateien folgende Fehlermeldung:

> Error 0x80004005: Unbekannter Fehler

Der Fehler kam von einem Ordner innerhalb der Website dessen Dateiname
**mit einem Punkt endet**.

Öffnen lässt sich dieser Ordner ebensowenig:

> C:\Temp\foo\release-7.21.1015.6. ist nicht verfügbar. Wenn sich der Speicherort auf dem
> PC befindet, stellen Sie sicher, dass das Gerät oder Laufwerk angeschlossen oder der
> Datenträger eingelegt ist, und wiederholen Sie den Vorgang.

Normalerweise verhindert Windows das Anlegen solcher Dateien und Ordner recht
gut, aber die `archive_file` Chef Resource hat es irgendwie dennoch hinbekommen.

Der Ordner kann aber mit einem CMD Befehl gelöscht werden:

```sh
rd /s /q "\\?\C:\Temp\foo\release-7.21.1015.6."
```

Quelle: [https://stackoverflow.com/a/4123152](https://stackoverflow.com/a/4123152)
