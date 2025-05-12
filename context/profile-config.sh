#!/bin/sh
set -eu
if [ "${PROFILES-}" = "ON" ] && [ -z "${CONFIGUS:-}" ]; then
  printf -- "UPHP RUNTIME: 1.0.0 (%s/%s) PROFILE\n" "$(id -u)" "$(id -g)" >&2 || true
  umask 0022
  template-engine fpm/pool /config/php/fpm/pool
  template-engine php/ini "${PHP_INI_DIR}/runtime.ini"
fi
