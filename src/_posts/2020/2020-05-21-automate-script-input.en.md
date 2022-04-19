---
author: christian
title: "Shell Scripts: Automate User Input"
locale: en
ref: expect-automate-script-input
tags: ['linux', 'shell', 'bash', 'ansible']
---

The tool `expect` makes it possible to automate keyboard
inputs in shell scripts and programs.

```sh
#!/usr/bin/expect
set timeout 600
spawn /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
expect "* email * \\\[ENTER\\\]: "
send "mail@example.com\n"
expect eof
```

Execute just like a "normal" shell script:

```sh
chmod a+x expect-script
./expect-script
```

`expect` starts the actual program, waits for the input of
`Enter your email and press [ENTER]:` and types in the email address
afterwards.

## As Ansible task

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
