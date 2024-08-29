#!/bin/sh
set -eu
MOLD="/dev/shm/extension.ini"
INI="${PHP_INI_DIR}/extension.ini"
PRESENT="/config/php/extension/present"
ENABLE="/config/php/extension/enable"

[ -w "${PHP_INI_DIR}" ] || exit 0
[ -d "${ENABLE}" ] || exit 0
[ -d "${PRESENT}" ] || exit 0
# extension.ini exists - this is not critical - container restart
[ ! -f "${INI}" ] || exit 0

umask 0022
:>"${MOLD}"

if [ -n "${ENABLE_EXTENSTION-}" ]; then
  for extension in ${ENABLE_EXTENSTION//,/ }
  do
    [ "${extension}" != "" ] || continue
    printf -- "%s" "${extension}" | grep -vq "^#" || continue
    if [ ! -f "${PRESENT}/${extension}" ]
    then
      printf -- "WARNING: extension '%s' not found ...\n" "${extension}"
      continue
    fi
    cat "${PRESENT}/${extension}" >>"${MOLD}"
  done
else
  for config in $(find "${ENABLE}" -maxdepth 1 -type f)
  do
    while read extension
    do
      [ "${extension}" != "" ] || continue
      printf -- "%s" "${extension}" | grep -vq "^#" || continue
      if [ ! -f "${PRESENT}/${extension}" ]
      then
        printf -- "WARNING: extension '%s' not found ...\n" "${extension}"
        continue
      fi
      cat "${PRESENT}/${extension}" >>"${MOLD}"
     done < "${config}"
  done
fi
sort "${MOLD}" | uniq > "${INI}"
rm "${MOLD}"
