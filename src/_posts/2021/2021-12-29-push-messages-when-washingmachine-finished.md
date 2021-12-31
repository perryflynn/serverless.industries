---
author: christian
title: Push Nachricht wenn die Waschmaschine fertig ist
lang: de
#ref: washingmachine-push-mystrom-hass
tags: [ smart home, home assistant, grafana ]
image: /assets/mystrom-finished.jpg
---

Mein Waschtrockner ist zwar smart, allerdings nur via Hersteller Cloud und
einer unpraktischen App. Daher würde ich das nur sehr ungerne nutzen.

Eigentlich möchte ich einfach nur eine Push Nachricht erhalten, wenn
die Waschmaschine fertig ist. (Steht im Keller)

![myStrom Finished]({{'assets/mystrom-finished.jpg' | relative_url}}){:.img-fluid}

Der [WiFi Switch von myStrom](https://mystrom.com/de/wifi-switch/) ist eine
WLAN Steckdose welche neben dem an- und ausschalten via HTTP Request auch
den Stromverbrauch misst.

## Benachrichtigung anhand des Stromverbrauchs

Anhand des Stromverbrauchs kann man sehr gut erkennen, wann die Waschmaschine
fertig ist. Man kann sich also ein Smarthome System schnappen und folgende
Regel implementieren:

> Wenn der Stromverbrauch für 15 Minuten unter 10 Watt fällt, sende
> eine Push Benachrichtigung.

![myStrom Graph]({{'assets/mystrom-graph.jpg' | relative_url}}){:.img-fluid}

(Grafana Datenimport wird über die [InfluxDB Integration von Home Assistant](https://www.home-assistant.io/integrations/influxdb/) realisiert)

## Steckdose ins WLAN ohne App

Der WiFi Switch **benötigt dabei keine App**! Zwar steht in der Anleitung
dass man eine installieren soll, aber die Steckdose strahlt bei der
Ersteinrichtung ein WLAN Netzwerk aus und erlaubt die Ersteinrichtung
unter `http://192.168.254.1`.

![myStrom Wifi Setup]({{'assets/mystrom-wifi.jpg' | relative_url}}){:.img-fluid}

## Home Assistant

Da die Steckdose ohne Authentifizierung funktioniert (ein hoch auf mein isoliertes
Smarthome/Gadget VLAN) und [von Home Assistant unterstützt wird][hass], ist
die Einrichtung hier auch einfach:

[hass]: https://www.home-assistant.io/integrations/mystrom/

```yml
# configuration.yaml
switch:
  - platform: mystrom
    name: Waschmachine
    host: myStrom-Switch-E424242

sensor:
  - platform: template
    sensors:
      washingmachine_watts:
        friendly_name: "Waschmachine Verbrauch"
        unit_of_measurement: "W"
        value_template: "{{'{{'}} state_attr('switch.washingmachine', 'current_power_w') }}"
```

```yml
# automation
# Washingmachine notification trigger
- alias: Washingmachine is finished
  trigger:
    - platform: numeric_state
      entity_id: sensor.washingmachine_watts
      below: 10
      for: '00:15:00'
  action:
    - service: notify.matrix_notify
      data: { message: "Waschmaschine ist fertig. 🚀" }
```

```yml
# automation
# Turn off power when washing machine turned off after idle peroid
- alias: Turn off Washingmachine
  trigger:
    - platform: numeric_state
      entity_id: sensor.washingmachine_watts
      below: 1
      for: '00:15:00'
  action:
    - service: switch.turn_off
      entity_id: switch.washingmachine
```

Home Assistant unterstützt neben Matrix auch noch viele andere
[Notification Provider](https://www.home-assistant.io/integrations/#notifications).
