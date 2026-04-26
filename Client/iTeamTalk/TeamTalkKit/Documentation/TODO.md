# TODO

TeamTalkKit is now more than a thin wrapper, but it is not complete. This file
tracks the remaining package work before it can be treated as a comprehensive
Swift SDK.

## High Priority

- [x] Add a test target for TeamTalkKit.
- [x] Add typed error wrappers for TeamTalk command/client error codes instead
  of exposing only `Int32` error numbers.
- [x] Add lightweight wrappers for common SDK IDs: `TeamTalkUserID`,
  `TeamTalkChannelID`, `TeamTalkFileID`, `TeamTalkTransferID`.
- [x] Cover mapping tests for current Swift `OptionSet` and raw wrappers.
- [x] Cover initial model/configuration round trips, especially string fields
  copied through `TeamTalkC`.
- [x] Cover initial `TeamTalkEvent.Kind` decoding for common event payloads.
- [x] Vendor TeamTalk native SDK artifacts inside the Swift package.
- [ ] Decide which APIs should be public compatibility APIs and which should be
  deprecated once the app migrates to the Swift model layer.
- [ ] Add documentation comments to the public Swift API once the names settle.

## Wrapper Coverage Still Missing

- [x] Sound device enumeration and richer sound-device models.
- [x] Audio input/output configuration models beyond the current helper methods.
- [x] Sound device effects wrappers.
- [x] Media file playback APIs and typed media file models.
- [x] Desktop sharing and desktop input wrappers.
- [x] Video capture device wrappers.
- Hotkey registration wrappers (Windows-only).
- [x] Local recording wrappers.
- [x] Audio block APIs.
- [x] Advanced audio preprocessors wrappers.
- [x] Complete channel transmission list helpers for `transmitUsers` and
  `transmitUsersQueue`.
- [x] Channel path helpers and typed path components.
- [x] More complete server abuse-prevention helpers.
- [x] More complete server logging/admin helpers where the SDK has additional
  commands not yet exposed by the Swift layer.

## API Design Follow-Ups

- Continue migrating event payloads and application-facing APIs from raw `Int32`
  IDs to lightweight ID wrappers where it improves clarity.
- Consider a dedicated `TeamTalkSession` type instead of exposing only
  `TeamTalkClient.shared`.
- Consider async command helpers which wait for matching success/error events:
  `try await client.joinChannel(...)`.
- Consider typed event streams filtered by command ID or event kind.
- Consider model builders for `Channel`, `UserAccount`, `ServerProperties` and
  `BannedUser` once the configuration structs grow.
- Decide whether Swift model snapshots should conform to `Sendable`, `Equatable`
  and `Hashable`.
- Decide how much of `TeamTalkC` should remain re-exported long term.

## macOS Follow-Ups

- Validate runtime linking with the vendored macOS TeamTalk library from an app
  target, not only from package tests.
- Add a small macOS command-line smoke test target if practical.
- Test sound device initialization on macOS.
- Test file upload/download paths on macOS sandboxed and non-sandboxed apps.
- Document any runtime embedding requirements for macOS app consumers if Xcode
  does not handle the vendored `.dylib` automatically.

## Native SDK Follow-Ups

- Add a repeatable script for regenerating `TeamTalkNativeiOS.xcframework` from
  `Library/TeamTalkLib` outputs.
- Track the vendored TeamTalk SDK version and update steps.
- Add or link the upstream license text if the SDK distribution provides a
  separate license file.

## Application Migration

- Migrate iTeamTalk from raw `Channel`, `User`, `RemoteFile` and `FileTransfer`
  usage to Swift models where it improves clarity.
- Move command tracking in the app from raw `Int32` to `TeamTalkCommandID`.
- Migrate file tab code to `TeamTalkRemoteFile` and `TeamTalkFileTransfer`.
- Migrate user rights/subscriptions checks to the Swift option sets.
- Keep raw C escape hatches only where a TeamTalk feature has not been wrapped
  yet.

## Documentation Follow-Ups

- Add examples for account administration once the app has an admin UI.
- Add examples for file browsing once the Files tab is migrated to the new API.
- Add examples for async command helpers if they are implemented.
- Add a generated symbol reference later, after the public API stabilizes.
