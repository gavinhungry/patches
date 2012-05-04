#!/bin/bash

if [ -x ${1}/patch.sh ]; then
  ${1}/patch.sh ${1}
else
  for P in ${1}/*.patch; do
    patch -N -r - -p0 < $P;
  done
fi