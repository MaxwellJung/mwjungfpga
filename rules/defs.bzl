"""Public Starlark entrypoints for mwjungfpga Bazel rules."""

load("//rules/verilator:verilator_sim.bzl", _verilator_sim_run = "verilator_sim_run")
load("//rules/vivado:program_device.bzl", _vivado_program_device = "vivado_program_device")

verilator_sim_run = _verilator_sim_run
vivado_program_device = _vivado_program_device
