---
author: christian
title: LG Smart TV mit Home Assistant automatisieren
locale: de
tags: [ smart home, ikea tradfri, home assistant ]
---

Mein 10 Jahre alter Samsung TV ist leider vor ein paar Wochen gestorben. Da Reparatur Versuche 
nicht erfolgreich waren, musste ein neuer her.

Der "LG OLED55B29LA TV 139 cm (55 Zoll) OLED" läuft mit WebOS, und kann über
die [WebOS Integration][hasswebos] von Home Assistant gesteuert werden.

[hasswebos]: https://www.home-assistant.io/integrations/webostv/
[hasswol]: https://www.home-assistant.io/integrations/wake_on_lan/
[opndocs]: https://docs.opnsense.org/intro.html
[ikeaplug]: https://www.ikea.com/de/de/p/tradfri-steckdose-funkgesteuert-smart-00377314/

## LG TV in Home Assistant einbinden

Die Integration kann ganz normal über die Einstellungen in der Home Assistant Oberfläche
hinzugefügt werden. Der Port `3000/tcp` vom LG TV muss von Home Assistant aus erreichbar
sein.

## Anschalten

Sofern via Ethernet an das Netzwerk angeschlossen, kann der LG TV via Wake on LAN angeschaltet
werden. Wenn sich Home Assistant und LG TV im selben Netzwerk befinden, kann die 
[Wake On LAN][hasswol] Integration benutzt werden.

Bei mir ist dies nicht der Fall, daher nutze ich die REST API des Wake On LAN Plugins
meines [OPNSense][opndocs] Routers.

Dafür muss ein neuer Benutzer in OPNSense angelegt werden, welcher ausschließlich die Berechtigung
hat, auf das WoL Modul zuzugreifen. Anschließend muss ein neues API Key Schlüsselpaar in den Benutzer
Einstellungen angelegt werden, welches als `username` und `password` dient.

```yml
# hass configuration.yaml
rest_command:
  wake_device:
    verify_ssl: false
    url: 'https://192.168.1.1/api/wol/wol/set'
    method: POST
    # interface MUST be the real name like 'opt5' and NOT the alias!
    payload: '{"wake":{"interface": "{{'{{'}}interface}}","mac": "{{'{{'}}mac}}"}}'
    content_type:  'application/json'
    username: XXXXXXXXXXXXX
    password: YYYYYYYYYYYYY
```

Nun können wir damit folgende Scripts erstellen:

```yml
# hass scripts.yaml
tv_turn_on_when_off:
  alias: Turn the SmartTV on when it's off
  sequence:
    - if:
        - condition: state
          entity_id: media_player.lg_smart_tv
          state: 'off'
      then:
        - service: rest_command.wake_device
          data:
            interface: opt2
            mac: 'ac:5a:f0:42:42:42'
        - wait_template: "{{'{{'}} is_state('media_player.lg_smart_tv', 'on') }}"
          timeout: 120
          continue_on_timeout: false
        - delay: 5

tv_firetv:
  alias: SmartTV + FireTV anschalten
  sequence:
    - service: script.tv_turn_on_when_off
    - service: media_player.select_source
      data:
        source: Amazon OTT
      target:
        entity_id: media_player.lg_smart_tv
```

Wird der Home Assistant Service `script.tv_firetv` ausgeführt, wird

- der LG TV über Wake on LAN angeschaltet
- darauf gewartet, dass der LG TV in Home Assistant als angeschaltet erkannt wird
- auf den HDMI Kanal vom Amazon FireTV umgeschaltet

(sofern dies nicht schon der Fall ist)

## Ausschalten

Mit dem Service `script.tv_off` wird der LG TV ausgeschaltet:

```yml
# hass scripts.yaml
tv_off:
  alias: SmartTV ausschalten
  sequence:
    - service: media_player.turn_off
      entity_id: media_player.lg_smart_tv
```

## Andere Geräte schalten

Da Home Assistant nun den Status des LG TV als Sensor verfügbar hat, können weitere
Komponenten geschaltet werden. 

In meinem Fall eine [IKEA Tradfri Steckdose][ikeaplug] via Zigbee, welche die 
Steckerleiste mit FireTV, Nintendo Switch und anderen Dingen schaltet.

```yml
# hass automations.yaml
- alias: Turn on other devices when SmartTV is turned on
  mode: single
  max_exceeded: silent
  trigger:
    - platform: state
      entity_id: media_player.lg_smart_tv
      to: 'on'
      for: 1
  action:
    - service: homeassistant.turn_on
      entity_id: switch.tv_switch

- alias: Turn off other devices when SmartTV is turned off
  mode: single
  max_exceeded: silent
  trigger:
    - platform: state
      entity_id: media_player.lg_smart_tv
      to: 'off'
      for: 60
  action:
    - service: homeassistant.turn_off
      entity_id: switch.tv_switch
```

Die Ausschalt-Automation hat absichtlich eine Verzögerung von 60 Sekunden eingebaut, sodass
versehendliches Ausschalten nicht dazu führt, dass alle Geräte abgewürgt werden.

## OLED + Standby

Der Fernsehr selbst bleibt im Standby. OLED TVs führen im Standby einen so genannten "Kompensationsprozess"
aus, welcher dafür sorgt, dass Pixel nicht einbrennen. Nimmt man dem Fernsehr den Standby Strom,
kann dies [die Lebenserwartung drastisch reduzieren](https://winfuture.de/news,122453.html).
