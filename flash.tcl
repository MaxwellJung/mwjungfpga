# Usage: run "vivado -mode batch -source flash.tcl" in terminal.

# Open the hardware manager and connect to the local server
open_hw_manager
connect_hw_server -url localhost:3121

# Find and open the hardware target (the programming cable)
current_hw_target [get_hw_targets *]
open_hw_target

# Select the first FPGA device on the chain
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]

# Set the bitstream file (update this path)
set_property PROGRAM.FILE "bazel-bin/design/rvfpganexys/vivado_rvfpganexys.bit" [lindex [get_hw_devices] 0]

# Program the device
puts "Programming FPGA..."
program_hw_devices [lindex [get_hw_devices] 0]

# Clean up
close_hw_manager
puts "Done."
