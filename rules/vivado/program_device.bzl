load("@rules_vivado//vivado:providers.bzl", "VivadoRoutingCheckpointInfo")
load(
    "@rules_vivado//vivado/private:common.bzl",
    "TOOLCHAIN_TYPE",
    "get_vivado_toolchain",
    "run_tcl_template",
)


def create_executable_tcl_sh(*, ctx, template, substitutions, input_files):
    env = get_vivado_toolchain(ctx)
    vivado_tcl = ctx.actions.declare_file("{}_run_vivado.tcl".format(ctx.label.name))

    ctx.actions.expand_template(
        template = template,
        output = vivado_tcl,
        substitutions = substitutions,
    )

    # Build the bash command
    vivado_command = ""
    if env.xilinx_env:
        vivado_command += "source " + env.xilinx_env.path + " && "
        
    vivado_command += "vivado -mode batch -source " + vivado_tcl.short_path
    # Hardcode the log names so they write to the host's current working directory
    vivado_command += " -log program_device.log -journal program_device.jou;"

    action_inputs = input_files + [vivado_tcl]
    if env.xilinx_env:
        action_inputs.append(env.xilinx_env)

    executable_script = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
    ctx.actions.write(executable_script, vivado_command, is_executable = True)

    return [
        DefaultInfo(
            executable = executable_script,
            runfiles = ctx.runfiles(files = action_inputs),
        )
    ]


def _vivado_program_device_impl(ctx):
    if DefaultInfo in ctx.attr.bitstream:
        bitstream_in = ctx.attr.bitstream[DefaultInfo].files.to_list()[0]
    else:
        bitstream_in = ctx.files.bitstream[0]

    substitutions = {
        "{{BITSTREAM}}": bitstream_in.short_path,
    }

    default_info = create_executable_tcl_sh(
        ctx = ctx,
        template = ctx.file.program_device_template,
        substitutions = substitutions,
        input_files = [bitstream_in],
    )

    return default_info


vivado_program_device = rule(
    doc = "Program Device.",
    implementation = _vivado_program_device_impl,
    toolchains = [TOOLCHAIN_TYPE],
    executable = True,
    attrs = {
        "bitstream": attr.label(
            doc = "The bitstream to program the device with.",
            providers = [DefaultInfo],
            mandatory = True,
            allow_files = [".bit"],
        ),
        "program_device_template": attr.label(
            doc = "The program device tcl template",
            default = "program_device.tcl.template",
            allow_single_file = [".template"],
        ),
    },
)
