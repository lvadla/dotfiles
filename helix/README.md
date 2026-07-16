# Helix

This package installs the shared Helix configuration and provides both `helix` and `hx` commands
on Linux and macOS.

The command wrappers select the native executable for the operating system:

- Linux uses the native `helix` executable.
- macOS uses the native `hx` executable.

The native Helix executable must already be installed and available on `PATH`. The wrappers skip
their own directory when searching `PATH`, so `helix` and `hx` do not call themselves recursively.

Install the package from the repository root with:

```bash
stow -vR helix -t ~
```
