---
author: christian
title: Unifi Controller auf Debian 12 Bookworm
locale: de
ref: unifi-apt-repo
tags: [ debian, apt, unifi, network, projects, projects:packagerepos ]
---

Schon seit einigen Jahren ist der Betrieb von Unifi WLAN Produkten kein Spaß mehr.
2020 sind diverse APs die wir einsetzen ohne Vorwarnung oder Kompensation EOL gegangen
und waren Elektroschrott, sobald man den Unifi Controller auf eine neuere Version als
5.6 gebracht hat.

Auch war Debian Stretch der letzte Release, wo das benötigte MongoDB 3.7 noch ohne
Frickelleien verfügbar war. Neuere Debian Versionen werden ohne manuelle Arbeit
schlicht nicht unterstützt. Bis heute.

## Neu Verpacken

Das Hauptproblem beim Unifi Controller ist, dass die Paket Abhängigkeiten
zu restriktiv sind. `mongodb-server (<< 1:4.0.0)` sorgt dafür, dass nur MongoDB Versionen
kleiner als 4.0 akzeptiert werden.

Das Projekt [unifi-repack von Julien Lecomte][repack] ändert dies. Ein Script entpackt
das Debian Paket, entfernt diese Einschränkung und packt es erneut.

[repack]: https://gitlab.com/jlecomte/unifi-repack

## Serverless Packages Repo

Von dem Projekt habe ich mir einen Fork erstellt und kurzerhand ein eigenes APT Repo
ausgerollt. Das Repo enthält diverse Versionen des Unifi Controllers wo die MongoDB
Version "entsperrt" ist und auch passende MongoDB 4.4 Pakete, für den Fall das diese
beim EOL von MongoDB 4.4 im Februar nächsten Jahres aus den ofiziellen Repos verschwinden.

```
root@ubnt:~# apt-cache madison unifi
     unifi | 7.4.162-21057-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 7.3.83-19645-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 7.2.97-18705-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 7.1.68-17885-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 7.0.25-17292-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 6.5.55-16678-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 6.5.54-16676-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 6.4.54-16067-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 5.14.23-13880-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 5.6.42-10376-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
     unifi | 5.6.40-10370-1+unlocked | https://files.serverless.industries/apt/repo hopefullystable/unifi amd64 Packages
```

Neuere Versionen wie MongoD 5 oder 6 werden nicht unterstützt und lassen den Unifi
Controller abstürzen.

GnuPG key importieren:

```sh
curl -fsSL https://files.serverless.industries/apt/serverless-packages.asc | \
   sudo gpg -o /usr/share/keyrings/serverless-packages.gpg --dearmor
```

Paketquelle hinzufügen:

```sh
echo "deb [signed-by=/usr/share/keyrings/serverless-packages.gpg] https://files.serverless.industries/apt/repo hopefullystable mongodb44 unifi" | \
    sudo tee /etc/apt/sources.list.d/serverless-packages.list
```

Der Distributionsname `hopefullystable` ist hier auch ernst gemeint. Ich nutze die Pakete
selbst, und es funktioniert soweit alles. Nutzung dennoch auf eigene Gefahr, da MongoDB 4.4 nicht
offiziell von unifi unterstützt wird.

## Upgrade Hinweise

Bis jetzt hatte ich die ganze Situation ausgesessen und noch ein Debian Stretch im Einsatz.
Jetzt war das Upgrade auf Debian Bookworm dran. Einige Dinge, die dabei passiert sind.

### Vorbereitungen

- Datensicherung der Unifi Konfiguration über das offizielle Backup Feature
- Snapshot/Backup des Servers machen
- Serverless Repo hinzufügen
- Offizielles unifi Repo löschen
- Mit `apt-cache madison unifi` prüfen, dass die aktuell eingesetzte Version auch im Repo drin ist
- Ggf. auf die nächste Version aktualisieren, welche im Repo enthalten ist
- Prüfen ob unifi noch funktioniert
- Erneut Konfigurationsbackup im Unifi Controller machen

### Upgrade von Stretch auf Buster

Es gibt kein `mongodb-server` mehr in den Repos von Buster. Daher macht es Sinn, vor dem OS Update
alles was mit unifi und MongoDB zu tun hat mit `apt remove --purge mongodb* unifi` 
zu deinstallieren.

Auch Pfade die von apt nicht gelöscht wurden manuell löschen!

Anschließend das Upgrade von Stretch auf Buster durchführen.

### Upgrade von Buster auf Bullseye

Hier gibt es keine besonderen Vorkommnisse. Ganz normal das Update durchführen.

Entscheidet man sich hier `unifi=versionskennung` und `mongodb-org-server` wieder zu installieren,
sollte dies ohne Probleme funktionieren. Der Controller begrüßt einen mit der Ersteinrichtung,
wo das Konfigurationsbackup eingespielt werden kann.

**Man muss die zum Backup passende Version installieren!**

Nach dem Einspielen des Backups bietet es sich an, `unifi` auf die aktuellste Version
hochzuziehen. Möchte man das nicht, sollte man mit `apt-mark hold unifi` das Upgrade
verhindern, da apt dies sonst bei jedem System Update versuchen wird.

Bullseye wird noch bis Juni 2026 mit Updates versorgt. Man könnte also hier einfach stoppen
und Unifi so weiter laufen lassen.

### Upgrade von Bullseye zu Bookworm

Das Update selbst lief wie bei Debian üblich ohne Probleme, der unifi Controller crashte danach
aber an einer neuen OpenJDK Version.

Unifi benötigt OpenJDK 11 aber nutzt trotzdem immer den Debian Default (OpenJDK 17),
obwohl auch OpenJDK 11 installiert ist. Daher kurzerhand die unbenutzten OpenJDK Versionen
deinstallieren:

```
apt remove --purge openjdk-8* openjdk-17* openjdk-7*
```

Nun sollte unifi wieder starten.

```
<launcher> ERROR ContextLoader - Context initialization failed org.springframework.beans.factory.UnsatisfiedDependencyException: 
Error creating bean with name 'alertPushNotificationSender' defined in com.ubnt.service.alert.notification.AlertNotificationSpringContext: 
Unsatisfied dependency expressed through method 'alertPushNotificationSender' parameter 0
```

```
java.lang.reflect.InaccessibleObjectException: Unable to make private java.time.Instant(long,int) 
accessible: module java.base does not "opens java.time" to unnamed module @73a8da0f
```

## Fazit

Unifi ist kaputt und es nervt einfach nur noch. Es sieht auch nicht so aus, als ob sich
daran kurzfristig was ändern wird. Die Kommunikation des Unternehmens ist dabei auch einfach
lächerlich.

Sie verlinken ernsthaft zu [Scripts und Hilfetexten der Community][lolscripts], statt das
Problem selbst zu beheben.

Ich für meinen Teil werde mir einen anderen Hersteller suchen, sobald die Hardware EOL ist
und sich ein Wechsel auf Wifi 6/7 lohnt.

[lolscripts]: https://help.ui.com/hc/en-us/articles/220066768-Updating-Self-Hosted-UniFi-Network-Servers-Linux-
