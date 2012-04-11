#!/bin/bash

COLOR_PATCH=$(cat ${1}/pacman-color_no_ignorepkg_warn.patch |\
              grep '^+++' | sed -e 's/^+++\s*\(.*\.patch\).*$/\1/')
PKGBUILD="$(dirname ${COLOR_PATCH})/PKGBUILD"

if [ ! -e ${COLOR_PATCH} ]; then
  echo "${COLOR_PATCH} not found" > /dev/stderr
  exit 1
elif [ ! -e ${PKGBUILD} ]; then
  echo "${PKGBUILD} not found" > /dev/stderr
  exit 1
fi

OLD_HASH=($(md5sum ${COLOR_PATCH}))

for P in ${1}/*.patch; do
  patch -p0 < $P;
done

NEW_HASH=($(md5sum ${COLOR_PATCH}))

sed -i "s/${OLD_HASH}/${NEW_HASH}/" ${PKGBUILD}
[ $? -eq 0 ] && echo "$PKGBUILD updated"
