#!/bin/sh
set -eu
INI="${PHP_INI_DIR}/extension.ini"
PRESENT="/config/php/extension/present"
ENABLE="/config/php/extension/enable"

[ -w "${PHP_INI_DIR}" ] || exit 0
[ -d "${PRESENT}" ] || exit 0

umask 0022

EXTENSION_LIST=""
EXTENSION_APPEND=""
EXTENSION_REMOVE=""

if [ -d "${ENABLE}" ]; then
  for config in $(find "${ENABLE}" -maxdepth 1 -type f); do
    while read extension
    do
      [ -n "${extension}" ] || continue
      echo -n "${extension}" | grep -vq "^#" || continue
      if echo -n "${extension}" | grep -q -E "^\+"; then
        extension="$(echo -n "${extension}" | cut -c2-)"
        EXTENSION_APPEND="${EXTENSION_APPEND}:${extension}:"
      elif echo -n "${extension}" | grep -q -E "^\-"; then
        extension="$(echo -n "${extension}" | cut -c2-)"
        EXTENSION_REMOVE="${EXTENSION_REMOVE}:${extension}:"
      else
        EXTENSION_LIST="${EXTENSION_LIST}:${extension}:"
      fi
     done < "${config}"
  done
fi

if [ -n "${EXTENSIONS-}" ]; then
  for extension in ${EXTENSIONS//,/ }; do
    if echo -n "${extension}" | grep -q -E "^\+"; then
      continue
    elif echo -n "${extension}" | grep -q -E "^\-"; then
      continue
    else
      EXTENSION_LIST=""
      EXTENSION_REMOVE=""
      EXTENSION_APPEND=""
    fi
  done
  for extension in ${EXTENSIONS//,/ }; do
    if echo -n "${extension}" | grep -q -E "^\+"; then
      extension="$(echo -n "${extension}" | cut -c2-)"
      EXTENSION_APPEND="${EXTENSION_APPEND}:${extension}:"
    elif echo -n "${extension}" | grep -q -E "^\-"; then
      extension="$(echo -n "${extension}" | cut -c2-)"
      EXTENSION_REMOVE="${EXTENSION_REMOVE}:${extension}:"
    else
      EXTENSION_LIST="${EXTENSION_LIST}:${extension}:"
    fi
  done
fi

EXTENSION_FINAL=""
for extension in ${EXTENSION_LIST//:/ }; do
  if echo -n "${EXTENSION_REMOVE}" | grep -q -F ":${extension}:"; then
    continue
  fi
  if echo -n "${EXTENSION_FINAL}" | grep -q -F ":${extension}:"; then
    continue
  fi
  EXTENSION_FINAL="${EXTENSION_FINAL}:${extension}:"
done
for extension in ${EXTENSION_APPEND//:/ }; do
  if echo -n "${EXTENSION_REMOVE}" | grep -q -F ":${extension}:"; then
    continue
  fi
  if echo -n "${EXTENSION_FINAL}" | grep -q -F ":${extension}:"; then
    continue
  fi
  EXTENSION_FINAL="${EXTENSION_FINAL}:${extension}:"
done

EXT="$(.md php/extension-dir)"
for extension in ${EXTENSION_FINAL//:/ }; do
  [ -f "${PRESENT}/${extension}" ] || continue
  unset SO
  unset ZEND
  source "${PRESENT}/${extension}"
  ext_enable=1
  for so in ${SO//,/ }; do
    [ -f "${EXT}/${so}" ] || ext_enable=0
  done
  [ ${ext_enable} -eq 1 ] || continue
  for so in ${SO//,/ }; do
    if [ "${ZEND-}" = "TRUE" ]; then
      printf -- "zend_extension=%s\n" "${so}"
    else
      printf -- "extension=%s\n" "${so}"
    fi
  done
done | sort | uniq >"${INI}"
unset SO
unset ZEND
