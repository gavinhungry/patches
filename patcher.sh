#!/bin/bash

for patchfile in ${1}/*.patch; do
  patch -p0 < $patchfile;
done
