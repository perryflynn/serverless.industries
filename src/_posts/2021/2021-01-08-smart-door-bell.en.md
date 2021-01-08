---
author: christian
title: Smart door bell build
lang: en
ref: smart-doorbell
tags: [ electronics, 'smart home', 'home assistant', 'esphome' ]
image: /assets/smartbell-hass.png
---

The idea to include my door bell into [Home Assistant][hass] exists
since 2018. I've asked a colleague which is electican how to do this.

A few days later he gave me a schematic and tried to explain it to me,
but I didn't understand it.

As you can see on the [posts of the last weeks]({{ '/tags.html#electronics' | relative_url }}),
I finally fought through it and did it. :-)

![Door bell in Home Assistant]({{'assets/smartbell-hass-small.png' | relative_url}}){:.img-fluid}

[esphome]: https://esphome.io/
[hass]: https://www.home-assistant.io/
[rect]: {% post_url 2020/2020-12-27-ac-to-dc-rectifier %}
[opto]: https://www.elektronik-kompendium.de/sites/bau/0411091.htm
[mqtt]: https://mosquitto.org/
[notify]: https://www.home-assistant.io/integrations/#notifications
[pulldown]: https://en.wikipedia.org/wiki/Pull-up_resistor

## Door bell

The door bell is a very simple 12V AC circuit. If you press the button,
the electromagnet activates the doorbell chime.

## Smarthome

I use Home Assistant for a long time now. New in my setup is [ESPHome][esphome],
which allows it to confgure sensors on ESP32 boards whithout writing any code.

The challenge is now to connect the 12V AC door bell to one of the 3.3V DC
GPIO Pins of the ESP32.

## Circuit

The circuit consists of three components

The AC signal is [rectified][rect] (sorry, german post) with a diode and a capacitor,
afterwards a resistor reduces the current flow so that a LED can be connected.

Instead of a simple LED we use a optocoupler. A optocoupler consists of a LED
and a phototransistor. It allows to control one circuit from another one.

Door bell and ESP32 are isolated from each ohther, the ESP32 requires it's own
5V power source.

The output pins of the optocoupler are connected to the ESP32, it's just like a
simple switch.

![Circuit]({{'assets/smartbell-circuit.jpg' | relative_url}}){:.img-fluid}

## Parts

- 1x [1N4001 Rectifier Diode](https://www.reichelt.de/gleichrichterdiode-50-v-1-a-do-41-1n-4001-p1723.html)  
  I had this diode laying around, it should be possible to use any other rectifier diode.  
  &nbsp;
- 1x [Capacitor 220µF 25VDC](https://www.reichelt.de/index.html?ACTION=446&LA=446&nbc=1&q=elko%20radial%20220%20%C2%B5f%2025%20v)  
  Somehow it is possible to calculate the required capacitor (recommended), or you
  [take a look to the oscilloscope][rect] (sorry, german post) at which capacitance
  the reaction time is the best (lazy method).  
  &nbsp;
- 1x [CNY17-2 Optocoupler](https://www.reichelt.de/optokoppler-cny-17-ii-p6676.html)  
  The optocoupler model was choosen by my colleague. It should be possible to use any other
  model as well.  
  &nbsp;
- 1x [820 Ohm Resistor](https://www.reichelt.de/widerstand-kohleschicht-820-ohm-0207-250-mw-5--1-4w-820-p1474.html) (For a 12V door bell)  
  Take a look to the data sheet of the optocoupler and calculate the size of the
  resistor afterwards just as you do it with normal LEDs.  
  &nbsp;
- 1x [12k Ohm Resistor](https://www.reichelt.de/widerstand-kohleschicht-12-kohm-0207-250-mw-5--1-4w-12k-p1348.html)  
  [Pull-Down][pulldown] resistor for the input signal on the ESP32.

![Breadboard]({{'assets/smartbell-breadboard.jpg' | relative_url}}){:.img-fluid}

[Original Picture]({{'assets/smartbell-breadboard-large.jpg' | relative_url}})

## ESPHome

As I said earlier, [ESPHome][esphome] enables us to use sensors without writing any code.
Which component is used in which way is described with YAML.

ESPHome communicates with the "outside world" via MQTT. I use the [Mosquitto Broker][mqtt] for this.

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

The `binary_sensor` is the pin with the optocoupler connected. If the door bell is pressed
or not is published at the MQTT topic `smarthome/floor/door_bell`.

ESPHome allows it to create automations without Home Assistant as well. If the bell is pressed,
the `on_press` and `on_release` control a LED at pin 18.

## Home Assistant

And now the best part. The auto discovery of new components in Home Assistant.
The MQTT broker is connected to Home Assistant as well. ESPHome creates meta data
topics which enables Home Assistant to create the sensor on it's own.

The door bell binary sensor can now be used to [create notifications][notify], for example.

![Door Bell in Home Assistant]({{'assets/smartbell-hass.png' | relative_url}}){:.img-fluid}

Many thanks to everyone, for answering my questions with a lot of patience. :-)
