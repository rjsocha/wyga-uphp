#!/bin/sh
set -eu
umask 0022
home-config
extension-config
configus-config
profile-config
timezone-config
xdebug-config
