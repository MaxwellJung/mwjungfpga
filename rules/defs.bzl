"""Public Starlark entrypoints for mwjungfpga Bazel rules."""

load("//rules/verilator:verilator_sim.bzl", _verilator_sim = "verilator_sim")
load("//rules/vivado:program_device.bzl", _vivado_program_device = "vivado_program_device")

verilator_sim = _verilator_sim
vivado_program_device = _vivado_program_device
