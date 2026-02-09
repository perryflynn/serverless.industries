#!/bin/bash

set -e
set -u

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TZ=Europe/Berlin
export BUNDLE_PATH__SYSTEM=true

mkdir -p vendor/ruby
sudo gem install bundler
bundle config set --local path vendor/ruby
bundle install

bundle exec jekyll serve --host=0.0.0.0 --lsi --unpublished \
    -s ./src -d ./_site \
    --config ./src/_config.yml,./src/_config_staging.yml,./src/_config_ci_demo.yml
