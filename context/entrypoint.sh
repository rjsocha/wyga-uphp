#!/bin/sh
set -eu
if [ -n "${1-}" ]; then
  if [ "${1::1}" = "@" ]; then
    cmd="${1:1}"
    shift
    exec "${cmd}" "${@}"
  fi
fi
container-config
# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi
exec "$@"
