# TeamTalkKit

TeamTalkKit is the Swift package used by iTeamTalk to wrap the TeamTalk C SDK.
The package is intentionally moving in two layers:

- a compatibility layer which still exposes TeamTalk C types when they are needed;
- a modern Swift layer with typed options, models, events and command APIs.

The goal is that application code can mostly talk to Swift types like
`TeamTalkUser`, `TeamTalkChannel`, `TeamTalkCommandID`,
`TeamTalkSubscriptions` and `TeamTalkUserRights`, while keeping access to the
underlying C values through `rawValue` and `cValue`.

## Platform Status

`Package.swift` declares:

- iOS 16 and newer
- macOS 10.15 and newer

The macOS declaration makes the Swift package buildable from SwiftPM on macOS,
especially because the event stream API uses `AsyncStream`. It does not by
itself prove that a macOS app can run TeamTalkKit end to end. A macOS consumer
still needs the correct TeamTalk runtime/library linkage and runtime testing.

## Documentation

- [Getting Started](Documentation/GettingStarted.md)
- [Advanced Usage](Documentation/Advanced.md)
- [TODO](Documentation/TODO.md)

## Current API Shape

TeamTalkKit currently contains:

- typed wrappers for user rights, user types, subscriptions, stream types,
  channel types, server log events, ban types, client events and payload types;
- snapshot models for users, channels, server properties, user accounts, remote
  files, file transfers, text messages, bans and server statistics;
- configuration models for creating/updating user accounts, channels, server
  properties, bans and outgoing text messages;
- `TeamTalkCommandID` for tracking command processing;
- a typed event system through `TeamTalkEventObserver` and
  `AsyncStream<TeamTalkEvent>`;
- Swift command APIs on `TeamTalkClient` for login, channels, files, bans,
  user accounts, server settings and server statistics;
- raw C escape hatches via the exported `TeamTalkC` module.

The package is not complete yet. See [TODO](Documentation/TODO.md) for the
remaining wrapper work.

## Build Checks

From the package directory:

```sh
swift build
```

From the iTeamTalk workspace:

```sh
xcodebuild -scheme iTeamTalk -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The iTeamTalk build may emit warnings from the bundled `libTeamTalk5.a`; those
warnings are currently unrelated to the Swift wrapper layer.
