#!/bin/bash

PDIR=$(pwd)/${1}
cd ..

if [ -x ${PDIR}/patch.sh ]; then
  ${PDIR}/patch.sh ${PDIR}
else
  for P in ${PDIR}/*.patch; do
    patch -N -r - -p0 < $P;
  done
fi
