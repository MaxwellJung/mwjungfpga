# mwjungfpga
Monorepo for all FPGA hobby projects by Maxwell Jung.

## Hardware

### Top Level Designs
led: Counts up in binary.
```bash
bazel run //design/led:program_nexys
```

rvfpganexys: SweRVolf (RISC-V SoC) on FPGA.
```bash
bazel run //design/rvfpganexys:program_nexys
```

### Bazel

To build all targets:
```bash
bazel build //...
```

To test all targets:
```bash
bazel test //...
```

To test all RTL modules:
```bash
bazel test //rtl/...
```

To test specific RTL modules:
```bash
bazel test //rtl/counter/...
```

## Software

TODO
