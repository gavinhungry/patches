#!/bin/bash

ARCH_DIR=$1
PKGSRC_DIR=$2

inform 'Executing conv_to_ewm_prop.py'
${PKGSRC_DIR}/resources/conv_to_ewm_prop.py ./rdp.png ${PKGSRC_DIR}/resources/RDP_Icon.h
