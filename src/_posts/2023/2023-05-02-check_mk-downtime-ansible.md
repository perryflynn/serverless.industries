---
author: christian
title: "Downtime in Check_MK planen via Ansible"
locale: de
tags: [check_mk, ansible, monitoring, 'infrastructure code']
---

Führt man System Upgrades über Ansible aus, macht es vielleicht auch Sinn eine Entsprechende
Downtime im Monitoring (in meinem Fall Check_MK) zu planen, um Alarm Benachrichtigungen zu
vermeiden.

Check_MK hat dafür ab Version 2.0 [eine REST API][restapi] an Board. 

[restapi]: https://docs.checkmk.com/latest/en/rest_api.html

Zu jetzigen Zeitpunkt (Checkmk Raw Edition 2.1.0p26) ist das Swagger UI, welches Check_MK mitbringt,
**absoluter Mist**. Es erzeugt fehlerhafte Requests und hat mich über mehrere Stunden beschäftigt, 
bis ich darauf kam die "REST API documentation" mal mit der "REST API interactive GUI"
zu vergleichen.

In der "REST API documentation" ist es richtig beschrieben.

Raus gekommen ist nun folgendes Ansible Schnipsel, welches copy/paste so funktionsfährig sein 
sollte, oder auch als Role in den eigenen Code importiert werden kann.

```yml
- block:
    
    - name: Check if a host is ztacked in check_mk
      uri:
        method: GET
        url: "{{'{{'}}bbcheckmk_monitoring_url}}/api/v1.0/domain-types/host/collections/all?query=%7B%22op%22%3A+%22%3D%22%2C+%22left%22%3A+%22name%22%2C+%22right%22%3A+%22{{'{{'}}bbcheckmk_monitoring_host}}%22%7D"
        validate_certs: "{{'{{'}}bbcheckmk_monitoring_verifytls}}"
        headers:
          Authorization: "Bearer {{'{{'}}bbcheckmk_monitoring_username}} {{'{{'}}bbcheckmk_monitoring_secret}}"
          Accept: application/json
      register: hostresult

    - name: Fail when getting host status from Check_MK failed
      fail:
        msg: "API request to get host status from Check_MK failed"
      when: hostresult.status != 200

    - name: Plan downtime
      uri:
        method: POST
        url: "{{'{{'}}bbcheckmk_monitoring_url}}/api/v1.0/domain-types/downtime/collections/host"
        validate_certs: "{{'{{'}}bbcheckmk_monitoring_verifytls}}"
        headers:
          Authorization: "Bearer {{'{{'}}bbcheckmk_monitoring_username}} {{'{{'}}bbcheckmk_monitoring_secret}}"
          Accept: application/json
        body_format: json
        body:
          # start time = now-60 seconds
          start_time: "{{'{{'}}'%Y-%m-%dT%H:%M:%SZ' | strftime(ansible_facts.date_time.epoch | int - 60)}}"
          # end time = now + 30 minutes
          end_time: "{{'{{'}}'%Y-%m-%dT%H:%M:%SZ' | strftime(ansible_facts.date_time.epoch | int + 1800)}}"
          # raw edition only supports fixed
          recur: fixed
          # as soon as the host goes down in the time between start_time and end_time
          # it needs to come up again after 600 seconds aka 10 minutes
          duration: "{{'{{'}}10*60}}"
          # commend shown in check_mk ui
          comment: "System upgrade by Ansible at {{'{{'}}ansible_date_time.iso8601}}"
          # plan downtime for a whole host
          downtime_type: host
          host_name: "{{'{{'}}bbcheckmk_monitoring_host}}"
        status_code: [ 200, 204 ]
      register: downtimeresult
      when: hostresult.json.value|length > 0
  
  vars:
    bbcheckmk_monitoring_url: "https://checkmk.example.com/brickburg/check_mk"
    bbcheckmk_monitoring_verifytls: false
    bbcheckmk_monitoring_username: ansible
    bbcheckmk_monitoring_secret: password1
    bbcheckmk_monitoring_host: "{{'{{'}}ansible_host}}"
```
