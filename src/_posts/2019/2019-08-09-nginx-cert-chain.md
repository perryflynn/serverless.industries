---
author: christian
title: NGINX und Certificate Chains Theorie
lang: de
ref: nginx-cert-chain
tags: [linux, http, nginx, tls]
---

Jeder Serverdienst welcher TLS Verbindungen verwendet muss
neben dem eigentlichen Server Zertifikat auch alle Intermediate
Zertifikate[^2] an den Client schicken, da diese nicht auf dem Client
installiert sind.

Dort ist nur das Root Zertifikat[^1] der genutzten
Certificate Authority[^3] installiert, durch das die gesamte Kette an
Zertifikaten geprüft werden kann.

Beispiel einer Zertifikatskette:

```txt
DigiCert Baltimore Root     // <-- Root Cert (lokaler Store)
 '- Microsoft IT TLS CA 4   // <-- Intermediate Cert (vom Server gesendet)
     '- *.visualstudio.com  // <-- Server Zertifikat (vom Server gesendet)
```

Welche Zertifikate vom Server gesendet werden, kann man
übrigens mit openssl prüfen:

```sh
openssl s_client -showcerts -connect sample.visualstudio.com:443
```

Für jedes Zertifikat gibt es in der Ausgabe folgende Passage:

```txt
# s = server certificate; i = intermediate certificate
Certificate chain
 0 s:CN = visualstudio.com
   i:C = US, ST = Washington, L = Redmond, O = Microsoft Corporation, OU = Microsoft IT, CN = Microsoft IT TLS CA 4
```

## Zertifikat für NGINX

NGINX erwartet eine einfache Textdatei welche neben dem
Serverzertifikat alle Intermediate Zertifikate enthält.
Die einzelnen Zertifikatsblöcke werden einfach untereinander
in die Datei eingefügt.

```sh
cat sample.visualstudio.com.pem microsoft-intermediate.pem > sample.visualstudio.com-bundle.pem
```

Alternativ zum Linux Werkzeug `cat` können die Zertifikate natürlich
manuell im Texteditor zusammenkopiert werden.

Die Bundle Datei wird dann wie folgt in NGINX eingebunden:

```nginx
server {
    server_name sample.visualstudio.com;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /etc/ssl/sample.visualstudio.com-bundle.pem;
    ssl_certificate_key /etc/ssl/sample.visualstudio.com-key.pem;

    # [...]
}
```

Viele andere Server Dienste machen das übrigens genauso.

-----

[^1]: **Root Certificate:** Selbstsigniertes Zertifikat welches
      in den Browser importiert werden muss. Kann Zwischenzertifikate
      und Server-/Clientzertifikate ausstellen.

[^2]: **Intermediate Certificate:** Zwischenzertifikat welches von
      von einem anderen Zwischenzertifikat oder einem Root
      Zertifikat signiert wurde. Kann je nach Festlegung bei Ausstellung
      weitere Zwischenzertifikate und Server-/Clientzertifikate ausstellen.

[^3]: **Certificate Authority:** Eine Organisation welche für das signieren
      von Zertifikaten zuständig ist. Die Organisation übernimmt die Aufgabe
      der vertrauenwürdigen Stelle.
