#!/bin/sh
set -eu
MOLD="/dev/shm/extension.ini"
INI="${PHP_INI_DIR}/extension.ini"
PRESENT="/config/php/extension/present"
ENABLE="/config/php/extension/enable"

[ -w "${PHP_INI_DIR}" ] || exit 100
[ -d "${ENABLE}" ] || exit
[ -d "${PRESENT}" ] || exit
[ ! -f "${INI}" ] || exit

umask 0022
:>"${MOLD}"
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
sort "${MOLD}" | uniq > "${INI}"
rm "${MOLD}"
