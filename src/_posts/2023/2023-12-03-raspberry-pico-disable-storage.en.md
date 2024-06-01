---
author: christian
title: Disable Storage on a Raspberry Pi Pico
locale: en
tags: [ python, embedded, projects, projects:mouse-jiggler ]
---

When using a Raspberry Pi Pico as a USB Mouse or Keyboard, you may want to disable
CircuitPythons flash drive and the REPL serial console.

Just put the following into the `boot.py`:

```py
import storage
import usb_cdc
import usb_midi

storage.disable_usb_drive()
usb_cdc.disable()
usb_midi.disable()
```

The actual logic of your program should be put into the `code.py` and will be launched after
`boot.py` has completed.

It is also possible to add a physical button to skip disabling the Flash Drive.
The following example will **not disable** it, when the button is hold while resetting the Pico:

```py
import board
import storage
import usb_cdc
import usb_midi
from digitalio import DigitalInOut, Direction, Pull

btn = DigitalInOut(board.GP13)
btn.direction = Direction.INPUT
btn.pull = Pull.DOWN

if not btn.value:
    storage.disable_usb_drive()
    usb_cdc.disable()
    usb_midi.disable()
```

![Pico Jiggler]({{'assets/jiggler-pico2.png' | relative_url}}){:.img-fluid}
