---
author: christian
title: Raspberry Pi Zero W Kamera via Twitch streamen
locale: de
ref: rpicam-stream-twitch
tags: [ "raspberry pi", streaming ]
---

Seit einigen Tagen haben wir in der [nerdbridge](https://nerdbridge.de/) einen 3D Drucker.
Um die meist langwierigen Druckaufträge auch von Zuhause/Unterwegs überwachen zu können,
lasse ich einen Raspberry Pi Zero W mit einer Raspberry Pi Kamera via Twitch streamen.

## Was gebraucht wird

- Einen Twitch Account
- Den Stream Key des Twitch Accounts
- Raspberry Pi Zero W + Raspberry Pi Kamera
- Irgendwas zum befestigen und ausrichten

![Camera]({{'/assets/rpi-3dprinter-steamcam01.jpg' | relative_url}}){:.img-fluid}

![Camera]({{'/assets/rpi-3dprinter-steamcam02.jpg' | relative_url}}){:.img-fluid}

## Installation

- Das aktuellste Raspbian installieren
- Via `raspi-config` die Kamera aktivieren
- Das Paket `libav-tools` installieren

## Das Script

```sh
#!/bin/bash

# https://stream.twitch.tv/ingests/

# twitch settings
STREAMKEY=live_XXXXXXXXX_YYYYYYYYYYYYYYYYYYYYYYYYYYYYY
ENDPOINTS=(rtmp://live-fra.twitch.tv/app rtmp://live-ber.twitch.tv/app rtmp://live-ams.twitch.tv/app)

# stream settings
VIDEOFPS=25
BITRATE=2000000
CONVFRAMERATE=30
CONVGOP=30
CONVPIXFORMAT=yuv420p
CONVOUTFORMAT=flv

I=0
while true
do

    # get the current endpoint
    EPIDX=$(( $I % ${#ENDPOINTS[@]} ))
    CURENDPOINT=${ENDPOINTS[$EPIDX]}

    echo "Using $CURENDPOINT as twitch endpoint"

    # start the stream
    raspivid -t 0 -fps $VIDEOFPS -b $BITRATE -o - | \
        avconv -i - -vcodec copy -an \
            -r $CONVFRAMERATE \
            -g $CONVGOP \
            -bufsize $BITRATE \
            -pix_fmt $CONVPIXFORMAT \
            -f $CONVOUTFORMAT \
            "$CURENDPOINT/$STREAMKEY"

    # cooldown when stream was aborted
    echo
    echo "Stream exited unexpected. Wait 60 seconds and restart..."
    echo

    sleep 60

    # jump to next endpoint
    I=$(( $I + 1 ))

done
```

## Funktionsweise

Twitch stellt [auf einer Seite](https://stream.twitch.tv/ingests/) verschiedene Endpunkte
für das Einspeisen von Videosignalen via [rtmp](https://de.wikipedia.org/wiki/Real_Time_Messaging_Protocol)
zur Verfügung. Das Script verbindet sich mit einem der
drei Endpunkte und beginnt das Kamerabild zu streamen.

Kommt es zu einem Verbindungsabbruch wird nach einer Pause von 60 Sekunden die Verbindung zum
nächsten Endpunkt in der Liste hergestellt.

Ich empfehle das Script in einer `screen` Session laufen zu lassen.

## Weitere Ideen

- Script als systemd daemon installieren
- LED welche signalisiert ob gestreamt wird
- Push Button welcher den Stream starten bzw stoppen kann

## Quellen

- [https://www.makeuseof.com/tag/live-stream-youtube-raspberry-pi/](https://www.makeuseof.com/tag/live-stream-youtube-raspberry-pi/)
- [https://www.hackster.io/tinkernut/raspberry-pi-twitch-o-matic-190a15](https://www.hackster.io/tinkernut/raspberry-pi-twitch-o-matic-190a15)
- [https://stream.twitch.tv/ingests/](https://stream.twitch.tv/ingests/)
