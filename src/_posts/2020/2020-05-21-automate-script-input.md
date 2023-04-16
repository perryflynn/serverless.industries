---
author: christian
title: "Shell Scripts: Benutzereingaben automatisieren"
locale: de
ref: expect-automate-script-input
tags: ['linux', 'shell', 'bash', 'ansible', 'infrastructure code']
---

Mit dem Tool `expect` können Tastatur Eingaben in einem Script oder
Programm automatisiert werden.

```sh
#!/usr/bin/expect
set timeout 600
spawn /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
expect "* email * \\\[ENTER\\\]: "
send "mail@example.com\n"
expect eof
```

Ausführen wie ein "normales" Shell Script:

```sh
chmod a+x expect-script
./expect-script
```

`expect` startet das eigentliche Programm, wartet auf die Ausgabe von
`Enter your email and press [ENTER]:` und gibt anschließend die Email
Adresse ein.

## Mit Ansible

```yml
- name: Execute lets encrypt bootstrap script
  shell: |
    set timeout 600
    spawn /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
    expect "* email * \\\[ENTER\\\]: "
    send "mail@example.com\n"
    expect eof
  args:
    executable: /usr/bin/expect
  environment:
    DEBIAN_FRONTEND: noninteractive
```
