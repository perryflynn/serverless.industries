---
author: christian
title: Query String Parameter in den Header mit NGINX
lang: de
ref: nginx-header-querystring
tags: [http, nginx]
---

Um Requests an eine externe API besser zu cachen
nutzen wir einen NGINX Reverse Proxy und haben Query
Parameter wie den API Key in den Header verschoben.

Egal wie viele unterschiedliche API Keys in Benutzung
sind, das Request wird nur einmalig ausgeführt und dann
gecached.

Der API Key wird vor der Ausführung des `proxy_pass`
an den Query String gehängt.

```
location / {
    # Add the APP ID and the APP key to the query string
    set $originalargs $args;
    set $args $args&app_id=$http_x_app_id&app_key=$http_x_app_key;

    # check for credencials in query string and abort
    if ( $originalargs ~ "(.*)(app_id|app_key)=([^&]*)(.*)" ) {
        # using the (debian/ubuntu) package libnginx-mod-http-headers-more-filter
        more_set_headers "Content-Type: application/json; charset=UTF-8";
        return 400 "{\"error\": \"app_id or app_key was specified as GET argument. These have to be specified with the X-App-ID and X-App-Key header instead.\"}";
    }

    proxy_cache awesomeapicache;

    # append the querystring without credencials to the cache key
    proxy_cache_key $request_uri$is_args$originalargs;

    # Remove custom headers for upstream API
    proxy_set_header X-App-ID "";
    proxy_set_header X-App-Key "";

    # Hide User-Agent for Upstream API
    proxy_set_header User-Agent "curl/7.47.0";

    # Forwarding of request
    proxy_pass http://awesomeapi.example.com;
}
```
