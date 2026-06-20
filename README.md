# hdl-archive
Monorepo for all HDL projects.

## Test
To run all tests:
```bash
bazel test //...
```

To test all RTL modules:
```bash
bazel test //rtl/...
```

To test specific RTL modules
```bash
bazel test //rtl/counter/...
```
