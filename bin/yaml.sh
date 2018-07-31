#!/bin/sh

ruby -e "require 'yaml';puts YAML.load_file('$1')"