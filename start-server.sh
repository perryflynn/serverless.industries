#!/bin/bash

cd "$(dirname "$0")"

jekyll serve -s ./src -d ./_site --config ./src/_config.yml,./src/_config_staging.yml

exit 0
