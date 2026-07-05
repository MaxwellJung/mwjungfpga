#!/usr/bin/env bash

export HOME=/tmp
# Allow overriding the Vivado install location (e.g. in CI or other machines)
# via VIVADO_ROOT; default to the local workstation install.
source "${VIVADO_ROOT:-/tools/Xilinx/Vivado/2024.2}/settings64.sh"
# export XILINXD_LICENSE_FILE=2100@localhost
