---
author: christian
title: Grafana Gastzugriff mit mehreren Organisationen
lang: de
ref: grafana-multi-org-anon
tags: ['nginx', 'grafana', 'linux', 'server']
---

[Grafana][about] unterstützt den Zugriff auf Dashboards ohne sich einloggen zu müssen
nur für eine Organisation, welche fest in der Server Konfiguration eingestellt
werden muss.

Über einen Trick kann man dennoch mehrere Organisationen
öffentlich verfügbar machen. Aktiviert man die
[Proxy Authentication][proxy], kann ein Reverse Proxy
einen Header an Grafana senden, welchen Grafana ohne
weitere Abfragen zur Anmeldung benutzt.

[about]: https://grafana.com/grafana/
[proxy]: https://grafana.com/docs/grafana/latest/auth/auth-proxy/

Grafana Konfiguration:

```ini
[auth.proxy]
enabled = true
header_name = X-WEBAUTH-USER
header_property = username
auto_sign_up = false
;ldap_sync_ttl = 60
whitelist = 127.0.0.1
headers =
enable_login_token = true
```

Sobald ein Reverse Proxy, welcher sich wegen der Whitelist auf dem
gleichen Server befinden muss, einen `X-WEBAUTH-USER` mitsendet,
nutzt Grafana den Wert des Headers um einen Benutzer zu finden,
der den entsprechenden Namen besitzt.

Der Account muss zuvor in Grafana angelegt worden sein.

Nun kommen wir zur Dark Magic. Um anonymen Zugriff und die
Anmeldung mit einem Account gleichzeitig zu ermöglichen, nutzen
wir einfach zwei Domains.

Hier eine Umsetzung mit NGINX:

```nginx
# set auto login username based on domain name
map $http_host $grafana_user {
    hostnames;
    # per default, don't use the header login at all
    default "";
    # if it is the guest domain, use 'anon' as account
    anonmetrics.example.com "anon";
}

# listen for HTTPS requests
# and do the proxing to the grafana backend
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name metrics.example.com anonmetrics.example.com;
    index index.html;
    root /var/www/officemetrics;

    ssl_certificate /root/.acme.sh/metrics.example.com/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/metrics.example.com/metrics.example.com.key;

    location /grafana/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_buffering                       off;
        proxy_set_header X-Real-IP            $remote_addr;
        proxy_set_header X-Forwarded-For      $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto    $scheme;

        # enforce the default domain for grafana
        # otherwise grafana would do a redirect to the
        # in grafana.ini configured domain
        proxy_set_header Host                 metrics.example.com;

        # send the with map {} defined user
        # by proxy header to grafana
        proxy_set_header X-WEBAUTH-USER       $grafana_user;
    }

}
```

Immer wenn `https://anonmetrics.example.com/grafana/` aufgerufen wird,
sorgt das `map {}` dafür, dass `$grafana_user` von einer leeren Zeichenkette
auf `anon` gesetzt wird. `$grafana_user` wird dann als `X-WEBAUTH-USER` an das
Grafana Backend gesendet.

Wird allerdings `https://metrics.example.com/grafana/` aufgerufen, ist
`$grafana_user` und somit auch `X-WEBAUTH-USER` leer und es wird kein automatischer
Login ausgeführt. Die Benutzer haben dann die Möglichkeit, sich ganz normal anzumelden.

In Grafana kann jetzt pro Dashboard oder Organisation festgelegt werden, ob der
`anon` Benutzer Zugriff erhalten soll:

![Grafana Permissions]({{'/assets/grafana-anon.png' | relative_url}}){:.img-fluid}

Have fun!
