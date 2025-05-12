#!/bin/sh
set -eu
if [ "${PROFILES-}" = "ON" ]; then
  umask 0022
  template-engine fpm/pool /config/php/fpm/pool
  template-engine php/ini "${PHP_INI_DIR}/runtime.ini"
fi
