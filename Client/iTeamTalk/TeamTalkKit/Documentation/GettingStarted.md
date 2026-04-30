# Getting Started

This guide shows the intended Swift-first way to use TeamTalkKit. The old C-like
methods remain available for compatibility, but new app code should prefer the
typed APIs.

## Import

Add TeamTalkKit as a Swift package dependency, then import it:

```swift
import TeamTalkKit
```

TeamTalkKit re-exports `TeamTalkC`, so raw C SDK types remain available when
needed.

## Start And Close

Create the TeamTalk instance once during app startup:

```swift
let client = TeamTalkClient.shared

client.start(
    licenseName: REGISTRATION_NAME,
    licenseKey: REGISTRATION_KEY
)
```

Release the instance when the app is shutting down:

```swift
TeamTalkClient.shared.close()
```

## Connect And Log In

Connecting returns a synchronous `Bool` because it starts the connection
attempt. The actual connection result arrives later through events.

```swift
let didStartConnection = client.connect(
    toHost: "example.org",
    tcpPort: 10333,
    udpPort: 10333,
    encrypted: false
)

guard didStartConnection else {
    return
}
```

After receiving `.connectionSucceeded`, log in. New code should usually prefer
the async helper:

```swift
Task {
    try await client.logIn(
        nickname: "Alice",
        username: "alice",
        password: "secret",
        clientName: "iTeamTalk"
    )
}
```

The lower-level command-returning overloads still exist when you explicitly want
to compare `TeamTalkCommandID` values against command events.

## Event Dispatch

The TeamTalk C SDK is poll based, but new TeamTalkKit code does not need to
call `pollMessages()` directly. As soon as you subscribe through
`TeamTalkEventObserver`, `eventPublisher`, or `events`, TeamTalkKit starts its
internal dispatch loop automatically.

## Observe Typed Events

Use `TeamTalkEventObserver` when you want a delegate-style observer:

```swift
final class SessionModel: TeamTalkEventObserver {
    func handleTeamTalkEvent(_ event: TeamTalkEvent) {
        switch event.kind {
        case .connectionSucceeded:
            TeamTalkClient.shared.logIn(
                nickname: "Alice",
                username: "alice",
                password: "secret",
                clientName: "iTeamTalk"
            )

        case .commandError(let commandID, let error):
            print("Command \(commandID) failed: \(error.message)")

        case .myselfLoggedIn(let userID, let account):
            print("Logged in as \(userID), rights: \(account.rights)")

        default:
            break
        }
    }
}
```

Register and remove observers explicitly:

```swift
let model = SessionModel()
client.addEventObserver(model)
client.removeEventObserver(model)
```

Use Combine when you prefer publisher-style observation:

```swift
import Combine

let cancellable = client.eventPublisher.sink { event in
    print(event.kind)
}
```

You can also consume events as an `AsyncStream`:

```swift
Task {
    for await event in TeamTalkClient.shared.events {
        print(event.kind)
    }
}
```

## Query Server State

Once logged in, query snapshots with Swift models:

```swift
let properties = client.serverProperties()
let account = client.currentUserAccount()
let channels = client.channels()
let users = client.serverUsers()
let files = client.remoteFiles(in: client.myChannelID)
```

Each model keeps the raw C value available:

```swift
if let channel = client.channel(id: client.myChannelID) {
    let rawChannel: Channel = channel.cValue
    print(rawChannel.nChannelID)
}
```

## Join A Channel

Join by ID:

```swift
try await client.joinChannel(withID: channel.id, password: "")
```

Create or join with a channel configuration:

```swift
let configuration = TeamTalkChannelConfiguration(
    parentID: client.rootChannelID,
    name: "Meeting",
    topic: "Weekly sync",
    types: [.default],
    maxUsers: 25
)

try await client.join(configuration)
```

## Send Text Messages

Use `TeamTalkOutgoingTextMessage`. Long messages are split into multiple
TeamTalk text-message packets automatically.

```swift
try await client.sendTextMessage(
    .channel(client.myChannelID, content: "Hello")
)
```

For private messages:

```swift
try await client.sendTextMessage(.user(to: user.id, content: "Hi"))
```

## Files

List files in a channel:

```swift
let files = client.remoteFiles(in: channel.id)
```

Download:

```swift
try await client.downloadFile(file, to: destinationURL)
```

Upload:

```swift
try await client.uploadFile(at: localURL, to: channel)
```

Track progress through `.fileTransfer` events:

```swift
case .fileTransfer(let transfer):
    print(transfer.progress)
```

## Rights And Options

Swift option sets wrap TeamTalk bitmasks:

```swift
if client.hasUserRight(.canUploadFiles) {
    print("Can upload")
}

if user.hasSubscription(.voice) {
    print("Receiving voice from user")
}
```

When the C value is needed:

```swift
let rawRights: UserRights = TeamTalkUserRights.canUploadFiles.cValue
```
