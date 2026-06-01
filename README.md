# AList SwiftUI Mac

A native SwiftUI macOS wrapper for running a local AList service.

## Current MVP

- Start and stop a local `alist` binary.
- Configure binary path, data directory, and HTTP port.
- Open the local AList admin UI in the default browser.
- Load the local AList admin UI inside an embedded WebKit view.
- Show service state in the main window and menu bar.
- Show basic Admin health state.
- Auto-detect likely local AList binary locations.
- Provide an Infuse-friendly WebDAV setup page with copy buttons.
- Capture stdout/stderr logs from the AList process.
- Parse AList Desktop GitHub release metadata for later update/download work.

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

On first launch, use the auto-detect button next to the binary path, or set the AList binary path manually if no local binary is found.

## Phase 1 Limitations

- The app checks release metadata shape in core code, but does not yet download or replace binaries from the UI.
- The embedded Admin view points at the configured local URL. Start AList before expecting the WebView to load.
- The app is not yet packaged, signed, notarized, or configured as a LaunchAgent.

## Upstream References

- AList source fork: https://github.com/ackles1215-xiong/alist
- AList desktop release fork: https://github.com/ackles1215-xiong/desktop-release
