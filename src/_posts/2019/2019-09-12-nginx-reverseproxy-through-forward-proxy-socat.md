---
author: christian
title: NGINX Reverse Proxy durch Forward Proxy mit socat
language: german
tags: [http, nginx]
---

Wie bereits in [einem früheren Beitrag][nginx-forwardproxy]
beschrieben, kann man mit `proxy_pass` Anfragen durch einen 
Forward Proxy leiten, in dem man als Proxy URL einfach den 
Forward Proxy verwendet und via `proxy_set_header` den `HOST` header
auf das eigentliche Ziel einstellt.

[nginx-forwardproxy]: {{ site.baseurl }}{% post_url 2019/2019-08-12-nginx-reverseproxy-through-forward-proxy %}

Im Testbetrieb hat sich nun aber heraus gestellt, dass dies nur mit HTTP
Traffic funktioniert. Soll eine TLS Verbindung aufgebaut werden, schlägt
dies fehl, da NGINX nicht in der Lage ist den PROXY CONNECT Prozess korrekt
auszuführen.

Zur Rettung kommt hier das Tool [socat](http://www.dest-unreach.org/socat/), 
welches ganz offiziell und ohne Tricks einen Proxy Connect beherrscht:

```sh
socat TCP4-LISTEN:8443,reuseaddr,fork,bind=127.0.0.1 \
    PROXY:corporate-proxy.serverless.industries:webservice.example.com:443,proxyport=8080
```

Das ganze als systemd unit:

```ini
[Unit]
Description=Socat API Proxy
After=network.target

[Service]
ExecStart=/usr/bin/socat TCP4-LISTEN:8443,reuseaddr,fork,bind=127.0.0.1 PROXY:corporate-proxy.serverless.industries:webservice.example.com:443,proxyport=8080
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
Alias=socat-api-proxy.service
```

In der NGINX Konfiguration wird dann der socat Port verwendet:

```
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name webserviceproxy.serverless.industries;

    ssl_certificate /etc/ssl/http/bundle_serverless.industries.cert;
    ssl_certificate_key /etc/ssl/http/serverless.industries.key;

    location / {
        proxy_set_header Host webservice.example.com;
        proxy_pass https://localhost:8443;
    }
}
```

Quelle: [https://stackoverflow.com/a/46824465](https://stackoverflow.com/a/46824465)
