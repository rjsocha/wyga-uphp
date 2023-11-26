#!/bin/sh
set -eu
[ ! -f "${PHP_INI_DIR}/timezone.ini" ] || exit
if [ -n "${TZ:-}" ]
then
  umask 0022
  echo "date.timezone=${TZ}" > "${PHP_INI_DIR}/timezone.ini"
fi
