---
author: christian
title: More features for my windows config script
locale: en
tags: [ windows, powershell, projects:wincfg ]
---

My [set-policies.ps1](https://github.com/perryflynn/my-windows-config/blob/main/set-policies.ps1)
disables many annoying features like Cortana, One Drive or Telemetry on Windows 10 Pro machines.
The script got some new features. It prevents now for example a involunary Windows 11 upgrade.

All new features:

- Prevent upgrade to Windows 11
- Disable "soft-disconnecting" Wifi (no disconnect if a Wifi has no internet connection)
- Disable PowerShell telemetry
