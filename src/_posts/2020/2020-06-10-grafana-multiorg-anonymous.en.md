---
author: christian
title: Grafana Guest Access with multiple Organizations
lang: en
ref: grafana-multi-org-anon
tags: ['nginx', 'grafana', 'linux', 'server']
---

[Grafana][about] supports guest access to dashboards only for one
single organization, which needs to be configured in the server
configuration.

But with a reverse proxy hack it is still possible for more than
one origanization. The [Proxy Authentication][proxy] module
allows a reverse proxy to send a header to the grafana backend,
which is used for the login process.

[about]: https://grafana.com/grafana/
[proxy]: https://grafana.com/docs/grafana/latest/auth/auth-proxy/

Grafana configuration:

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

By sending the header `X-WEBAUTH-USER` (which contains a
valid account name) to the grafana backend, the specified
user will be automatically authenticated.

The dark magic is done in the reverse proxy. To allow both,
anonymous access and autenticated users, we use two domains.

NGINX configuration:

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

When `https://anonmetrics.example.com/grafana/` is opened, the `map {}`
block will set the `$grafana_user` to `anon`. `$grafana_user` will used
in the `X-WEBAUTH-USER` header afterwards.

When `https://metrics.example.com/grafana/` is opened, the
`$grafana_user` variable and `X-WEBAUTH-USER` header are set to empty.
Grafana will now not perform a automatic login. But the user can
input their login credentials.

Now we can use the Grafana Permissions to grant Access so single
dashboards or entire organizations.

![Grafana Permissions]({{'/assets/grafana-anon.png' | relative_url}}){:.img-fluid}

Have fun!
