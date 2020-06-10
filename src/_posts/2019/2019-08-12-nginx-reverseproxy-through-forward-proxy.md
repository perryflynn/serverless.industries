---
author: christian
title: NGINX Reverse Proxy durch Forward Proxy
lang: de
ref: nginx-reverse-forward
tags: [http, nginx]
---

NGINX Webserver welche innerhalb eines Firmennetzwerks
laufen und mit einem Corporate Proxy vom Internet isoliert sind,
haben normalerweise keine direkte Verbindung zum Internet.

Möchte man nun einen Reverse Proxy erstellen, welcher Requests
auf externe APIs/Webservices cached, hilft folgender Hack:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name webserviceproxy.serverless.industries;

    ssl_certificate /etc/ssl/http/bundle_serverless.industries.cert;
    ssl_certificate_key /etc/ssl/http/serverless.industries.key;

    location / {
        proxy_set_header Host webservice.example.com;
        proxy_pass http://corporate-proxy.serverless.industries:8080;
    }
}
```

Die eigentliche Verbindung wird direkt zum Proxy (`proxy_pass`) aufgebaut.
Allerdings wird mit der `proxy_set_header` Direktive der `Host`
Header überschrieben, sodass der Proxy weiß, an welchen
Service die eingehende Anfrage weitergeleitet werden muss.

Disclaimer: Ich habe das bisher nur mit RESTful APIs genutzt.
Keine Ahnung was passiert, wenn man so eine komplette Website
verarbeiten will.
