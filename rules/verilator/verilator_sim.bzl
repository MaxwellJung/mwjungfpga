"""Rule to run a Verilator simulation with optional GTKWave."""

def _verilator_sim_run_impl(ctx):
    sim_bin = ctx.executable.sim_bin

    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = script,
        substitutions = {
            "%SIM_RLOCATION%": "{}/{}".format(ctx.workspace_name, sim_bin.short_path),
            "%WAVEFORM%": ctx.attr.waveform,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = [sim_bin])
    runfiles = runfiles.merge(ctx.attr.sim_bin[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr._runfiles[DefaultInfo].default_runfiles)

    return [
        DefaultInfo(
            executable = script,
            runfiles = runfiles,
        ),
    ]

verilator_sim_run = rule(
    doc = "Run a Verilator simulation executable; pass --gtkwave to open the VCD in GTKWave.",
    implementation = _verilator_sim_run_impl,
    executable = True,
    attrs = {
        "sim_bin": attr.label(
            doc = "Verilator simulation executable to run.",
            mandatory = True,
            executable = True,
            cfg = "target",
        ),
        "waveform": attr.string(
            doc = "VCD filename written under TEST_UNDECLARED_OUTPUTS_DIR by the testbench.",
            mandatory = True,
        ),
        "_template": attr.label(
            default = "//rules/verilator:verilator_sim.sh.tpl",
            allow_single_file = True,
        ),
        "_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
    },
)
