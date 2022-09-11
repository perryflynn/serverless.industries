---
author: christian
title: Raspberry Pi Touchscreen als Lampe in Home Assistant
locale: de
tags: [ linux, raspberry pi, smart home, home assistant ]
---

Um Touchscreen und Flurlicht gleichzeitig via Bewebungsmelder an- und ausschalten
zu können, ist der Touchscreen [als Lampe in Home Assistant][tpllight] eingebunden.

Die Kommunikation findet dabei über SSH statt.

Über einen SSH Force Command wird ein Shell Script aufgerufen, welches den
Touchscreen steuert.

[tpllight]: https://www.home-assistant.io/integrations/light.template/

```yml
# home assistant configuration.yml
shell_command:
  dashdisplay_on: ssh -oConnectTimeout=3 -oStrictHostKeyChecking=no -q -i /config/ssh/dashdisplay.key pi@192.168.42.42 -- --on
  dashdisplay_off: ssh -oConnectTimeout=3 -oStrictHostKeyChecking=no -q -i /config/ssh/dashdisplay.key pi@192.168.42.42 -- --off
  dashdisplay_status: ssh -oConnectTimeout=3 -oStrictHostKeyChecking=no -q -i /config/ssh/dashdisplay.key pi@192.168.42.42 -- --displaystatus

# manually defined lights
light:
  - platform: template
    lights:
      dashdisplay:
        friendly_name: "Dashboard Display"
        entity_id:
          - binary_sensor.dashdisplay_status
        turn_on:
          service: shell_command.dashdisplay_on
        turn_off:
          service: shell_command.dashdisplay_off
        value_template: >-
          {{states('binary_sensor.dashdisplay_status')}}
```

```txt
# raspberry pi ~/.ssh/authorized_keys
command="/home/pi/display.sh",no-port-forwarding,no-X11-forwarding,no-pty ssh-rsa AAAAB3[....]
```

Das Script nutzt `xset dpms` um den Bildschirm an- und auszuschalten und
`/sys/class/backlight/rpi_backlight/brightness` um die Helligkeit des Displays zu
steuern.

```sh
#!/bin/bash
# /home/pi/display.sh

export DISPLAY=:0
TIMEOUT=120
BACKLIGHT="/sys/class/backlight/rpi_backlight/brightness"

# arguments
DOINIT=0
DOON=0
DOOFF=0
DODISPLAYSTATUS=0
DOSETBRIGHTNESS=-1
DOGETBRIGHTNESS=0

parseargs() {
    while [[ $# -ge 1 ]]
    do
        key="$1"
        case $key in
            --init)
                DOINIT=1
                ;;
            --on)
                DOON=1
                ;;
            --off)
                DOOFF=1
                ;;
            --get-brightness)
                DOGETBRIGHTNESS=1
                ;;
            --set-brightness)
                DOSETBRIGHTNESS="$2"
                shift
                ;;
            --displaystatus)
                DODISPLAYSTATUS=1
                ;;
            *)
                # unknown option
                ;;
            esac
        shift # past argument or value
    done
}


# script commands
parseargs $SSH_ORIGINAL_COMMAND

if [ "$DOINIT" == "1" ]; then
    # disable screensaver
    xset s off
    # enable dpms
    xset +dpms
    # set timeout standby/suspend/off
    xset dpms "$TIMEOUT" "$TIMEOUT" "$TIMEOUT"
fi

if [ "$DOON" == "1" ]; then
    # wake screen
    xset dpms force on
elif [ "$DOOFF" == "1" ]; then
    # fall asleep
    xset dpms force off
fi

if [ "$DODISPLAYSTATUS" == "1" ]; then
    # get the current display status
    xset q | grep "Monitor is" | sed 's/.*Monitor is //g' | tr '[:upper:]' '[:lower:]'
fi

if [ "$DOGETBRIGHTNESS" == "1" ]; then
    # show the brightness
    cat "$BACKLIGHT"
elif [ "$DOSETBRIGHTNESS" -ge 0 ] && [ "$DOSETBRIGHTNESS" -le 255 ]; then
    # change the brightness
    sudo sh -c "echo $DOSETBRIGHTNESS > $BACKLIGHT"
fi
```
