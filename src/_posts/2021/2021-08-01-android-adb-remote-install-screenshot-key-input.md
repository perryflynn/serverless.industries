---
author: christian
title: Android Geräte mit ADB vom Netzwerk steuern
locale: de
tags: [ android, 'software development', 'smart home' ]
toc: true
---

Auf meiner FireTV Box sind diverse Android Apps installiert, welche man so
im Amazon Store nicht findet. Zum Beispiel [Kodi][kodi] oder [VLC][vlc].

Mit den [Android Debug Bridge Tools][adb] (in den [Platform Tools][platools] enthalten)
kann man sich dabei eine ganze Menge Ärger ersparen. Die Tools erlauben
zum Beispiel das Installieren von Apps vom PC aus.

[kodi]: https://kodi.tv/download/android
[vlc]: https://www.videolan.org/vlc/download-android.html
[platools]: https://developer.android.com/studio/releases/platform-tools
[adb]: https://developer.android.com/studio/command-line/adb

## Android Debugging aktivieren

Zuerst muss das Debugging in Android aktiviert werden. Dies erlaubt es vom Netzwerk
aus auf das Gerät zuzugreifen.

Beim ersten Zugriffsversuch des PCs auf den FireTV muss
der Zugriff gestattet werden. Anschließend hat der PC Vollzugriff.

![FireTV Android Debugging]({{'assets/firetv-adb.png' | relative_url}}){:.img-fluid}

## ADB Verbinden

```txt
# ./adb connect 192.168.13.11:5555
connected to 192.168.13.11:5555
```

```txt
# ./adb devices
List of devices attached
192.168.13.11:5555    device
```

## APKs installieren

Neue App installieren:

```txt
# ./adb install VLC-Android-3.3.4-armeabi-v7a.apk 
Performing Push Install
VLC-Android-3.3.4-armeabi-v7a.apk: 1 file pushed. 3.2 MB/s (30990469 bytes in 9.174s)
    pkg: /data/local/tmp/VLC-Android-3.3.4-armeabi-v7a.apk
Success
```

App aktualisieren:

```txt
# ./adb install -r kodi-19.1-Matrix-armeabi-v7a.apk 
Performing Push Install
kodi-19.1-Matrix-armeabi-v7a.apk: 1 file pushed. 3.1 MB/s (75796367 bytes in 23.594s)
    pkg: /data/local/tmp/kodi-19.1-Matrix-armeabi-v7a.apk
Success
```

## Textfelder ausfüllen

Über die ADB Shell kann das Tool `input` benutzt werden, um Text auf dem Android Gerät
schreiben zu lassen.

```sh
./adb shell "input keyboard text 'my-awesome-long-password-which-is-annoying-to-type'"
```

## Bildschirm abdunkeln verhindern

Sobald der FireTV den Bildschirmschoner aktiviert, geht oft der aktuell pausierte Film
verloren und man muss diesen neu aus dem "Weiterschauen" Menü starten. Über ADB kann man
die Timeouts (Millisekunden; Sekunde x 1000) für Bildschirmschoner und Bildschirm abdunkeln verändern.

Bildschirmschoner nach einer Stunde aktivieren:

```sh
./adb shell settings put system screen_off_timeout 3600000
```

Bildschirm nach drei Stunden ausschalten:

```sh
./adb shell settings put secure sleep_timeout 10800000
```

Quelle: [aftvnews.com](https://www.aftvnews.com/how-to-set-custom-sleep-or-screensaver-times-on-the-amazon-fire-tv-or-stick-without-root/)

## Screenshot erstellen

```sh
./adb exec-out screencap -p > screen.png
```

## Neustart

```sh
./adb reboot
```
