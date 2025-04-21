---
author: christian
title: Reverse Engineer Java Native Interfaces (JNI)
locale: de
tags: [ reverse engineering, software development, java, linux, security ]
featured: true
---

Der Hersteller einer Appliance stellt für Aufgaben wie den RAID Rebuild Tools in Form von Update Paketen bereit,
welche verschlüsselt sind.

Das Unix Werkzeug `file` liefert direkt den Dateityp:

```txt
$ file update_tool-RAID_Init.update
update_tool-RAID_Init.update: POSIX tar archive (GNU)
```

In dem tar Archiv befindet sich eine install Datei:

```txt
$ file install.enc
install.enc: openssl enc'd data with salted password
```

Ok, verschlüsselt. 

Der Service welcher das Update durchführt, ist teilweise in Java und teilweise in C programmiert.
Der Java Service enthält neben vielen Open Source Komponenten auch ein `updater.jar` Package.
jar-Packages sind simple ZIP Dateien, die man einfach entpacken kann.

In dem Package enthalten ist eine Java Klasse mit dem Namen `PackageUtils.class`. Klingt so,
als ob das die Klasse sein könnte, welche sich um das Entpacken von Updates kümmert.

Da die Nutzung von Decompilern bei Software welche einem nicht gehört verboten ist, versuchen
wir es erst einmal mit dem Unix Tool `strings`.

```
	genAesKey
passwordForEncrypt
	updaterBinDir
...
encrypt the Key from OS
Lo0ksLikeAPassw0rdNumber0ne
encrypt the Key from OS failure
Unarchiving update package file with new key failed.
Try to unarchive update package file with old key.
An0therPassw0rdTwo
 encrypt the Key from OS failure.
...
openssl enc -d %s -k %s -in '%s' | tar xzf - -C '%s'
-aes-128-cbc
...
#com/example/updatemanager/UpdateJni
getUpdaterKey1
```

Nice, zwei Strings welche wie Passwörter aussehen und der OpenSSL Befehl mit dem die Entschlüsselung gemacht wird.
Leider sind die Passwörter nicht für das Update Paket: `bad decrypt`

Im genannten `updaterBinDir`, diese Variable findet sich auch im Shell Script welches den Update Service startet,
befindet sich ein Programm mit dem Namen `genAesKey`. Führt man dieses aus, erhält man folgende Meldung:

```
Usage: ./genAesKey key passphrase
```

Also sind die beiden Passwörter in `PackageUtils.class` eigentlich die Passphrases zur Entschlüsselung des
AES Keys, welcher wahrscheinlich am Ende das Update Package entschlüsseln kann.

Mit `UpdateJni` ist aber noch eine weitere Java Klasse genannt. Auch hier können wir uns mal die Strings
anschauen:

```txt
updaterGetCert
(I)Ljava/lang/String;
getUpdaterKey1
()Ljava/lang/String;
	versionupgrader
loadLibrary
updaterStart
updaterStop
```

Hier steckte ich dann erst Mal fest. Nach langer Sucherei fing ich dann an mit `find` und `grep -r`
das Dateisystem nach den Strings zu durchsuchen und voilà: `/home/updater/app/lib/libversionupgrader.so`

Auch hier wieder der `strings` output:

```txt
Java_com_example_updatemanager_UpdateJni_updaterStart
Java_com_example_updatemanager_UpdateJni_updaterGetCert
Java_com_example_updatemanager_UpdateJni_updaterStop
UPDATER_KEY1 0x01
UPDATER_PKGDECKEY 0x04
```

Ok, WTF, wieso sind Java Funktionen (?) in einer Linux Library referenziert? 

Ein bisschen gegoogle später die Lösung: Mit `System.loadLibrary("versionupgrader")`
können Funktionen in der Library `libversionupgrader.so` aus Java heraus aufgerufen werden!

Nach mehreren Tagen des Rumprobierens hier die richtige Implementierung:

```java
package com.example.updatemanager;

import java.util.List;

public class UpdateJni
{
    public static native boolean updaterStart();
    public static native boolean updaterStop();
    private static native String updaterGetCert(final int p0);

    static {
        System.loadLibrary("versionupgrader");
    }

    public static void main(String[] args) {
        updaterStart();
        System.out.println(updaterGetCert(4));
        updaterStop();
    }
}
```

Im `strings` Output bedeutet das `(I)`, dass die Funktion ein Argument vom Typ Integer erwartet.
Das `Ljava/lang/String`, dass die Funktion einen String zurück gibt.

Die Konstante im `strings` Output der Linux Library (`UPDATER_PKGDECKEY 0x04`) liefert den Integer,
welcher an die Funktion übergeben werden muss.

```txt
$ javac com/example/updatemanager/UpdateJni.java
$ java com/example/updatemanager/UpdateJni
DEC1F5A1E5EAAA7DD539BBCFCEB1BB18
```

Bäm! Es funktioniert!

```sh
$ ./genAesKey DEC1F5A1E5EAAA7DD539BBCFCEB1BB18 Lo0ksLikeAPassw0rdNumber0ne
5A81937CD1FBB6A32C2DB9BDB2AAE5CB

$ openssl enc -md md5 -d -aes-128-cbc -k 5A81937CD1FBB6A32C2DB9BDB2AAE5CB -in install.enc > install.unencrypted
$ file install.unencrypted
install.unencrypted: gzip compressed data, last modified: Wed Jun 11 00:54:04 2019, from Unix, original size modulo 2^32 163840
```

Bäm Nr. 2! Das Archiv lässt sich entschlüsseln.

## Fazit

Die Crypto in Linux Libraries auszulagern hat hier absolut nichts gebracht. Man konnte den Aufruf einfach
(mehrere Tage Arbeit) nachbauen und ausführen.

Wieder eine ganze Menge gelernt, Danke dafür an die Autoren. 👍
