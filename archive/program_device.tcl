# Usage: run "vivado -mode batch -source program_device.tcl" in terminal.
# see https://docs.amd.com/r/2024.2-English/ug835-vivado-tcl-commands/program_hw_devices

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set_property PROGRAM.FILE {bazel-bin/design/rvfpganexys/vivado_rvfpganexys.bit} [get_hw_devices xc7a100t_0]
current_hw_device [get_hw_devices xc7a100t_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7a100t_0] 0]
set_property PROBES.FILE {} [get_hw_devices xc7a100t_0]
set_property FULL_PROBES.FILE {} [get_hw_devices xc7a100t_0]
set_property PROGRAM.FILE {bazel-bin/design/rvfpganexys/vivado_rvfpganexys.bit} [get_hw_devices xc7a100t_0]
program_hw_devices [get_hw_devices xc7a100t_0]
refresh_hw_device [lindex [get_hw_devices xc7a100t_0] 0]
