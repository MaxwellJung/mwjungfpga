"""Macro for Verilator simulation test + interactive run with optional GTKWave."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def _verilator_sim_run_impl(ctx):
    sim_bin = ctx.executable.sim_bin
    workspace = ctx.workspace_name
    waveform = ctx.attr.waveform

    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = script,
        content = """#!/usr/bin/env bash
set -euo pipefail

SIM_RLOCATION="{sim_rlocation}"
WAVEFORM="{waveform}"

OPEN_WAVE=0
SIM_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --gtkwave | --wave)
      OPEN_WAVE=1
      shift
      ;;
    *)
      SIM_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -d "$(dirname "$0")/$(basename "$0").runfiles" ]]; then
  RUNFILES_DIR="$(cd "$(dirname "$0")/$(basename "$0").runfiles" && pwd)"
elif [[ -n "${{RUNFILES_DIR:-}}" && -d "${{RUNFILES_DIR}}" ]]; then
  RUNFILES_DIR="$(cd "${{RUNFILES_DIR}}" && pwd)"
elif [[ -d "${{0}}.runfiles" ]]; then
  RUNFILES_DIR="$(cd "${{0}}.runfiles" && pwd)"
else
  echo "error: runfiles directory not found for $0" >&2
  exit 1
fi

_rlocation() {{
  local key="$1"
  if [[ -f "${{RUNFILES_DIR}}/MANIFEST" ]]; then
    local path
    path="$(grep -m1 "^${{key}} " "${{RUNFILES_DIR}}/MANIFEST" | awk '{{print $2}}')"
    if [[ -n "$path" ]]; then
      echo "$path"
      return 0
    fi
  fi
  if [[ -e "${{RUNFILES_DIR}}/${{key}}" ]]; then
    echo "${{RUNFILES_DIR}}/${{key}}"
    return 0
  fi
  return 1
}}

SIM_BIN="$(_rlocation "${{SIM_RLOCATION}}")" || true
if [[ -z "${{SIM_BIN:-}}" || ! -x "$SIM_BIN" ]]; then
  echo "error: simulation binary not found in runfiles: ${{SIM_RLOCATION}}" >&2
  exit 1
fi

OUT_DIR="${{TEST_UNDECLARED_OUTPUTS_DIR:-$(mktemp -d -t verilator_sim.XXXXXX)}}"
export TEST_UNDECLARED_OUTPUTS_DIR="$OUT_DIR"

if [[ ${{#SIM_ARGS[@]}} -gt 0 ]]; then
  "$SIM_BIN" "${{SIM_ARGS[@]}}"
else
  "$SIM_BIN"
fi

if [[ "$OPEN_WAVE" -eq 0 ]]; then
  exit 0
fi

if ! command -v gtkwave >/dev/null 2>&1; then
  echo "error: gtkwave not found on PATH" >&2
  exit 1
fi

VCD="$OUT_DIR/$WAVEFORM"
if [[ ! -f "$VCD" ]]; then
  echo "error: expected waveform not found: $VCD" >&2
  exit 1
fi

exec gtkwave "$VCD"
""".format(
            sim_rlocation = workspace + "/" + sim_bin.short_path,
            waveform = waveform,
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = [sim_bin])
    default_runfiles = ctx.attr.sim_bin[DefaultInfo].default_runfiles
    if default_runfiles:
        runfiles = runfiles.merge(default_runfiles)

    return [
        DefaultInfo(
            executable = script,
            runfiles = runfiles,
        ),
    ]

_verilator_sim_run = rule(
    doc = "Run a Verilator simulation; pass --gtkwave to open the VCD afterward.",
    implementation = _verilator_sim_run_impl,
    executable = True,
    attrs = {
        "sim_bin": attr.label(
            doc = "Verilator cc_binary to execute.",
            mandatory = True,
            executable = True,
            cfg = "exec",
        ),
        "waveform": attr.string(
            doc = "VCD filename written under TEST_UNDECLARED_OUTPUTS_DIR.",
            mandatory = True,
        ),
    },
)

def verilator_sim(
        name,
        verilated,
        waveform,
        size = "small",
        sim_tags = [],
        run_tags = ["manual"],
        **kwargs):
    """Create Verilator simulation targets.

    Targets:
      :{name}_bin  — cc_binary (private)
      :{name}_test — cc_test for CI (`bazel test //rtl/...`)
      :{name}      — runnable sim (`bazel run ... -- --gtkwave`)

    Args:
      name: Base target name (typically "sim").
      verilated: Verilator library label for the testbench top.
      waveform: VCD filename written under TEST_UNDECLARED_OUTPUTS_DIR.
      size: cc_test size attribute.
      sim_tags: Tags for the cc_test and cc_binary.
      run_tags: Tags for the run target.
      **kwargs: Additional cc_test attributes (for example, visibility).
    """
    bin_name = name + "_bin"
    test_name = name + "_test"

    cc_binary(
        name = bin_name,
        srcs = ["//sim_lib:cpp_sim_timing"],
        deps = [
            verilated,
            "//sim_lib:cpp_sim_lib",
        ],
        tags = sim_tags,
        visibility = ["//visibility:private"],
    )

    cc_test(
        name = test_name,
        size = size,
        srcs = ["//sim_lib:cpp_sim_timing"],
        deps = [
            verilated,
            "//sim_lib:cpp_sim_lib",
        ],
        tags = sim_tags,
        **kwargs
    )

    _verilator_sim_run(
        name = name,
        sim_bin = ":" + bin_name,
        waveform = waveform,
        tags = run_tags,
    )
