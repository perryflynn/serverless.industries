---
author: christian
title: "Control Home Assistant Enities with Windows / PowerShell"
locale: en
tags: [ windows, powershell, home assistant, smart home ]
---

The [Home Assistant API](https://developers.home-assistant.io/docs/api/rest/) allows it to control
Smart Home Entities very easily from any scripting language. The following Power Shell Script 
allows it to toggle, turn on or turn off entities like switches or lights.

If the parameter `-networkAdapterMac` is defined, the script first checks if this interface is
available and online. This is used to ensure, that a Laptop is connected to a certain docking
station.

```powershell
#Requires -Version 7.4

<#
.SYNOPSIS
    Toggle a Home Assistant Entity
.DESCRIPTION
    Toggle a Home Assistant Entity like a light
.NOTES
    Author: Christian <christian@serverless.industries>
.EXAMPLE
    .\toggle-entity.ps1 -hassUrl "https://hass.example.com" -apiKey "XXXXX" -action turn_on -entityName light.foo"
    .\toggle-entity.ps1 -hassUrl "https://hass.example.com" -apiKey "XXXXX" -action turn_off -entityName light.foo"
    .\toggle-entity.ps1 -hassUrl "https://hass.example.com" -apiKey "XXXXX" -action toggle -entityName light.foo"
    .\toggle-entity.ps1 -hassUrl "https://hass.example.com" -apiKey "XXXXX" -action toggle -entityName light.foo" -networkAdapterMac "0A-00-27-00-00-09"
#>

param (
    [Parameter(Mandatory=$true)][string]$hassUrl,
    [Parameter(Mandatory=$true)][string]$apiKey,
    [Parameter(Mandatory=$true)][ValidateSet('turn_on', 'turn_off', 'toggle')][string]$action,
    [Parameter(Mandatory=$true)][string]$entityName,
    [Parameter(Mandatory=$false)][string]$networkAdapterMac = ""
)

if ($networkAdapterMac -eq "" -or (Get-NetAdapter | Where-Object { $_.MacAddress -eq "$networkAdapterMac" -and $_.Status -eq "Up" }).Length -gt 0)
{
    $secureApiKey = ConvertTo-SecureString -String "$apiKey" -AsPlainText -Force

    Invoke-WebRequest `
        -Uri "$hassUrl/api/services/homeassistant/$action" `
        -Method POST `
        -Authentication Bearer `
        -Token $secureApiKey `
        -ContentType application/json `
        -Body "{ ""entity_id"": ""$entityName"" }"
}
```
