---
author: christian
title: HTTP Requests mit esphome.io
locale: de
tags: [ 'smart home', esphome, yaml ]
image: /assets/esphome-influx.jpg
ref: esphome-http-request-influxdb
---

[esphome.io][esphome], ein sehr komfortables Baukasten System für Sensoren,
sendet standardmäßig Sensordaten [via MQTT][hassmqtt] oder eigenem
Protokoll an [Home Assistant][hass]. Von dort werden die Messdaten weiter verarbeitet.

Es ist aber auch möglich [via HTTP Request][esphttp] Daten direkt an InfluxDB oder einen
**beliebigen anderen HTTP Service** zu schicken.

[hass]: https://www.home-assistant.io/
[hassmqtt]: https://www.home-assistant.io/docs/mqtt/discovery/
[esphome]: https://esphome.io/index.html
[esphttp]: https://esphome.io/components/http_request.html

## Bauteile

- ESP32 (zum Beispiel NodeMCU)
- Dallas DS18B20 Temperatur Sensor
- 47k Widerstand

## Hardware zusammen setzen

- Stiftleisten auf den ESP32 löten
- VCC (rot) Pin an `3.3V` auf ESP32
- Ground (schwarz) Pin an `GND` auf ESP32
- Data (gelb) Pin an `Pin 23` auf ESP32
- Widerstand (47k) zwischen `Pin 23` und `3.3V` verlöten

![ESP32]({{'assets/esphome-influx.jpg' | relative_url}}){:.img-fluid}

![ESP32 Resistor]({{'assets/esphome-influx-resistor.jpg' | relative_url}}){:.img-fluid}

## esphome.io Config

Der große Vorteil an esphome.io ist, dass man nicht wirklich programmieren muss. Es ist
ein Baukasten welcher über YAML Dateien konfiguriert wird. Das `esphome` Programm setzt dann später
den C Code automatisch zusammen, kompiliert und flasht die Firmware auf den ESP32.

Der Ablauf ist wie folgt:

- Mit WLAN verbinden
- Dallas Sensor Plattform aktivieren und nach Sensoren suchen
- Sensor mit der ID `0xCD012062C7DCFFFF` (Dein Sensor hat eine andere!) auslesen
- Median aus fünf Sensorwerten ermitteln
- Ergebnis via HTTP Request an InfluxDB senden

```yml
esphome:
  name: influxdb_test
  platform: ESP32
  board: nodemcu-32s

wifi:
  ssid: "WirelessInternetIsBlackMagic"
  password: "password1"

ota:
  password: "password1"

logger:

# Enable http request module
http_request:
  useragent: esphome/influxsensors
  timeout: 10s

# Enable dallas sensor module on PIN 23
dallas:
  - pin: 23
    update_interval: 60s

# The sensor itself
sensor:

  - platform: dallas
    # flash the config fist without the sensor block 
    # and pick the dallas address from the log
    address: 0xCD012062C7DCFFFF
    resolution: 12
    id: mysensor
    filters:
      # generate the median from 5 values to improve the quality
      # the sensor will transmit a value to influxdb each 5 minutes
      - median:
          window_size: 5
          send_every: 5
          send_first_at: 5
    on_value:
      then:

        # send the data
        - http_request.post:
            url: https://metrics.example.com/write?db=sensordata
            # esphome is not able to verify a certificate
            verify_ssl: false
            headers:
              # influxdb 1.x uses basic authorization
              # In a Linux shell:
              # echo -n "username:password" | base64
              Authorization: 'Basic YWxpY2U6cGFzc3dvcmQ='
            # a few lines of C code to generate the influxdb request data
            # https://docs.influxdata.com/influxdb/v1.8/guides/write_data/#write-data-using-the-influxdb-api
            body: !lambda |-
              char buf[64];
              sprintf(buf, "%0.1f", id(mysensor).state);
              return ((std::string) "temperature,group=outdoor,locationkey=example-sensor,stage=test,platform=esphome,sensor=dallas value="+buf).c_str();
```

## esphome.io Software

Im [esphome.io Getting Started Guide] ist beschrieben wie esphome funktioniert und was man
installieren muss. Ich empfehle das Ganze über einen Raspberry Pi zu machen, wenn man keinen
Linux PC zuhause hat.

Unter Windows funktioniert das zwar auch, ist aber etwas fummelig.

**Docker braucht man nicht!** Es reicht ein PC mit installiertem Python,
wo man das `esphome` Paket via `pip3 install esphome` installieren kann.

[getting]: https://esphome.io/guides/getting_started_command_line.html

## Sensor ID ermitteln & flashen

Jeder Dallas Sensor hat eine eindeutige ID. Um diese zu ermitteln muss man
das YAML File einmal ohne den `sensor:` Block auf den ESP32 flashen.

```sh
esphome esp-einwettertest.yaml run --upload-port /dev/ttyUSB0
```

Die Sensor ID wird dann im Log auftauchen:

```txt
[23:41:09][D][dallas.sensor:079]:   Found sensors:
[23:41:09][D][dallas.sensor:082]:     0xCD012062C7DCFFFF
```

Anschließend mit der eingesetzten Sensor ID ein weiteres Mal flashen:

```txt
[23:42:05][D][dallas.sensor:153]: 'mysensor': Got Temperature=27.1°C
[23:43:05][D][dallas.sensor:153]: 'mysensor': Got Temperature=27.1°C
[23:44:05][D][dallas.sensor:153]: 'mysensor': Got Temperature=27.0°C
[23:45:05][D][dallas.sensor:153]: 'mysensor': Got Temperature=26.9°C
[23:45:05][D][sensor:099]: 'mysensor': Sending state 27.06250 °C with 1 decimals of accuracy
[23:45:06][D][http_request:074]: HTTP Request completed; URL: https://metrics.example.com/write?db=sensordata; Code: 204
```

## Bonus: Over-the-air updates

Ist esphome einmal auf dem ESP32 geflasht, kann man Updates über WLAN verteilen.

Wenn der WLAN Router den ESP32 korrekt mit seinem Namen auflöst, reicht ein
einfaches `esphome esp-einwettertest.yaml run` und das esphome Tool wird
versuchen das Firmware Image via WLAN zu flashen:

```txt
INFO Resolving IP address of influxdb_test
INFO  -> 192.168.42.191
INFO Uploading influxdb_test/.pioenvs/influxdb_test/firmware.bin (984784 bytes)
Uploading: [============================================================] 100% Done...

INFO Waiting for result...
INFO OTA successful
INFO Successfully uploaded program.
INFO Starting log output from /dev/ttyUSB0 with baud rate 115200
```
