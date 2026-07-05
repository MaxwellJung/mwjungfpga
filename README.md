# mwjungfpga
Monorepo for all FPGA hobby projects by Maxwell Jung.

## Hardware

### Top level designs

**led** — counts up in binary.

```bash
bazel run //design/led:program_nexys
```

**rvfpganexys** — SweRVolf (RISC-V SoC) on FPGA.

```bash
bazel run //design/rvfpganexys:program_nexys
```

## RTL simulation

RTL testbenches are built with [rules_verilator](https://github.com/UebelAndre/rules_verilator). Each module declares two simulation targets in its `BUILD.bazel`:

| Target | Purpose |
|--------|---------|
| `:sim_test` | Headless simulation for CI (`cc_test`) |
| `:sim` | Interactive run (`verilator_sim_run`) of the `:sim_test` binary; pass `--gtkwave` to open the VCD in GTKWave |

Run all RTL simulations:

```bash
bazel test //rtl/...
```

Run a single testbench:

```bash
bazel test //rtl/counter:sim_test
```

Run interactively and view the waveform (GTKWave must be on `PATH`):

```bash
bazel run //rtl/counter:sim -- --gtkwave
```

## Bazel

This repo uses [Bazelisk](https://github.com/bazelbuild/bazelisk) with Bazel **9.1.1** (see `.bazelversion`).

Build everything (requires a local Vivado install for bitstream targets):

```bash
bazel build //...
```

Test RTL simulations only (no Vivado required):

```bash
bazel test //rtl/...
```

Lint RTL with Verilator:

```bash
bazel build --config=verilator_lint //rtl/...
```

Format and lint Starlark (`BUILD.bazel`, `.bzl` files):

```bash
bazel run //:buildifier
```

### Custom rules

Starlark rules live under `rules/` and are exported from `rules/defs.bzl`:

- `verilator_sim_run` — run a Verilator sim binary; pass `--gtkwave` to open the VCD in GTKWave
- `vivado_program_device` — program an FPGA from a generated bitstream

Shared Verilator simulation support (DPI getenv, `sc_time_stamp`, VCD output paths) lives in `rules/verilator/`.

## CI

GitHub Actions runs on pushes and pull requests to `main`:

- `bazelisk test //rtl/...`
- `bazelisk build --config=verilator_lint //rtl/...`

See [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

## Software

TODO
