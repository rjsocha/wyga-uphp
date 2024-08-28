#!/bin/sh
set -eu
#This breaks restarts / docker engine upgrades
#find /config -user $(id -u) -exec chmod a-w {} \;
