#!/bin/sh
set -eu
find /config -user $(id -u) -exec chmod a-w {} \;
