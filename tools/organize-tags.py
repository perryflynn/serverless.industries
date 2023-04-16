#!/usr/bin/python3

import yaml
from pprint import pprint

config = []
with open("src/_data/tags.yml") as filehandle:
    config = yaml.load(filehandle, Loader=yaml.FullLoader)

newlist = sorted(config, key=lambda k: k['name'])

with open("src/_data/tags.yml", "w") as filehandle:
    yaml.dump(newlist, filehandle)
