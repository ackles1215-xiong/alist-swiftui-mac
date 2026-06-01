# AList SwiftUI Mac Design

## Goal

Build a native SwiftUI macOS wrapper for AList. The first milestone is an MVP that can configure, start, stop, observe, and open a local AList service. The next milestone extends the wrapper into a polished desktop shell while continuing to use AList's existing web admin UI for file management and server administration.

## Scope

The MVP includes:

- Menu bar presence with service status.
- Main window with service controls.
- Port, binary path, and data directory settings.
- Start and stop actions for a local `alist` process.
- Log capture from standard output and standard error.
- Open local admin URL in the default browser.
- Basic service health state shown in the app.
- Embedded WebKit view for the local AList admin UI.
- Automatic local binary discovery from bundled and common install paths.
- GitHub desktop release metadata parsing for future update/download flow.

The MVP does not include:

- Reimplementing AList's web file manager in SwiftUI.
- Editing AList storage drivers natively.
- Shipping a signed/notarized `.app` package.
- Automatic binary download or update from the UI.

## Architecture

The project is a Swift Package with two targets:

- `AListCore`: platform-neutral service logic that can be tested without SwiftUI.
- `AListSwiftUIMac`: a macOS SwiftUI executable target that renders the window and menu bar.

`AListCore` owns configuration, command construction, process lifecycle, and log storage. The UI owns presentation state and sends user actions to `AListServiceController`.

## Data Flow

1. `SettingsStore` loads `AListConfiguration` from `UserDefaults`.
2. `BinaryDiscovery` suggests a local `alist` binary from bundled and common install paths.
3. The SwiftUI app creates a shared `AListServiceController`.
4. Start builds an `AListLaunchConfiguration` from the current configuration.
5. The process launcher starts `alist server --data <dataDirectory>` and supplies `ALIST_ADDR` plus `ALIST_HTTP_PORT`.
6. Output streams append lines into `LogStore`.
7. `HTTPHealthChecker` probes the admin URL while the service is running.
8. UI observes service state, health, and logs, then updates controls.

## UI

The MVP uses a restrained macOS utility layout:

- Sidebar-like status panel with the current state, port, and URL.
- Primary controls for start, stop, and open admin.
- Settings form for binary path, data directory, and port.
- Log panel with monospace output.
- Embedded admin panel backed by `WKWebView`.
- Menu bar extra with start/stop/open/quit commands.

The design follows `/Users/ackles/.codex/DESIGN.md` where applicable: dark utility surfaces, dense information, clear hairline separation, and minimal decorative styling.

## Error Handling

- Missing binary path: show a clear error and keep state stopped.
- Invalid port: reject before launch.
- Port selection: pass `ALIST_HTTP_PORT` to AList because the `server` command reads listen settings from config/env rather than command flags.
- Process launch failure: append error to logs and set state failed.
- Stop when no process exists: no-op and keep stopped.

## Testing

Core behavior is tested in `AListCoreTests`:

- Default configuration produces `http://127.0.0.1:<port>`.
- Port validation rejects out-of-range values.
- Command builder emits the expected executable URL, arguments, and working directory.
- Log store keeps recent entries in insertion order.
- Service controller moves between stopped, running, and stopped using a fake launcher.
- Binary discovery chooses the first executable candidate.
- Desktop release metadata selects the matching macOS app archive.
- Health checker maps HTTP status and connection failures to UI health states.

SwiftUI rendering is verified by building the executable target. Manual app behavior can be checked with `swift run AListSwiftUIMac`.

## GitHub

The upstream forks are:

- `https://github.com/ackles1215-xiong/alist`
- `https://github.com/ackles1215-xiong/desktop-release`

The SwiftUI wrapper should live in a separate repository named `alist-swiftui-mac`.
