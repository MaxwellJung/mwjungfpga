#!/usr/bin/env bash
# Runs a Verilator simulation and, when requested, opens the resulting VCD in
# GTKWave.
#
# Usage:
#   <target> [--gtkwave|--wave] [-- <extra sim args>...]
#
# Placeholders below are substituted by the verilator_sim_test rule.

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null ||
  source "$0.runfiles/$f" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
  {
    echo >&2 "ERROR: cannot find $f"
    exit 1
  }
f=
set -e
# --- end runfiles.bash initialization v3 ---

set -euo pipefail

readonly SIM_RLOCATION="%SIM_RLOCATION%"
readonly WAVEFORM="%WAVEFORM%"

open_wave=0
sim_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --gtkwave | --wave)
      open_wave=1
      shift
      ;;
    --)
      shift
      sim_args+=("$@")
      break
      ;;
    *)
      sim_args+=("$1")
      shift
      ;;
  esac
done

# Fail fast if the waveform viewer was requested but is unavailable, so we do
# not run the whole simulation only to error at the end.
if [[ "$open_wave" -eq 1 ]] && ! command -v gtkwave >/dev/null 2>&1; then
  echo >&2 "error: gtkwave not found on PATH"
  exit 1
fi

sim_bin="$(rlocation "$SIM_RLOCATION")" || true
if [[ -z "${sim_bin:-}" || ! -x "$sim_bin" ]]; then
  echo >&2 "error: simulation binary not found in runfiles: $SIM_RLOCATION"
  exit 1
fi

# The testbench writes its VCD under TEST_UNDECLARED_OUTPUTS_DIR; honor an
# existing value (e.g. from `bazel test`) or create a scratch directory.
out_dir="${TEST_UNDECLARED_OUTPUTS_DIR:-$(mktemp -d -t verilator_sim.XXXXXX)}"
export TEST_UNDECLARED_OUTPUTS_DIR="$out_dir"

if [[ ${#sim_args[@]} -gt 0 ]]; then
  "$sim_bin" "${sim_args[@]}"
else
  "$sim_bin"
fi

if [[ "$open_wave" -eq 0 ]]; then
  exit 0
fi

vcd="$out_dir/$WAVEFORM"
if [[ ! -f "$vcd" ]]; then
  echo >&2 "error: expected waveform not found: $vcd"
  exit 1
fi

exec gtkwave "$vcd"
