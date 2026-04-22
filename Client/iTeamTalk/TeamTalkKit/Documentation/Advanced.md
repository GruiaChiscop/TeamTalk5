# Advanced Usage

This document explains the pieces that matter once the basic connection flow is
working.

## Package Layers

TeamTalkKit is organized around four layers:

- `TeamTalkC`: a small C bridge over the TeamTalk SDK header, mostly for fixed
  string arrays, C unions and helper constructors;
- `TeamTalkTypes.swift`: Swift wrappers for C enums and bitmasks;
- `TeamTalkModels.swift`: Swift snapshot/configuration models built from C
  structs;
- `TeamTalkClient.swift`: lifecycle, queries, command APIs and event dispatch.

The package still exports raw C APIs through `TeamTalkC`. This is intentional:
the modern wrapper is growing incrementally, and app code can still drop to C
types when a TeamTalk feature has not been wrapped yet.

## Raw Values And C Values

Most Swift wrappers expose both:

```swift
let rights = TeamTalkUserRights.canUploadFiles
let raw: UInt32 = rights.rawValue
let c: UserRights = rights.cValue
```

Most snapshot models expose the original struct:

```swift
let channel: TeamTalkChannel = ...
let rawChannel: Channel = channel.cValue
```

Configuration models go the other direction and build C structs:

```swift
let config = TeamTalkChannelConfiguration(
    parentID: TeamTalkClient.shared.rootChannelID,
    name: "Staff"
)

let rawChannel: Channel = config.cValue
```

## Typed IDs

TeamTalkKit now has lightweight wrappers for common SDK IDs:

```swift
let userID = TeamTalkUserID(5)
let channelID = TeamTalkChannelID(10)
let fileID = TeamTalkFileID(3)
let transferID = TeamTalkTransferID(8)
```

They preserve the C value through `cValue`, but make new Swift code clearer:

```swift
client.joinChannel(withID: channelID)
client.downloadFileCommand(channelID: channelID, fileID: fileID, to: localURL)
client.cancelFileTransfer(id: transferID)
```

Snapshot models still expose their existing `Int32` ID properties for source
compatibility. They also expose typed companions such as `user.userID`,
`channel.channelID`, `file.fileID` and `transfer.transferID`.

## Command Tracking

TeamTalk commands return an ID. The old API returned `Int32`; the new API returns
`TeamTalkCommandID`.

```swift
let commandID = client.joinChannel(withID: channelID)
```

Then match it in events:

```swift
switch event.kind {
case .commandProcessing(let id, let isActive) where id == commandID:
    print(isActive ? "Started" : "Finished")

case .commandError(let id, let error) where id == commandID:
    print(error.message)

case .commandSucceeded(let id) where id == commandID:
    print("OK")

default:
    break
}
```

`TeamTalkCommandID.invalid` maps to `-1`, which is the TeamTalk SDK error return.

## Event Dispatch

TeamTalkKit has two event APIs:

- `TeamTalkMessageObserver` receives raw `TTMessage` values;
- `TeamTalkEventObserver` receives decoded `TeamTalkEvent` values.

Both are fed by `pollMessages()`. The typed API is additive and does not remove
raw message support.

Important: `events: AsyncStream<TeamTalkEvent>` is only a stream wrapper over
the observer system. It does not poll the C SDK by itself.

## Server And Admin APIs

The modern command API includes wrappers for admin flows:

```swift
client.listUserAccounts(startingAt: 0, count: 100)

client.createUserAccount(
    TeamTalkUserAccountConfiguration(
        username: "guest",
        password: "guest",
        types: .defaultUser,
        rights: [.canTransmitVoice, .canSendChannelTextMessages]
    )
)

client.deleteUserAccount(username: "guest")
```

Server settings can be updated from a configuration:

```swift
let current = client.serverProperties()

if let current {
    var config = TeamTalkServerPropertiesConfiguration(current)
    config.name = "New Server Name"
    config.logEvents.insert(.userLoggedIn)
    client.updateServer(config)
}
```

Server statistics are requested with:

```swift
let commandID = client.queryServerStatistics()
```

The response arrives as:

```swift
case .serverStatistics(let statistics):
    print(statistics.usersServed)
```

## Bans

Ban types are represented as an `OptionSet`:

```swift
let ban = TeamTalkBanConfiguration(
    ipAddress: "192.168.1.*",
    types: [.ipAddress]
)

client.ban(ban)
```

For username/channel bans:

```swift
let ban = TeamTalkBanConfiguration(
    channelPath: "/Lobby",
    username: "guest",
    types: [.channel, .username]
)

client.ban(ban)
```

List bans:

```swift
client.listBans(channelID: 0, startingAt: 0, count: 100)
```

Each result arrives as:

```swift
case .bannedUser(let bannedUser):
    print(bannedUser.username, bannedUser.ipAddress)
```

## Files And Transfer Progress

File listing is synchronous from the current SDK state:

```swift
let files = client.remoteFiles(in: channelID)
```

Upload/download/delete are commands:

```swift
let uploadID = client.uploadFileCommand(at: localURL, toChannelID: channelID)
let downloadID = client.downloadFile(file, to: destinationURL)
let deleteID = client.deleteFile(file)
```

Transfer state arrives through `.fileTransfer`:

```swift
case .fileTransfer(let transfer):
    print(transfer.id, transfer.status, transfer.progress)
```

`TeamTalkFileTransfer.progress` is normalized from `0` to `1`.

## Threading And Lifecycle

TeamTalkKit currently assumes the app uses one shared `TeamTalkClient` instance.
The underlying SDK is stateful and poll based, so app code should avoid issuing
commands from many unrelated queues.

Recommended pattern:

- start the client during app initialization;
- connect/log in from a session model;
- call `pollMessages()` from one predictable loop;
- update UI state from decoded events;
- close the client during shutdown.

## macOS Notes

The package declares macOS 10.15 so `swift build` can compile TeamTalkKit on
macOS. This is useful for package validation and future desktop work.

The unit tests currently cover pure Swift wrapper behavior and payload decoding.
On macOS, the test target uses dynamic symbol lookup so these tests can run
without linking the iOS TeamTalk static library into a macOS executable. Tests
which call `TeamTalkClient` runtime methods should wait for a real macOS
TeamTalk library or dedicated test stubs.

Runtime macOS support still needs:

- the correct TeamTalk binary/library for macOS;
- linker settings for a macOS app target;
- audio device testing;
- file sandbox/security-scoped URL testing where applicable.

Until those are validated, macOS should be treated as package-build support, not
as a fully certified runtime target.
