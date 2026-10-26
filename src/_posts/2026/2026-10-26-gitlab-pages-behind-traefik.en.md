---
author: christian
title: "GitLab Pages behind Traefik"
locale: en
tags: [ gitlab, web service ]
---

My GitLab server is running on a virtual machine behind a Traefik reverse proxy. This saves me
money, since I don't have to rent additional IP addresses, but it also means that GitLab pages
does not work properly. It requires it's own dedicated IP for custom domain hosting.

To make the handling of the routes a little bit more git-like, I created a repo, placed a
YAML file containing the Traefik routes for GitLab pages into it and used Traefiks [HTTP Provider][httpp]
to poll the YAML through a very simple python HTTP server from GitLabs package registry.

[httpp]: https://doc.traefik.io/traefik/reference/install-configuration/providers/others/http/

## Steps

Prepare:

- Create a repo and place the `traefik.yml` routes file (see below) into it
- Use GitLab CI, the JSON schema and the validation script to ensure proper syntax (see below)
- Configure branches and package registry settings properly to prevent unauthorized changes
- Let the pipeline run to create a generic package containing the YAML file

Setup webserver:

- Create a deploy token with `read_package_registry` permission
- Craft the GitLab API endpoint with the local VM IP (so that the endpoint works regardless of a functioning Traefik proxy).
  Example: `http://192.168.199.36:80/api/v4/projects/205/packages/generic/traefik/latest/traefik.yaml`
- Place webserver script on GitLab server host
- Create a `/etc/traefik-routes-api.conf` environment file on the GitLab server
    - `BB_ROUTES_URL`: The endpoint with the traefik.yml package file
    - `BB_DEPLOY_TOKEN`: The deploy token to access the package
    - `BB_PORT`: The port to be used by the service
- Create the systemd service unit (see below)
- Enable and start unit
- Verify if it works by using curl: `curl http://localhost:23765`

Enable the [HTTP Provider][httpp] integration in traefik configuration:

```yml
providers:
  http:
    endpoint: "http://192.168.199.36:23765"
```

Now the routes defined in the repository should appear in the Traefik dashboard. We can now use
regular merge requests to add new GitLab pages deployments. Traefik will take care of certificates etc.

I use this repo for both, the main routes to GitLab and also for GitLab pages. Of course it is
possible to split out the services and the main routes and only maintain the pages routes.

Have fun! 🚀

## The code

File `/traefik.yml` in the repo:

```yml
# yaml-language-server: $schema=checks/schema.json
http:

  services:

    gitlab-pages-service:
      loadBalancer:
        healthcheck:
          hostname: gitlab-pages.example.com
          interval: 10s
          path: /@status
          timeout: 3s
        passHostHeader: true
        servers:
          - url: 'http://192.168.199.37'

    gitlab-web-service:
      loadBalancer:
        healthcheck:
          interval: 10s
          path: /-/readiness
          timeout: 3s
        passHostHeader: true
        servers:
          - url: 'http://192.168.199.36'

  routers:

    gitlab-web-route:
      rule: Host(`git.example.com`) || Host(`reg.git.example.com`)
      service: gitlab-web-service

    glpage-default:
      rule: Host(`gitlab-pages.example.com`)
      service: gitlab-pages-service

    # more routes here
```

The pipeline:

```yaml
stages:
  - check
  - deploy

variables:
  packagename: traefik

check:
  stage: check
  tags: [ docker ]
  image: some/image:latest
  script:
    - |
      ./checks/validate.py --format yaml \
          --schemafile checks/schema.json \
          --file traefik.yaml

publish:
  stage: deploy
  tags: [ docker ]
  only: [ main ]
  image: some/image:latest
  script:
    - |
      echo "[*] Generate new routing file"
      echo "# Generated at $(date) from $CI_COMMIT_SHA" > out.yaml
      cat ./traefik.yaml >> out.yaml
    - |
      echo "[*] Figure out the package ID"
      packageid=$(curl --location --silent --fail \
          --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
          "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages?package_name=${packagename}" | \
              jq -r -M '.[0].id')

      if [ -n "$packageid" ]; then
          echo "[*] Checking for old files to cleanup"
          while read -r fileid; do

              echo "[*] Delete file ${fileid}"
              curl --location --silent --fail --request DELETE \
                --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
                --url "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/${packageid}/package_files/${fileid}"

          done <<< "$(curl --location --silent --fail --header "JOB-TOKEN: ${CI_JOB_TOKEN}" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/${packageid}/package_files" | jq '. | sort_by(.created_at) | .[] | .id' | head -n -2)"
      fi

      echo "[*] Upload new routing file"
      curl --location --silent --fail --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
           --upload-file ./out.yaml \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/traefik/latest/traefik.yaml"
```

Python Script to validate YAML against the Schema:

```py
#!/usr/bin/python3

import json
import yaml
import argparse
import sys
from jsonschema import Draft7Validator

def parse_args():
    """ Parse command line arguments """

    parser = argparse.ArgumentParser(
        description='Validate a JSON file against a schema file',
        formatter_class=argparse.RawDescriptionHelpFormatter
        )

    parser.add_argument('--file', type=str, required=True)
    parser.add_argument('--schemafile', type=str, required=True)
    parser.add_argument('--format', type=str, choices=['json', 'yaml'], default='json')

    return parser.parse_args()

def main():
    """ Main function """

    args = parse_args()

    schema = None
    with open(args.schemafile, 'r') as f:
        schema = json.load(f)

    validator = Draft7Validator(schema)

    content = None
    with open(args.file, 'r') as f:
        if args.format == 'json':
            content = json.load(f)
        elif args.format == 'yaml':
            content = yaml.safe_load(f)
        else:
            raise Exception('Unknown format for data file')

    haserrors = False
    for error in validator.iter_errors(content):
        haserrors = True
        path = " -> ".join(str(p) for p in error.absolute_path) or "root"
        print(f"[{path}]: {error.message}")

    if haserrors:
        sys.exit(1)

if __name__ == "__main__":
    main()
```

The schema file:

```json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "id": "https://example.com/traefik-routes.json",
    "title": "JSON schema for GitLab Traefik routes",

    "definitions": {
        "duration": {
            "type": "string",
            "pattern": "^[0-9]+s$"
        },
        "http-url": {
            "type": "string",
            "minLength": 8,
            "pattern": "^https?://",
        },
        "service-name": {
            "type": "string",
        },
        "service-hostname": {
            "type": "string",
            "minLength": 4,
        },
        "traefik-healthcheck": {
            "type": "object",
            "additionalProperties": false,
            "required": [ "interval", "path", "timeout" ],
            "properties": {
                "hostname": {
                    "$ref": "#/definitions/service-hostname"
                },
                "interval": {
                    "$ref": "#/definitions/duration"
                },
                "timeout": {
                    "$ref": "#/definitions/duration"
                },
                "path": {
                    "type": "string",
                    "minLength": 2,
                    "pattern": "^/"
                }
            }
        },
        "traefik-servers": {
            "type": "array",
            "minItems": 1,
            "items": {
                "type": "object",
                "additionalProperties": false,
                "required": [ "url" ],
                "properties": {
                    "url": {
                        "$ref": "#/definitions/http-url"
                    }
                }
            }
        },
        "traefik-loadbalancer": {
            "type": "object",
            "additionalProperties": false,
            "required": [ "healthcheck", "servers", "passHostHeader" ],
            "properties": {
                "healthcheck": {
                    "$ref": "#/definitions/traefik-healthcheck"
                },
                "servers": {
                    "$ref": "#/definitions/traefik-servers"
                },
                "passHostHeader": {
                    "type": "boolean"
                }
            }
        },
        "traefik-route": {
            "type": "object",
            "additionalProperties": false,
            "required": [ "rule", "service" ],
            "properties": {
                "rule": {
                    "type": "string",
                    "minLength": 9
                },
                "service": {
                    "$ref": "#/definitions/service-name"
                }
            }
        }
    },

    "type": "object",
    "additionalProperties": false,
    "required": [ "http" ],
    "properties": {
        "http": {
            "type": "object",
            "additionalProperties": false,
            "required": [ "services", "routers" ],
            "properties": {

                "services": {
                    "type": "object",
                    "additionalProperties": false,
                    "patternProperties": {
                        "^[a-z\\-]+$": {
                            "type": "object",
                            "required": [ "loadBalancer" ],
                            "additionalProperties": false,
                            "properties": {
                                "loadBalancer": {
                                    "$ref": "#/definitions/traefik-loadbalancer"
                                }
                            }
                        }
                    }
                },

                "routers": {
                    "type": "object",
                    "additionalProperties": false,
                    "patternProperties": {
                        "^[a-z\\-]+$": {
                            "$ref": "#/definitions/traefik-route"
                        }
                    }
                }

            }
        }
    }
}
```

The minimal Python webserver:

```py
#!/usr/bin/python3

import http.server
import requests
import argparse
import os

URL = os.environ.get('BB_ROUTES_URL')
TOKEN = os.environ.get('BB_DEPLOY_TOKEN')
PORT = int(os.environ.get('BB_PORT', '8000'))

class ResponseHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        text = fetch_url()

        response_bytes = text.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/yaml; charset=utf-8")
        self.send_header("Content-Length", str(len(response_bytes)))
        self.end_headers()
        self.wfile.write(response_bytes)

def parse_args():
    """ Parse command line arguments """
    parser = argparse.ArgumentParser(description='Dumb Web Server')
    parser.add_argument('--server', action='store_true', help='Run as webserver', default=False)
    return parser.parse_args()

def fetch_url():
    """ Fetch URL """
    headers = { 'DEPLOY-TOKEN': TOKEN }
    response = requests.get(URL, headers=headers)
    return response.text

def run(server_class=http.server.HTTPServer, handler_class=ResponseHandler):
    server_address = ('', PORT)
    httpd = server_class(server_address, handler_class)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.server_close()

def main():
    """ Main method """
    args = parse_args()
    if args.server:
        run()
    else:
        print(fetch_url())

if __name__ == "__main__":
    main()
```

Systemd unit file for the minimal webserver:

```ini
[Unit]
Description=Traefik Routes API

[Service]
Type=simple
User=nobody
Group=nogroup
EnvironmentFile=/etc/traefik-routes-api.conf
ExecStart=/usr/local/bin/bb-dumb-api-repeater.py --server
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
```
