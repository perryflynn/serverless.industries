---
author: christian
title: Smarte Türklingel selbst bauen
lang: de
ref: smart-doorbell
tags: [ electronics, 'smart home', 'home assistant', 'esphome' ]
image: /assets/smartbell-hass.png
---

Den Plan meine Türklingel in [Home Assistant][hass] einzubinden hatte ich schon
lange. 2018 fragte ich einen Arbeits&shy;kollegen der Elektrik gelernt hatte,
wie man das am besten macht.

Ein paar Tage später legte er mir einen Schaltplan auf den Tisch und versuchte mir zu
erklären, was zu tun ist. Ich hab es aber nicht verstanden, da ich keinerlei
Grundkenntnisse hatte.

Der Plan wanderte in mein Notizbuch und tauchte über die Jahre immer mal wieder auf.
Ich hatte dann auch mal ein paar Teile bestellt und rumprobiert, aber es hat
nie so richtig geklappt.

Wie man an den [Beiträgen der letzten Wochen]({{ '/tags.html#electronics' | relative_url }})
erkennen kann, habe ich mich jetzt durchgebissen und es tatsächlich hinbekommen.
Menschen mit Elektonrik Skills verdrehen jetzt bestimmt die Augen, aber
für mich ist das was großes. :-)

![Türklingel in Home Assistant]({{'assets/smartbell-hass-small.png' | relative_url}}){:.img-fluid}

[esphome]: https://esphome.io/
[hass]: https://www.home-assistant.io/
[rect]: {% post_url 2020/2020-12-27-ac-to-dc-rectifier %}
[opto]: https://www.elektronik-kompendium.de/sites/bau/0411091.htm
[mqtt]: https://mosquitto.org/
[notify]: https://www.home-assistant.io/integrations/#notifications
[pulldown]: https://de.wikipedia.org/wiki/Open_circuit#Pull-down

## Türklingel

Die verbaute Türklingel ist eine simple 12 Volt
Wechselstrom Schaltung. Wird der Taster gedrückt, drückt der Elektromagnet
in der Klingel den Schlägel an den Gong.

## Smarthome

Home Assistant habe ich wie gesagt schon lange im Einsatz, vor einigen Monaten neu dazu
gekommen ist [ESPHome][esphome], mit dem man extrem einfach ESP32 Boards ohne eine Zeile
Code zu schreiben benutzen kann um Sensoren oder Aktoren anzusteuern.

Das ESP32 Board wird mit 5 Volt Gleichstrom betrieben. Das 12V Wechselstrom&shy;signal muss also
[gleichgerichtet][rect] und sicher an den mit 5 Volt betriebenen ESP32 angeschlossen
werden.

## Schaltung

Die Schaltung besteht aus drei Komponenten.

Das Klingelsignal wird mit einer Diode und einem Kondensator [gleichgerichtet][rect]
und anschließend mit einem Widerstand so weit runter gedrückt, dass eine LED
angesteuert werden kann.

Statt einer einfachen LED kommt ein Optokoppler zum Einsatz. Ein Optokoppler
besteht aus einer LED und einen Fotosensor, und ermöglicht so das Schalten eines
Stromkreises von einem anderen.

Klingel und ESP32 sind also von einander getrennt, der ESP32 hat seine eigene
Stromquelle.

Die Ausgangspins von dem Optokoppler werden an den ESP32 angeschlossen. Für den ESP32
ist dies das gleiche, als wenn man einen einfachen Taster anschließt.

![Schaltung]({{'assets/smartbell-circuit.jpg' | relative_url}}){:.img-fluid}

## Teile

- 1x [1N4001 Gleichrichter Diode](https://www.reichelt.de/gleichrichterdiode-50-v-1-a-do-41-1n-4001-p1723.html)  
  Es hat keinen besonderen Grund genau diese Diode zu nutzen, ich hatte die halt noch.
  Die Diode sollte aber auf jeden Fall eine Gleichrichter&shy;diode sein!  
  &nbsp;
- 1x [Kondsensator 220µF 25VDC](https://www.reichelt.de/index.html?ACTION=446&LA=446&nbc=1&q=elko%20radial%20220%20%C2%B5f%2025%20v)  
  Man kann die Größe des Kondensators berechnen, ich habe aber einfach [auf dem Oszilloskop][rect] 
  geschaut, bei welcher Kapazität die Reaktionszeit am besten/schnellsten ist.  
  &nbsp;
- 1x [CNY17-2 Optokoppler](https://www.reichelt.de/optokoppler-cny-17-ii-p6676.html)  
  Das Optokoppler Modell hat mein Kollege vorgegeben. Es gibt sichlich auch andere Modelle,
  mit denen das genau so gut funktioniert.  
  &nbsp;
- 1x [820 Ohm Widerstand](https://www.reichelt.de/widerstand-kohleschicht-820-ohm-0207-250-mw-5--1-4w-820-p1474.html) (Bei einer 12V Klingel)  
  Die Größe des Widerstands ergibt sich aus dem Datenblatt des Optokopplers und kann
  mit der Formel für die Berechnung eines LED Vorwiderstands berechnet werden.  
  &nbsp;
- 1x [12k Ohm Widerstand](https://www.reichelt.de/widerstand-kohleschicht-12-kohm-0207-250-mw-5--1-4w-12k-p1348.html)  
  [Pull-Down][pulldown] Widerstand für das Eingangssignal am ESP32.

## ESPHome

Wie bereits erwähnt erspart ESPHome jegliches schreiben von Code. Welche Komponenten
es gibt und wie diese miteinander kommunizieren wird mit YAML definiert.

Die Kommunikation "nach außen" wird über MQTT realisiert, dafür betreibe ich einen
[Mosquitto Broker][mqtt].

```yml
esphome:
  name: esp_floor
  platform: ESP32
  board: nodemcu-32s

wifi:
  ssid: "ExampleWifi"
  password: "password1"

binary_sensor:
  - platform: gpio
    pin:
      number: 26
      mode: INPUT_PULLDOWN
    name: "Door Bell"
    state_topic: smarthome/floor/door_bell
    filters:
      - delayed_off: 100ms
    on_press:
      then:
        - output.turn_on: led18
    on_release:
      then:
        - output.turn_off: led18

output:
  - platform: gpio
    id: led18
    pin:
      number: 18

mqtt:
  broker: 192.168.1.1
  username: esphome
  password: password1
  discovery: True
  discovery_retain: True
  topic_prefix: smarthome/floor
```

Der `binary_sensor` ist der Pin an dem der Optokoppler hängt. Ob die Klingel gerade gedrückt
wurde oder nicht, wird über den MQTT Topic `smarthome/floor/door_bell` veröffentlicht.

Gleichzeitig unterstützt ESPHome aber auch eigene Automationen, so schaltet der Sensor
mit `on_press` und `on_release` eine LED (mit passenden Vorwiderstand) an Pin 18
entsprechend an oder aus.

## Home Assistant

Und nun zu dem besten Teil an ESPHome, der **Auto-Discovery von Sensoren**. Der MQTT Bus
ist auch in Home Assistant eingebunden und neue Sensoren werden **automatisch angelegt**.

Die dunkle Magie machen dabei die Einstellungen `discovery` und `discovery_retain`, welche
über automatisch generiete Topics in MQTT Metadaten zur Anlage der Sensoren an
Home Assistant senden.

Der Binary Sensor in Home Assistant kann nun zum Beispiel dafür benutzt werden,
[Benachrichtigungen zu verschicken][notify] oder eine Lampe blinken zu lassen.

![Türklingel in Home Assistant]({{'assets/smartbell-hass.png' | relative_url}}){:.img-fluid}

Vielen Dank an alle, die mit sehr sehr viel Geduld meine ganzen Fragen beantwortet haben. :-)
