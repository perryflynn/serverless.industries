---
author: christian
title: Shelly CoIoT + UDP Proxy mit NGINX
locale: de
tags: [ linux, nginx, network, docker, home assistant, shelly ]
---

[Mein Smarthome]({% post_url 2022/2022-09-11-my-smarthome-setup %}) besteht Docker Containers mit einem NGINX
als Frontend, welche die einzelnen Dienste von außen erreichbar macht.

Die neuste Errungenschaft ist ein [Shelly 1PM][shelly1pm], ein smartes WLAN Relais, welches
auch den Stromverbrauch messen kann. 

[shelly1pm]: https://shelly.cloud/products/shelly-1pm-smart-home-automation-relay/
[coiot]: https://www.home-assistant.io/integrations/shelly/#shelly-device-configuration-generation-1

Die Kommunikation zwischen Home Assistant und Shelly [findet dabei via CoIoT statt][coiot] statt,
einem bidirektionalem UDP Protokoll.

Home Assistant stellt diese Schnittstelle unter dem Port `5683/udp` bereit.

Damit die Status Nachrichten von Shelly richtig erkannt werden, muss im NGINX die
Direktive `proxy_bind` gesetzt werden, welche es erlaubt die Quell IP Adresse
der UDP Pakete zu überschreiben. 

So denkt Home Assistant, dass die Pakete vom Shelly kommen, und nicht im NGINX.

```conf
stream {
    resolver 127.0.0.11;
    server {
        listen 5683 udp;
        # override source IP
        proxy_bind $remote_addr transparent;
        set $proxy_destination "homeassistant:5683";
        proxy_pass $proxy_destination;
    }
}
```

Bei UDP Verbindungen ist so etwas super einfach, bei TCP Paketen hingehen
nicht zu empfehlen. Da kann es so weit kommen, dass man an Routing Tabellen
rumschrauben muss.

War in diesem Fall zum Glück nicht notwendig. 🙂
