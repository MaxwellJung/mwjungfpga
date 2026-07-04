load("//rules/vivado:program_device.bzl", _vivado_program_device = "vivado_program_device")

# Forward the rule to the public interface
vivado_program_device = _vivado_program_device
