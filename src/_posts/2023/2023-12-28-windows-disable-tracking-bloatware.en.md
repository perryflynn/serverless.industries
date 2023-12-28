---
author: christian
title: Disable Bloatware, Tracking and other nasty stuff with PowerShell
locale: en
tags: [ windows, powershell ]
---

Windows 10 comes with alot of annoying tracking features, bloatware and other
nasty stuff. As long as the system is licensed as Pro Edition, it is possible
to disable alot of this stuff with Group Policies.

Group Policies are normally managed by Active Directoy, which requires one or
more Windows Servers. But Policies can also managed with PowerShell and the
[PolicyFileEditor Module](https://github.com/dlwyatt/PolicyFileEditor).

{% include box.html type='warning' message="The following script was created for my machines. Some of it's features may not suit you needs." %}

My script [set-policies.ps1](https://github.com/perryflynn/my-windows-config/blob/main/set-policies.ps1)
will apply the following changes to Windows:

## Group Policies

- Disable the Windows Advertising ID
- Disable data collection for the Input Personalisazion
- Disable online tips
- Disable cloud features
- Disable telemetry and feedback
- Disable data collection in Microsoft Edge
- Disable Flash in Microsoft Edge
- Disable interactive "New Tab" Page in Microsoft Edge
- Disable Windows Preview Builds
- Disable Microsoft Accounts
- Disable Windows News and Interest Feeds
- Disable Cortana, Cloud and Internet Search in Windows Search
- Disable Windows Settings synchronization
- Disable automatic Windows Updates
- Download updates and schedule the installation every day at 03:00
- Disable reboot for Windows Updates if a User is logged in
- Disable Windows Update P2P
- Disable device wake up for windows updates
- Disable error reporting to Microsoft
- Disable consumer experience reporting to Microsoft
- Disable application telemetry
- Disable auto connect to suggested Wifi Hot Spots
- Disable OneDrive

## Uninstall Bloatware

If the magic file `C:\configs\enable-uninstallpackages.txt` exists, the script will try to
uninstall the following AppX packages:

- 3dbuilder
- 3dviewer
- bingfinance
- bingnews
- bingsports
- bingweather
- disney
- feedbackhub
- getstarted
- netflix
- officehub
- oneconnect
- onenote
- people
- print3d
- skypeapp
- solitairecollection
- soundrecorder
- tuneinradio
- twitter
- windowsalarms
- windowscamera
- windowscommunicationsapps
- windowsmaps
- windowsphone
- xbox
- zunemusic
- zunevideo
- xing
- king.com

The strings are used for searching for the full package names and can match multiple packages.
Please check the list with the following commands on your system to make sure, that no
package you need is uninstalled by mistake.

```ps1
Get-AppxPackage -AllUsers -Name "*xbox*"
Get-AppXProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*xbox*" }
```

{% include box.html type='error' message="Careful! Some of the packages cannot be reinstalled by the Microsoft Store!" %}

## Other Features

- Show last login info on logon (If magic file `C:\configs\enable-logoninfo.txt` exists)
- Create symlinks for `shutdown /r` and `shutdown /s` on the Desktop  (If magic file `C:\configs\enable-trueshutdown-icon.txt` exists)
- Apply new group policies
- Create a policy report at `C:\Temp\GPReport.html`
