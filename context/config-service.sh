#!/bin/sh
set -eu
TFILE=""

cleanup() {
  if [ -n "${TFILE}" ] && [ -f "${TFILE}" ]
  then
      rm "${TFILE}"
  fi
}

getConfig() {
local _count _info _src _dst _url
  _src="$1"
  _dst="$2"
  _url="${CONFIGUS_ENDPOINT}/cfg/${_src}"
  _count=0
  while true
  do
    if wget -q -T 5 -O "${_dst}" "${_url}" 2>/dev/null
    then
      printf -- '::CONFIGUS configuration acquired from "%s"\n' "${_url}"
      break
    fi
    _count=$(expr "${_count}" + 1)
    _info=$(expr "${_count}" % 20) || true
    if [ ${_info} -eq 0 ]
    then
      printf -- '::CONFIGUS still waiting for configuration from "%s"\n' "${_url}"
      _count=0
    fi
    sleep 0.5
  done
}

processMacro() {
local _inp _macro _eval
  _inp="$1"
  _eval="${_inp}"
  # ${XXX}
  if _macro=$(printf -- "${_inp}" | egrep -o '\$\{[^}]+\}' 2>/dev/null)
  then
    if ! _eval=$(eval printf -- "%s" "${_inp}" 2>/dev/null)
    then
      return 1
    fi
  fi
  printf -- "%s" "${_eval}"
}

getCommand() {
local _src _dst _base
  _src="$(processMacro "$1")" || _panic "unable to evalute macro for %s" "$1"
  _dst="$(processMacro "$2")" || _panic "unable to evalute macro for %s" "$2"
  _base="$(dirname "${_dst}")"
  if ! printf -- "${_src}" | fgrep -q "/"
  then
    _src="${SERVICE}/${_src}"
  fi
  if printf -- "${_dst}" | grep -q "^@"
  then
    _dst="$(printf -- "${_dst}" | cut -c 2-)"
    _dst="/config/${SERVICE}/${_dst}"
  fi

  mkdir -p "${_base}" 2>/dev/null || _panic "unable to create '%s' directory" "${_base}"
  getConfig "${_src}" "${_dst}" || _panic "unable to acquire '%s' configuration" "${_src}"
}

parseConfig() {
local _lno _source _line _command _opt1 _opt2
  _source="$1"
  _lno="$2"
  shift 2
  _command="$1"
  _command="$(printf -- "${_command}" | tr a-z A-Z)"
  case "${_command}" in
    :GET)
      shift
      if [ $# -ne 2 ]
      then
        _panic "wrong number of arguments for command :GET at line %s of %s" "${_lno}" "${_source}"
        return
      fi
      getCommand "$@"
      ;;
    *)
      _panic "unsupported config command %s at line %s of %s" "${_command}" "${_lno}" "${_source}"
  esac
}

processConfig() {
local _config _source _line _lineno
  _source="$1"
  _config="$2"
  _lineno=1
  while read _line
  do
    if printf -- "%s" "${_line}" | egrep -q '^#'
    then
      continue
    fi
    parseConfig "${_source}" "${_lineno}" ${_line} || true
    _lineno="$(expr ${_lineno} + 1)" || true
  done < "${_config}"
}

_panic() {
local _template
  _template="::CONFIGUS PANIC: ${1}"
  shift
  printf -- "${_template}\n" "$@"
  exit 100
}

_main() {
  if [ -n "${1:-}" ] && [ -n "${CONFIGUS_ENDPOINT:-}" ]
  then
    SERVICE="${1}"
    TFILE=$(mktemp -q -p /dev/shm -t cs.XXXXXX) || _panic "unable to start config-service (read-only filesystem?)"
    _service="${SERVICE}/config"
    if ! printf -- "%s" "${CONFIGUS_ENDPOINT}" | egrep -q "^http://"
    then
      CONFIGUS_ENDPOINT="http://${CONFIGUS_ENDPOINT}"
    fi
    getConfig "${_service}" "${TFILE}" || _panic "unable to acquire '%s' configuration" "${_service}/config"
    processConfig "${_service}" "${TFILE}"
  fi
}

trap cleanup EXIT
umask 0022
_main "$@"
