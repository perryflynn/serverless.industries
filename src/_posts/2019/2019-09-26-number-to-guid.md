---
author: christian
title: Zahlen und .NET GUIDs kodieren
language: german
tags: ['CSharp', '.NET']
---

Diverse Webservices erwarten bei der Anlage eines Jobs als
Identifikationsmerkmal eine GUID (zum Beispiel `c4a583ad-9d39-4580-928b-c9a3dbcc6599`)
welche anschließend zum Abrufen vom Ergebnis des Jobs verwendet wird.

Verknüpft man diese Job GUID mit Daten in der eigenen Datenbank,
kann man sich eine separate Spalte oder gar ganze Tabelle sparen,
in dem man einfach den vorhandenen Primary Key als GUID kodiert.

In C# ist eine Zahl vom Typ `long` 8 Byte lang. In ein `Guid` Object passen
16 Byte. Man kann also ohne Probleme zwei `long`
Werte in eine GUID kodieren:

```cs
// Encode
long numberOne = long.MinValue;
long numberTwo = long.MaxValue;
byte[] guidBytes = new byte[16];

BitConverter.GetBytes(numberOne).CopyTo(guidBytes, 0);
BitConverter.GetBytes(numberTwo).CopyTo(guidBytes, 8);

var guid = new Guid(guidBytes);
```

Wieder dekodieren funktioniert ähnlich simpel:

```cs
// Decode
var guid = "...";
var reverseGuid = Guid.Parse(guid);
var reverseGuidBytes = reverseGuid.ToByteArray();

long numberOne = BitConverter.ToInt64(reverseGuidBytes, 0);
long numberTwo = BitConverter.ToInt64(reverseGuidBytes, 8);
```

Reichen zwei Zahlen nicht, sollte man
einen Blick auf die anderen Datentypen die C# beherrscht werfen.
Zum Beispiel gibt es da noch `short` und `ushort`.

Das Kodieren sollte aber so gebaut sein, dass Exceptions geworfen werden,
wenn sich eine Eingabe außerhalb des darstellbaren Bereichts befindet!
