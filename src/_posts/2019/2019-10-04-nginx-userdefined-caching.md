---
author: christian
title: NGINX Benutzerdefiniertes Caching
lang: de
ref: nginx-dyn-cache
tags: [http, nginx]
---

NGINX ermöglicht es einem Upstream Server über [magische Headers][magic-headers]
Einstellungen zu ändern. Zum Beispiel mit `X-Accel-Expires`, wie lange das Response
vom Reverse Proxy geacached werden soll.

Sehr praktisch wenn man ein extrem komplexes Caching Setup umsetzen will.
Man kann durch diesen Header im Code des Upstream Server steuern, wie lange gecached wird.

[magic-headers]: https://www.nginx.com/resources/wiki/start/topics/examples/x-accel/

In dem man zwei NGINX Reverse Proxy `server {}` Blöcke hintereinander schaltet, kann man
auch dem User erlauben eine Cache Zeit festzulegen:

```
proxy_cache_path /tmp/cache levels=1:2 keys_zone=examplecache:10m max_size=50g inactive=86400 use_temp_path=on;

server {
    listen 127.0.0.1:7443 ssl;
    ssl_certificate /etc/ssl/http/bundle_example.com.cert;
    ssl_certificate_key /etc/ssl/http/example.com.key;

    location / {
        # set the cache time for examplecache by request header
        add_header X-Accel-Expires $http_x_cache_ttl;
        add_header Cache-Control max-age=$http_x_cache_ttl;

        # ignore cache headers from upstream
        proxy_ignore_headers X-Accel-Redirect X-Accel-Expires X-Accel-Limit-Rate X-Accel-Buffering X-Accel-Charset Expires Cache-Control Vary;
        proxy_hide_header Cache-Control;
        proxy_hide_header Via;

        # remove our custom headers for upstream
        proxy_set_header X-Cache-TTL "";

        # relay the request to the real upstream
        proxy_pass https://api.webservice.serverless.industries;
    }
}

server {
    server_name example.com;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /etc/ssl/http/bundle_example.com.cert;
    ssl_certificate_key /etc/ssl/http/example.com.key;

    location / {
        proxy_cache examplecache;
        proxy_cache_methods GET HEAD POST;
        proxy_cache_lock on;
        proxy_read_timeout 60s;
        proxy_http_version 1.1;
        proxy_redirect off;
        proxy_cache_key $scheme$proxy_host$request_uri$is_args$args;

        # prepare caching headers
        proxy_hide_header X-Cache;
        proxy_set_header X-Cache-TTL $http_x_cache_ttl;
        add_header X-Cache $upstream_cache_status;
        add_header X-Cache-TTL $http_x_cache_ttl;

        # Forward to intermediate nginx server block
        proxy_set_header Host api.webservice.serverless.industries;
        proxy_pass https://127.0.0.1:7443;
    }
}
```

Ablauf:

- Eingehendes Request auf example.com mit `X-Cache-TTL` header
- Weiterleitung an 127.0.0.1:7443
- Weiterleitung an api.webservice.serverless.industries
- Antwort mit Response und `X-Accel-Expires` header mit dem Inhalt von `X-Cache-TTL`
- example.com nutzt die Zeitangabe in Sekunde aus `X-Accel-Expires` zur Anlage des Cache
- Antwort an den Benutzer

## Hohes Missbrauchspotential

Man sollte sich ganz genau überlegen, ob man dieses Setup ungeschützt
im Internet betreibt. Macht ein User einen Fehler oder setzt gar falsche Werte aus Absicht,
kann dies zum Beispiel die Festplatte vollaufen lassen oder den Upstream unbrauchbar machen,
da Daten (zum Beispiel) für 100 Jahre gecached werden.

In meinem Fall läuft das Setup in einem geschützten Netzwerk und
im `proxy_cache_key` ist eine User ID enthalten. Das sorgt dafür, dass der
Cache immer nur für einen Benutzer gilt und somit nicht alle anderen Benutzer
beeinträchtigt.
