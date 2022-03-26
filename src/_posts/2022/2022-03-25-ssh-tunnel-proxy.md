---
author: christian
title: 'SSH Tunnel, ProxyJumps und HTTPS auf dem gleichen Port'
lang: de
tags: [ linux, server, ssh, tunnel, network ]
---

Seit dem Windows einen SSH Client an Bord hat, ist es nie einfacher gewesen, Dienste verschlüsselt
durch das Internet zu tunneln, ohne gleich einen OpenVPN oder Wireguard Server aufzusetzen.

Im Optimalfall nutzt man für die Freigabe von Diensten ins Internet einen Proxy Server 
(`Internet -> Router -> Proxy -> Firewall -> Interner Server`). Via Firewall kann dann genau gesteuert
werden, welcher Dienst über den Proxy erreichbar gemacht wird. 

## SSH Server

Via `/etc/ssh/sshd_config` sollte der Login auf Schlüsselpaare und eine feste Gruppe von Accounts
eingeschränkt werden.

- `AuthenticationMethods publickey`: Login ausschließlich via Schlüsselpaar
- `PermitRootLogin no`: Kein Login mit dem root Account
- `AllowGroups sshlogin`: Genutzte Accounts müssen Mitglied der Gruppe `sshlogin` sein
- `AllowTcpForwarding yes`: Port Tunnel erlauben

## Beispiel 1: GitLab SSH via ProxyJump tunneln

Um den SSH Server eines intern betriebenen GitLab Servers durchzureichen, wird auf dem Proxy Server
`gateway.example.com` folgender Key in `/home/joshua/.ssh/authorized_keys`
hinterlegt:

```
restrict,port-forwarding,permitopen="git.example.com:22" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK/7fXttoLNXHz/tyyE22YwQGyRe8v6na0e/1e1XAHSM christian@example
```

Vor dem eigentlichen Key können Einstellungen gesetzt werden. Eine vollständige Liste gibt es mit
`man authorized_keys`.

- `restrict`: Alles verbieten
- `port-forwarding`: Port Tunnel wieder erlauben
- `permitopen="git.example.com:22"` Ausschließlich Tunnel zum GitLab SSH erlauben

Auf dem Client PC muss der Tunnel nun in `~/.ssh/config` konfiguriert werden. Das funktioniert unter Linux,
in der PowerShell und der Git Bash (git for Windows) identisch.

```
Host git.example.com
  Port 22
  User git
  IdentityFile ~/.ssh/gitlab
  PreferredAuthentications publickey
  ProxyJump joshua

Host joshua
  PreferredAuthentications publickey
  HostName gateway.example.com
  Port 22
  User joshua
  IdentityFile ~/.ssh/gitlab
  RequestTTY no
  RemoteCommand none
```

Nun sollte es egal sein, ob man sich im Heimnetzwerk befindet oder nicht. Der `ProxyJump` Parameter sorgt dafür,
dass erst eine SSH Verbindung zu `gateway.example.com` aufgebaut wird, und anschließend von da aus 
zu `git.example.com`.

```sh
git clone git@git.example.com:serverless.industries/blog.git
```

```
remote: Enumerating objects: 237, done.
remote: Counting objects: 100% (39/39), done.
remote: Compressing objects: 100% (38/38), done.
remote: Total 237 (delta 15), reused 5 (delta 1), pack-reused 198
Receiving objects: 100% (237/237), 81.19 KiB | 20.30 MiB/s, done.
Resolving deltas: 100% (140/140), done.
```

Die `ProxyJump` Anweisungen können beliebig verkettet werden.

## Beispiel 2: Zugriff auf Proxmox VM

Ein weiteres Beispiel ist der Zugriff auf eine Proxmox VM. Der Tunnel ermöglicht den Zugriff auf das Proxmox VE GUI,
den Desktop der VM via SPICE und den SSH Service der VM.

```
restrict,port-forwarding,permitopen="proxmox.example.com:8006",permitopen="proxmox.example.com:3128",permitopen="thevm.example.com:22" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK/7fXttoLNXHz/tyyE22YwQGyRe8v6na0e/1e1XAHSM christian@example
```

- `restrict`: Alles verbieten
- `port-forwarding`: Port Tunnel wieder erlauben
- `port-forwarding,permitopen="proxmox.example.com:8006"` Tunnel zum Interface von Proxmox VE erlauben
- `permitopen="proxmox.example.com:3128"` Tunnel zum SPICE Port von Proxmox erlauben
- `permitopen="thevm.example.com:22"` Tunnel zum SSH Port der VM erlauben

Die Client Konfiguration:

```
Host joshua-desktop
  PreferredAuthentications publickey
  HostName gateway.example.com
  Port 22
  User joshua
  IdentityFile ~/.ssh/gitlab
  RequestTTY no
  RemoteCommand none
  LocalForward localhost:8006 proxmox.example.com:8006
  LocalForward localhost:3128 proxmox.example.com:3128
  LocalForward localhost:8022 thevm.example.com:22
```

Nachdem der Tunnel mit `ssh -N joshua-desktop` aufgebaut wurde, kann via https://localhost:8006/ die Proxmox VE
GUI erreicht werden und der Desktop der VM via SPICE Client angezeigt werden. Über localhost:8022 können Dateien, 
zum Beispiel via WinSCP, mit der VM ausgetauscht werden.

## SSH auf dem HTTPS Port

In Netzwerken wo der SSH Port (22/tcp) geblockt wird, kann es helfen den SSH Server auf dem HTTPS 
Port (443/tcp) laufen zu lassen. Mit NGINX ist es sogar möglich, SSH und HTTPS 
**auf dem gleichen Port laufen zu lassen**.

Ein sehr simples und unvollständiges Beispiel:

```
http {
    server {
        server_name git.example.com;
        listen 127.0.0.1:8443 ssl http2;

        ssl_certificate      /etc/letsencrypt/example.com/fullchain.cer;
        ssl_certificate_key  /etc/letsencrypt/example.com/example.com.key;

        location / {
            proxy_pass https://git.example.com;
        }
    }
}

stream {
    map $ssl_preread_protocol $upstream {
        "" 127.0.0.1:22;
        "TLSv*" 127.0.0.1:8443;
        default 127.0.0.1:8443;
    }

    server {
        listen 443;
        proxy_pass $upstream;
        ssl_preread on;
    }
}
```

Mit `ssl_preread` prüft NGINX mit welchem Protokoll über 443/tcp gesprochen wird. Handelt es sich um eine
TLS Verbindung, ist es sehr wahrscheinlich HTTPS. Ansonsten wird von SSH ausgegangen.

```
[christian@tuttle ~]$ curl -v https://gateway.example.com:443/
< HTTP/2 403
< server: nginx
```

```
[christian@tuttle ~]$ ssh gateway.example.com -p 443
Permission denied (publickey).
```
