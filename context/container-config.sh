#!/bin/sh
set -eu
umask 0022
home-config
configus-config
extension-config
timezone-config
xdebug-config
