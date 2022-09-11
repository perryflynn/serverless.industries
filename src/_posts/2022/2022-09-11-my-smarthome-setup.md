---
author: christian
title: Mein Smarthome Setup
locale: de
tags: [ linux, nginx, network, docker, smart home, home assistant ]
---

Mein Smarthome besteht komplett aus Docker Containers mit zwei NGINX Webservern
als Frontend, welche die einzelnen Dienste von außen erreichbar machen.

![Smarthome 2022]({{'assets/smarthome-2022.png' | relative_url}}){:.img-fluid}
([in neuem Tab öffnen]({{'assets/smarthome-2022.png' | relative_url}}))

## Docker Netze mit gerouteten IP Adressen

Den Anfang macht ein [macvlan Docker Network][macvlan] welches es erlaubt, IP Adressen
aus einem "echten" VLAN einem Container zuzuordnen, als ob der Container ein Server wäre.

[macvlan]: https://docs.docker.com/network/macvlan/
[httpproxy]: https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/
[portpublish]: https://docs.docker.com/config/containers/container-networking/#published-ports
[usbip]: https://wiki.ubuntuusers.de/USBIP/
[zha]: https://www.home-assistant.io/integrations/zha/
[hassinflux]: https://www.home-assistant.io/integrations/influxdb/
[esphome]: https://esphome.io/index.html

```sh
docker network create -d macvlan \
  --subnet=192.168.99.0/24 \
  --ip-range=192.168.99.224/28 \
  --gateway=192.168.99.254 \
  --aux-address="my-router=192.168.99.1" \
  -o parent=eth0 srv
```

Mit `--ip-range` kann dabei ein Subset des eigentlichen VLANs definiert werden,
aus dem die IP Adressen benutzt werden. Sodass weiterhin für DHCP und Server
noch Platz ist und es nicht zu IP Konflikten kommt.

Jeder Dienst hat dadurch eine echte IP Adresse und kann ganz einfach aus dem lokalen
Netzwerk erreicht werden.

## NGINX TCP/UDP Streams

Neben den normalen [HTTP Reverse Proxy][httpproxy] beherrscht NGINX auch das weiterleiten
von TCP oder UDP Verbindungen. Das mache ich mir zunutze, um Dienste aus getrennten
Containers logisch unter einer IP Adresse zusammenzufassen.

So kommt das Setup komplett ohne [port publishing][portpublish] aus.

```conf
stream {
    resolver 127.0.0.11;
    server {
        listen 1883;
        set $proxy_destination "mosquitto:1883";
        proxy_pass $proxy_destination;
    }
}
```

## ZigBee über USB/IP

Der ZigBee USB Dongle, welcher in der Wohnung die Lampen und Schaltsteckdosen steuert, 
muss irgendwie mit dem Docker Host im Keller verbunden werden.

[USB/IP][usbip] ist ein großartiges Werkzeug dafür, welches erlaubt USB Geräte von
einem Linux Host auf einen anderen weiter zu leiten.

```sh
# Raspberry Pi in der Wohnung
modprobe usbip-host
usbipd -D
usbip list -l
usbip bind 1-1.5

# Docker Host im Keller
modprobe vhci-hcd
usbip attach -r "192.168.42.42" -b "1-1.5"
docker run [...] --device "/dev/ttyACM0:/dev/ttyACM0:rwm" homeassistant/home-assistant:latest
```

Alles weiter macht dann die [ZHA Integration in Home Assistant][zha].

## Home Assistant Geräte in Grafana

Die [InfluxDB Integration in Home Assistant][hassinflux] ermöglicht es die Sensoren auch in Grafana
zu visualisieren, was je nach Anwendungsfall viel hübscher und komfortabler sein kann,
als die Diagramme in Home Assistant.

```yml
# configuration.yml
influxdb:
  host: influxdb
  ssl: false
  verify_ssl: false
  username: hass
  password: hass
  database: hass
  include:
    domains:
      - sensor
      - binary_sensor
  exclude:
    entities:
      - sensor.date_time
      - sensor.time
```

![Smarthome Grafana]({{'assets/smarthome-2022-grafana.png' | relative_url}}){:.img-fluid}

## esphome.io Sensoren

[ESPHome][esphome] ist ein Baukasten für ESP32 Microcontroller welcher anhand einer YAML Konfiguration
dynamisch ein Firmeware Image erzeugt und flashed. Der Microcontroller kommuniziert dann via
WLAN und MQTT mit Home Assistant.

Die Schnittstelle zwischen Home Assistant und ESPHome ist standardisiert,
wodurch die Sensoren **automatisch** von Home Assistant erkannt und eingerichtet werden.

```yml
# esphome temperatur sensor
esphome:
  name: esp-livingwindow
  platform: ESP32
  board: nodemcu-32s

wifi:
  ssid: "WifiNetwork"
  password: "xxxxxxxxxxxxxxxxx"

ota:
  password: "yyyyyyyyyyyyyyyyy"

logger:

dallas:
  - pin: 23
    update_interval: 60s

sensor:

  - platform: dallas
    address: 0xD5012062F1642B28
    resolution: 12
    name: "Livingroom Outdoor Temperature"
    state_topic: smarthome/livingroomwindow/outdoor/temperature
    filters:
      - median:
          window_size: 5
          send_every: 5
          send_first_at: 5

mqtt:
  broker: hass.example.com
  username: esphome
  password: xxxxxxxxxxxxxxx
  discovery: True
  discovery_retain: True
  topic_prefix: smarthome/livingroomwindow
```

```yml
# home assistant configuration.yml
mqtt:
  broker: mosquitto
  port: 1883
  username: hass
  password: hass
  discovery: true
  discovery_prefix: homeassistant
```

## Linux Bildschirm als Lampe

Im Flur steht ein Raspberry Pi mit Touchscreen als Home Assistant Dashboard.
Damit Flurlicht und Display zeitgleich über einen ZigBee Bewegungsmelder 
an- und ausgeschaltet werden können, ist das Touchscreen Display als "Lampe"
in Home Assistant eingebunden.

Die Kommunikation zwischen Display und Home Assistant findet dabei via SSH statt.

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
          {{'{{'}}states('binary_sensor.dashdisplay_status')}}
```
