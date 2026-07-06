"""Public Starlark entrypoints for mwjungfpga Bazel rules."""

load("//rules/verilator:verilator_sim.bzl", _verilator_sim_test = "verilator_sim_test")
load("//rules/vivado:program_device.bzl", _vivado_program_device = "vivado_program_device")

verilator_sim_test = _verilator_sim_test
vivado_program_device = _vivado_program_device
