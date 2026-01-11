---
author: christian
title: "File Access via NGINX"
locale: en
tags: [ linux, debian, server, http, projects, projects:linas ]
series:
  tag: series:linas
  index: 2
---

If the [File Permissions are set correctly][acls], it is quite simple to configure a NGINX webserver
to serve these share folders without granting "any-access" to the folder structure. It is even
possible to use an Unix account for password authentication over HTTPS.

[acls]: {% post_url 2026/2026-01-11-nas-posix-acls.en %}

Preparations:

- Install Debian Trixie
- Set hostname and fqdn
- Install `ssl-cert` package for a snakeoil certificate
- Setup [file shares][acls]
- Install `nginx-full` and `libnginx-mod-http-auth-pam`
- Grant access to a file share via group: `gpasswd -a www-data shrmedia`
- Grant access to shadow file: `gpasswd -a www-data shadow`
- Create a text file `/etc/nginx-share-shrmedia.group.allow` with the following content:

```txt
shrmedia
```

- Create a text file `/etc/pam.d/nginx-share-shrmedia` with the following content:

```txt
auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/nginx-share-shrmedia.group.allow
@include common-auth
```

**Important:** Both files must be readable by NGINX. I recommend to set owner 
to `root:root` and permissions to `u=rw,go=r`.

Now the NGINX config. The following config publishes the share `/mnt/raid/media` as `/media`
authenticated with PAM. Every Unix account with memership in group `shrmedia` can access the folder.

Also, depending on the `Accept:` request header, the server will respond with a classic autoindex,
JSON oder XML. So programmical access to the folder structure is also possible. Without any
additional software! 🚀

Have fun!

```txt
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /dev/null;
    error_log /var/log/nginx/error.log;
    gzip on;

    ssl_protocols TLSv1.3;
    ssl_ecdh_curve X25519:prime256v1:secp384r1;
    ssl_prefer_server_ciphers off;

    map $http_accept $autoindexformat {
        default @html;
        ~text/html @html;
        ~application/json @json;
        ~application/xml @xml;
    }

    server {
        listen 80;
        listen [::]:80;
        server_name _;
        return 302 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        http2 on;

        ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
        ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

        server_name _;

        root /mnt/raid;
        index index.html;
        charset UTF-8;

        # main page
        location / {
            root /var/www/html;
        }

        # fancyindex assets
        location /_index {
            alias /var/www/fancyindex;
        }

        # ping-pong endpoint
        location /ping {
            return 200 "pong";
            add_header Content-Type text/plain;
        }

        location /media {
            alias /mnt/raid/media;
            try_files $uri $autoindexformat;
            auth_pam "Accessing share";
            auth_pam_service_name "nginx-share-shrmedia";
        }

        # return directory content fancy
        location @html {
            autoindex on;
            autoindex_format html;
        }

        # return directory content as json
        location @json {
            autoindex on;
            autoindex_format json;
        }

        # return directory content as xml
        location @xml {
            autoindex on;
            autoindex_format xml;
        }
    }
}
```

If there are issues with the file permissions or with the PAM authentication, check the
logs via `journalctl -xn 200` and also restart NGINX with `systemctl restart nginx`.

Unfortunately PAM is not very verbose when it comes to configuration issues. It took me
quite some time to figure out that one issue was, that NGINX was unable to read the PAM config
files.
