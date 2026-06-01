# AList SwiftUI Mac

A native SwiftUI macOS wrapper for running a local AList service.

## Current MVP

- Start and stop a local `alist` binary.
- Configure binary path, data directory, and HTTP port.
- Open the local AList admin UI in the default browser.
- Show service state in the main window and menu bar.
- Capture stdout/stderr logs from the AList process.

## Requirements

- macOS 13 or newer.
- Xcode or Swift toolchain with Swift 6 support.
- An AList binary. You can use one from the official AList release or from the AList Desktop app bundle.

## Build

```bash
swift build
```

## Test

```bash
swift test
```

## Run

```bash
swift run AListSwiftUIMac
```

On first launch, set the AList binary path if `/usr/local/bin/alist` does not exist.

## Upstream References

- AList source fork: https://github.com/ackles1215-xiong/alist
- AList desktop release fork: https://github.com/ackles1215-xiong/desktop-release
