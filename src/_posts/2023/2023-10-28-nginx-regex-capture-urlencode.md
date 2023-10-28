---
author: christian
title: "NGINX und automatisches URL encoding"
locale: de
tags: [ nginx, server ]
---

Bei dem Versuch einen WebDAV Server mit NGINX aufzusetzen, bin ich mit Anlauf 
in die Workaround-Hölle gesprungen. Eigentlich war der Gedanke "Joa, verzichten wir
Mal auf komplexe Webservices und machen es einfach". Nun. Hat gut funktioniert.

**tl;dr:** Die funktionierende Konfiguration mit Kommentaren:

```conf
# This NGINX runs behind a reverse proxy, so parse X-Forwarded-For headers
# Directives for setting real_ip/XFF IP address in log files
set_real_ip_from 172.16.0.0/12;
real_ip_header X-Forwarded-For;

server {
    listen 80;
    server_name _;
    root /var/www/public/;

    location / {
        # https://serverfault.com/a/1092384
        # https://www.dimoulis.net/posts/webdav-behind-reverse-proxy/
        # capturing group without name is urlencoded, named capturing group is not.
        # see https://trac.nginx.org/nginx/ticket/348
        set $destination $http_destination;
        if ($destination ~ ^https?://(?<myvar>(.+))$) {
            set $destination "http://$myvar";
            more_set_input_headers "Destination: $destination";
        }

        dav_methods PUT DELETE MKCOL COPY MOVE;
        dav_ext_methods PROPFIND OPTIONS;
        dav_access user:rw;

        client_max_body_size 0;
        create_full_put_path on;
        client_body_temp_path /tmp/;
        autoindex on;
    }
}
```

## Destination Header und Reverse Proxy

Beim Verschieben und Kopieren von Dateien sendet WebDAV einen `Destination: https://...`
Header mit dem Zielpfad. Der Header enthält eine `https://` URL, dadurch das der WebDAV Server
aber hinter einem Reverse Proxy steht, spricht dieser aber kein TLS. 

NGINX weist daher das Request ab:

```txt
[error] 6#6: *2 client sent invalid "Destination" header: "https://
```

Mit `more_set_input_headers` aus dem Debian Paket `libnginx-mod-http-headers-more-filter`
und ein wenig Regex Magie lässt sich dies aber umgehen.

Im eingehenden Header wird `https://` durch `http://` ersetzt, bevor das WebDAV Modul
mit der Verarbeitung beginnt.

## Automatisches URL encoding via Regex

Ein regulärer Ausdruck wie `$destination ~ ^https?://(.+)$` erzeugt die Match Group
Variable `$1`, welche die URL aus `$destination` ohne `http://` oder `https://` enthält.
Leider aber URL encoded. Sprich aus `/` wird `%2F`.

Dadurch werden dann auch die Dateien im WebDAV Ordner mit URL kodierten Dateinamen erstellt.

Das ist ein [10 Jahre alter, ungelöster Bug](https://trac.nginx.org/nginx/ticket/348) in NGINX.
Der Workaround ist die Nutzung von Named Match Groups.
In dem Code Block weiter oben wird daher die Match Group als `myvar` benannt.

Ergebnis ist eine `$myvar` Variable, welche nicht URL encoded ist.
