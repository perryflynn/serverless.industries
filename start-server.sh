#!/bin/bash

cd "$(dirname "$0")"

#podman pull reg.git.brickburg.de/bbcontainers/hyde:current

podman run -it --rm \
    --name hyde-blog --hostname hyde-blog \
    --user root \
    -v "$(pwd):/src:z" \
    -w /src \
    -p 127.0.0.1:4000:4000 \
    reg.git.brickburg.de/bbcontainers/hyde:current \
    /src/docker-entrypoint.sh
