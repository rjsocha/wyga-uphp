#!/bin/sh
set -eu
if [ -n "${CONFIGUS:-}" ]
then
  export CONFIGUS_ENDPOINT="${CONFIGUS_ENDPOINT:-configus}"
  printf -- "UPHP RUNTIME: 1.0.0 (%s/%s) CONFIGUS: %s\n" "$(id -u)" "$(id -g)" "${CONFIGUS}" >&2 || true
  umask 0022
  exec config-service "${CONFIGUS}"
fi
