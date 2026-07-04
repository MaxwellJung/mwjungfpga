# hdl-archive
Monorepo for all HDL projects.

## FPGA Top Level Designs

### led
```bash
bazel run //design/led:program_nexys
```

### rvfpganexys
```bash
bazel run //design/rvfpganexys:program_nexys
```

## Bazel Commands

### Build

To build all targets:
```bash
bazel build //...
```

### Test

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
