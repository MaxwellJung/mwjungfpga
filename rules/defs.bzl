"""Public Starlark entrypoints for mwjungfpga Bazel rules."""

load("//rules/vivado:program_device.bzl", _vivado_program_device = "vivado_program_device")

vivado_program_device = _vivado_program_device
