#!/bin/bash

cd "$(dirname "$0")"

if [ ! -f src/serve-cert.pem ] || [ ! -f src/serve-key.pem ]; then
    rm -f src/serve-cert.pem
    rm -f src/serve-key.pem
    openssl req -new -x509 -days 365 -nodes -out src/serve-cert.pem -keyout src/serve-key.pem
fi

args=()
if [ -n "$JEKYLL_HOSTNAME" ]; then
    host+=( "--host $JEKYLL_HOSTNAME" --ssl-cert serve-cert.pem --ssl-key serve-key.pem )
fi

mkdir -p vendor/ruby
bundle config set --local path vendor/ruby
bundle install
bundle exec jekyll serve --lsi --unpublished "${args[@]}" -s ./src -d ./_site --config ./src/_config.yml,./src/_config_staging.yml,./src/_config_ci_demo.yml

exit 0
