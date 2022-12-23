---
author: christian
title: LEDs glühen obwohl der Strom ausgeschaltet ist
locale: de
tags: [ smart home, ikea tradfri, electronics ]
published: false
---

TODO: kaputte strominstallation maybe?

Manchmal ist es kein super komplizierter Microcontroller Wahnsinn. Nach der Inbetriebnahme einer Lichterkette
viel mir am nächsten Morgen auf, dass diese im ausgeschalteten Zustand leicht glüht.

Die Lichterkette hängt an einer [IKEA Tradfri Zigbee Steckdose][tradfri], welche "verkehrt herum" in der Steckdose
steckte.

[tradfri]: https://www.ikea.com/de/de/p/tradfri-steckdose-funkgesteuert-smart-00377314/

<div style="display: grid; grid-template-columns: auto auto; gap: 10px; justify-content: space-between; margin-bottom: 20px;">
    <img style="object-fit: cover; width: 100%; max-height: 100%;" src="{{'assets/tradfri-plug-ledchain-on.jpg' | relative_url}}">
    <img style="object-fit: cover; width: 100%; max-height: 100%;" src="{{'assets/tradfri-plug-ledchain-on-light.jpg' | relative_url}}">
</div>

Dreht man die Steckdose, funktioniert alles wie erwartet.

<div style="display: grid; grid-template-columns: auto auto; gap: 10px; justify-content: space-between; margin-bottom: 20px;">
    <img style="object-fit: cover; width: 100%; max-height: 100%;" src="{{'assets/tradfri-plug-ledchain-off.jpg' | relative_url}}">
    <img style="object-fit: cover; width: 100%; max-height: 100%;" src="{{'assets/tradfri-plug-ledchain-off-light.jpg' | relative_url}}">
</div>

Vermutlich lag es daran, dass die Schaltsteckdose den Neutralleiter der Steckdose ausgeschaltet hat,
statt des Außenleiters (auch L1/L2/L3 genannt).

In [diesem YouTube Video](https://www.youtube.com/watch?v=3Mc0CST507k) kann man sehen, dass das Relais in der
Steckdose nur eine der beiden Leitungen schaltet.

![Smarthome 2022]({{'assets/tradfri-plug-ledchain.jpg' | relative_url}}){:.img-fluid}
{: style="text-align: center;"}
