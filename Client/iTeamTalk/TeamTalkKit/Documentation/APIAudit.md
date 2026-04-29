# API Audit

This document records the current TeamTalkKit API split between the preferred
Swift layer and the compatibility layer that still exists to support the app's
ongoing migration away from the raw C API.

## Preferred Public API

Application code should prefer:

- `TeamTalkClient` methods returning `TeamTalkCommandID` from
  `TeamTalkClientCommands.swift`
- typed snapshot models such as `TeamTalkUser`, `TeamTalkChannel`,
  `TeamTalkRemoteFile`, `TeamTalkFileTransfer`, `TeamTalkTextMessage`,
  `TeamTalkServerProperties` and `TeamTalkUserAccount`
- configuration models such as `TeamTalkChannelConfiguration`,
  `TeamTalkUserAccountConfiguration`, `TeamTalkServerPropertiesConfiguration`,
  `TeamTalkBanConfiguration`, `TeamTalkMediaFilePlaybackConfiguration` and
  `TeamTalkUserMediaStorageConfiguration`
- typed IDs and option sets such as `TeamTalkUserID`, `TeamTalkChannelID`,
  `TeamTalkFileID`, `TeamTalkTransferID`, `TeamTalkCommandID`,
  `TeamTalkSubscriptions`, `TeamTalkUserRights` and `TeamTalkStreamTypes`
- `TeamTalkEvent` and `AsyncStream<TeamTalkEvent>` instead of polling raw
  `TTMessage` values directly

This is the surface area whose naming and ergonomics should keep improving.

## Compatibility API To Keep Public For Now

The following should remain public until the app no longer depends on them:

- `@_exported import TeamTalkC` in `Exports.swift`
- raw C model access through `rawValue` and `cValue`
- raw C struct extensions on `User`, `Channel`, `RemoteFile`, `FileTransfer`,
  `TTMessage`, `AudioCodec`, `AudioPreprocessor` and related types
- `Int32`-based overloads in modern `TeamTalkClient` files where they support
  mixed migration and simplify bridging from older code

These APIs are still useful escape hatches, especially when an SDK feature is
only partially wrapped or when the app still holds raw TeamTalk C values.

## Compatibility API Likely To Be Deprecated Later

Once iTeamTalk has largely migrated to the Swift model layer, the strongest
candidates for deprecation are:

- the command methods in `TeamTalkClientLegacyCommands.swift`
- `Int32` ID overloads in `TeamTalkClientCommands.swift` when a typed overload
  already exists for the same operation
- `Int32` ID overloads in `TeamTalkClientServerState.swift` where typed lookup
  and typed model overloads now exist side by side
- `Int32` session/channel/user overloads in `TeamTalkClientMedia.swift` and
  `TeamTalkClientDesktopVideo.swift` when the typed alternatives cover the same
  call paths used by the app
- low-level event helpers in `TeamTalkClientEvents.swift` that still take raw
  `StreamType` or `UInt32` when the typed overloads become sufficient for all
  in-tree callers

The deprecation pass should be additive and gentle:

1. keep the raw API public
2. add deprecation messages steering callers toward the typed overloads
3. only consider removal after at least one release cycle of app migration

## APIs That Should Not Be Deprecated Soon

The following are still worth keeping available even after app migration:

- `rawValue` and `cValue` on typed wrappers
- selected raw C extensions that expose data not yet mirrored on a typed model
- `TeamTalkC` re-export, at least until async helpers and broader wrapper
  coverage make the raw API a much rarer escape hatch

TeamTalkKit is still intentionally a wrapper around the TeamTalk SDK, not a
sealed abstraction that hides the native layer completely.

## Event Naming Audit

Current event naming is mostly in good shape. The recent cleanup fixed the two
main rough spots:

- `connectionMaxPayloadUpdated(maxPayloadSize:)` now reflects the actual SDK
  payload field instead of exposing a misleading `source` label
- `hotkey(hotkeyID:isActive:)` is clearer than `hotkey(id:isActive:)`

Remaining raw scalar payloads in `TeamTalkEvent.Kind`, such as key codes or
payload sizes, are intentionally left as scalar values because they are not
SDK identity types.

## Recommended Next Step

After the app migrates more call sites to the typed layer, add deprecation
attributes to the first wave of compatibility methods in
`TeamTalkClientLegacyCommands.swift` and the duplicate `Int32` overloads that
already have a direct typed replacement.
