#!/bin/sh
set -eu
[ ! -f "${PHP_INI_DIR}/xdebug.ini" ] || exit
if [ -n "${XDEBUG:-}" ]
then
  xdebug_client="xdebug-client"
  xdebug_client_port="9003"
  xdebug_mode="develop,debug"
  xdebug_start="trigger"
  xdebug_output=""
  xdebug_log=""
  xdebug_log_level=0
  set -- ${XDEBUG}
  enabled=0
  while [[ $# -gt 0 ]]
  do
    case "${1}" in
      enable|enabled)
        enabled=1
        ;;
      client:*)
        xdebug_client="${1:7}"
        ;;
      port:*)
        xdebug_client_port="${1:5}"
        ;;
      mode:*)
        xdebug_mode="${1:5}"
        ;;
      start:*)
        xdebug_start="${1:6}"
        ;;
      start_with_request:*)
        xdebug_start="${1:19}"
        ;;
      output:*)
        xdebug_output="${1:7}"
        ;;
      output_dir:*)
        xdebug_output="${1:11}"
        ;;
      log_level:*)
        xdebug_log_level="${1:10}"
        ;;
      log:*)
        xdebug_log="${1:4}"
        ;;
    esac
    shift
  done
  if [ "${enabled}" == "0" ]
  then
    exit 0
  fi
  printf -- "XDEBUG:\n"
  printf -- "  CLIENT:    %s\n" "${xdebug_client}"
  printf -- "  PORT:      %s\n" "${xdebug_client_port}"
  printf -- "  MODE:      %s\n" "${xdebug_mode}"
  printf -- "  START:     %s\n" "${xdebug_start}"
  if [ -n "${xdebug_output:-}" ]
  then
    printf -- "  OUTPUT:    %s\n" "${xdebug_output}"
  fi
  if [ -n "${xdebug_log:-}" ]
  then
    printf -- "  LOG:       %s\n" "${xdebug_log}"
  fi
  printf -- "  LOG LEVEL: %s\n" "${xdebug_log_level}"
  xdebug_log_dir="$(dirname "${xdebug_log}")"
  umask 0022
  {
    printf -- "zend_extension=xdebug.so\n"
    printf -- "xdebug.discover_client_host=false\n"
    printf -- "xdebug.client_host=%s\n" "${xdebug_client}"
    printf -- "xdebug.client_port=%s\n" "${xdebug_client_port}"
    printf -- "xdebug.mode=%s\n" "${xdebug_mode}"
    printf -- "xdebug.start_with_request=%s\n" "${xdebug_start}"
    if [ -n "${xdebug_output:-}" ]
    then
      printf -- "xdebug.output_dir=%s\n" "${xdebug_output}"
    fi
    if [ -n "${xdebug_log:-}" ]
    then
      printf -- "xdebug.log=%s\n" "${xdebug_log}"
    fi
    printf -- "xdebug.log_level=%s\n" "${xdebug_log_level}"
  } > "${PHP_INI_DIR}/xdebug.ini"
fi
