#!/bin/sh
set -eu
umask 0022
printf -- "1: HOME CONFIG\n"
home-config
printf -- "2: CONFIGUS CONFIG\n"
configus-config
printf -- "3: EXTENSION CONFIG\n"
extension-config
printf -- "4: TIMEZONE CONFIG\n"
timezone-config
printf -- "5: XDEBUG CONFIG\n"
xdebug-config
printf -- "0: DONE\n"
