---
author: christian
title: Powershell + Invoke-Webrequest in Systemdiensten
lang: de
ref: powershell-webrequests-systemservices
tags: ['windows', 'powershell']
---

Die [Invoke-WebRequest][invoke] Funktion in PowerShell extrahiert im Standardverhalten
Bilder, Formularfelder, Links aus dem Response und stellt diese als separate Properties
bereit.

Dafür benutzt die Funktion den Internet Explorer, welcher für den System Account von Windows
natürlich nicht zur Verfügung steht. Der Aufruf von `Invoke-WebRequest` führt zu folgender
Fehlermeldung:

> The response content cannot be parsed because the Internet Explorer engine is not available,
> or Internet Explorer's first-launch configuration is not complete.
> Specify the UseBasicParsing parameter and try again.

Mit der Option `-UseBasicParsing` kann man dieses Verhalten deaktivieren:

```ps1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$result = Invoke-WebRequest -UseBasicParsing -Uri "https://localhost/api/getawesomethings"
```

Ab Powershell 6 ist das "extended Parsing" veraltet und es wird standardmäßig
das "basic parsing" verwendet. Die Option sollte man aber zur Kompatibilität
mit älteren Windows Systemen dennoch setzen.

[invoke]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest
