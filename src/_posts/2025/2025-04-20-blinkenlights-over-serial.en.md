---
author: christian
title: Force Devices to use Pi-hole
locale: en
tags: [ eh22, electronics, arduino, hardware, python ]
image: /assets/serial-blinkenlights.gif
---

After attending the workshop [LED Strips Everywhere for Everyone](https://cfp.eh22.easterhegg.eu/eh22/talk/LBAYEL/)
by [Mitch](https://mastodon.social/@maltman23), I looked for a project for the Arduino and 
LED Strip. Introducing Blinkenlights over Serial.

![Serial Blinkenlights]({{'assets/serial-blinkenlights.gif' | relative_url}}){:.img-fluid}

## The Protocol

Just ASCII text, each command terminated by `CRLF` (`\r\n`).

The parameters separated by space.

```txt
PIXEL_START PIXEL_END RED GREEN BLUE COMMIT
```

Turn all LEDs to red:

```txt
0 29 255 0 0 1
```

Turn LEDs 1-3 off and LEDs 4-6 to green:

```txt
0 2 0 0 0 0
3 5 0 255 0 1
```

Mind the last parameter, the commit byte is only set to `1` on the last command. Which triggers
an LED strip update only on the second command.

## The Arduino Sketch

The program uses the NeoPixel library from Adafruit. Every time when a serial command is received
it queues the changes to the LED strip. If the `commit` flag is set to `1`, the changes will be
applied to the LED strip.

```c
#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
  #include <avr/power.h>
#endif

//#define DEBUG 1

// initialize neopixel lib
#define PIN A5
#define NUMLEDS 30
Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUMLEDS, PIN, NEO_GRB + NEO_KHZ800);

// max length of one serial command including NULL byte at the end
#define SERIAL_BUFFERLEN 22

// vars for parsing the incoming serial commands
char readString[SERIAL_BUFFERLEN];

struct LedCommand {
  int pixelStart;
  int pixelEnd;
  int red;
  int green;
  int blue;
  bool commit;
};

struct LedCommand ledInfo;

// initialize the components
void setup() {
  // init serial connection
  Serial.begin(115200);
  Serial.setTimeout(20); 

  // This is for Trinket 5V 16MHz, you can remove these three lines if you are not using a Trinket
  #if defined (__AVR_ATtiny85__)
    if (F_CPU == 16000000) clock_prescale_set(clock_div_1);
  #endif
  // End of trinket special code

  // init LED strip
  strip.begin();
  strip.show();
  strip.setBrightness(1);
  strip.show();
}

// event loop
void loop() {
  // read, parse and validate incoming serial commands
  while (readSerialCommand() && parseLedCommand())
  {
    if (ledInfo.pixelStart >= 0)
    {
      // set requested color for the requested pixel range
      for (int i = ledInfo.pixelStart; i <= ledInfo.pixelEnd; i++)
      {
        strip.setPixelColor(i, strip.Color(ledInfo.red, ledInfo.green, ledInfo.blue));
      }

      // send response
      char buffer[64];
      sprintf(buffer, "Pixel update %d-%d: r=%d,g=%d,b=%d,commit=%d", ledInfo.pixelStart, ledInfo.pixelEnd, ledInfo.red, ledInfo.green, ledInfo.blue, ledInfo.commit);
      Serial.println(buffer);
    }

    // update LED strip if requested
    if (ledInfo.commit)
    {
      strip.show();
      ledInfo.commit = false;
    }
  }
}

// read a single serial command into buffer
bool readSerialCommand()
{
  int ctr = 0;
  bool error = false;

  while (Serial.available()) 
  {
    delay(2);  //delay to allow byte to arrive in input buffer
    char c = Serial.read();

    if (c == '\n' || c == '\r')
    {
      break;
    }
    else if (ctr < SERIAL_BUFFERLEN -1)
    {
      readString[ctr] = c;
      ctr++;
    }
    else
    {
      error = true;
      break;
    }
  }

  readString[ctr] = '\0';

  #ifdef DEBUG
  if (ctr > 0)
  {
    Serial.println(readString);
  }
  #endif

  if (error)
  {
    Serial.println("Syntax error while reading serial");
  }

  return ctr > 0 && !error;
}

// parse command from buffer into helper struct and validate values
bool parseLedCommand()
{
  char *search = " ";

  char *pixelStart;
  char *pixelEnd;
  char *red;
  char *green;
  char *blue;
  char *commit;

  pixelStart = strtok(readString, search);
  pixelEnd = strtok(NULL, search);
  red = strtok(NULL, search);
  green = strtok(NULL, search);
  blue = strtok(NULL, search);
  commit = strtok(NULL, search);

  ledInfo.pixelStart = 1 > strlen(pixelStart) ? -1 : atoi(pixelStart);
  ledInfo.pixelEnd = 1 > strlen(pixelEnd) ? -1 : atoi(pixelEnd);
  ledInfo.red = 1 > strlen(red) ? -1 : atoi(red);
  ledInfo.green = 1 > strlen(green) ? -1 : atoi(green);
  ledInfo.blue = 1 > strlen(blue) ? -1 : atoi(blue);
  ledInfo.commit = commit != NULL && commit[0] == '1';

  bool b = (
    ledInfo.pixelStart >= 0 && ledInfo.pixelStart < NUMLEDS &&
    ledInfo.pixelEnd >= 0 && ledInfo.pixelEnd < NUMLEDS &&
    ledInfo.pixelStart <= ledInfo.pixelEnd &&
    ledInfo.red >= 0 && ledInfo.red <= 255 &&
    ledInfo.green >= 0 && ledInfo.green <= 255 &&
    ledInfo.blue >= 0 && ledInfo.blue <= 255
  );

  if (!b)
  {
    ledInfo.pixelStart = -1;
    ledInfo.pixelEnd = -1;
    Serial.println("Syntax error while parsing line");
  }

  return b;
}
```

After uploaded to the Arduino, the program can be tested via the Serial Monitor in the 
Arduino IDE. Make sure to set the correct baud rate.

*Note: I am a complete beginner in regards of C and Arduino, so if there is anything to improve, just
let me know. I am always happy to learn.*

## The Python Client

Okay, the code is running on the Arduino, now we need a Client to send commands with.
I used Python.

Probably the serial device (`/dev/ttyUSB0`) have to be adjusted.

```py
import serial
import time
from pprint import pprint

SOMECOLORS = [ '255 255 255', '0 255 0', '255 0 0', '0 0 255', '255 255 0', '0 255 255', '255 0 255' ]
PIXELS = list(range(0, 30))

cancel = False

def genroundround():
    pixelrange = PIXELS.copy()
    while not cancel:
        for color in SOMECOLORS:
            pixelrange.reverse()
            for idx in pixelrange:
                yield f"{idx} {idx} {color} 1"
            time.sleep(0.5)

def genfillloop():
    while not cancel:
        for color in SOMECOLORS:
            yield f"0 29 {color} 1"
            time.sleep(0.5)

def main():
    global cancel
    ser = serial.Serial('/dev/ttyUSB0', timeout=1, baudrate=115200)

    try:
        ser.readline()
        ser.readline()

        for line in genroundround():
            ser.write(bytes(f"{line}\r\n", 'utf-8'))
            time.sleep(0.001)
            print(ser.readline())
            time.sleep(0.001)

    except KeyboardInterrupt:
        cancel = True
    finally:
        ser.write(b'0 29 0 0 0 1')
        time.sleep(0.001)
        print(ser.readline())
        ser.close()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
```

The `genroundround` and `genroundround` generator functions are creating different animations,
just change the call in the `main` function.

Have fun and a great Easterhegg 22!
