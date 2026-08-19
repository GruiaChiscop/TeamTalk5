// TeamTalkKitExample
//
// A minimal console client showing the lifecycle every TeamTalkKit app
// follows: start the SDK, connect, log in, do something, then tear down
// cleanly. Run it against your own TeamTalk server:
//
//   swift run TeamTalkKitExample <host> [tcpPort] [udpPort] [nickname]
//   swift run TeamTalkKitExample talk.example.org 10333 10333 ExampleBot
//
// With no username/password this logs in as a guest, which only works if
// the server allows guest logins. See ../../Documentation/GettingStarted.md
// for a walkthrough of the API this example exercises.

import Foundation
import TeamTalkKit

func waitForConnection(_ session: TeamTalkSession, timeoutSeconds: TimeInterval) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
            for await event in session.events {
                switch event.kind {
                case .connectionSucceeded:
                    return
                case .connectionLost:
                    throw ExampleError.connectionFailed
                default:
                    continue
                }
            }
            throw ExampleError.connectionFailed
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
            throw ExampleError.timedOut
        }
        try await group.next()
        group.cancelAll()
    }
}

enum ExampleError: Error, CustomStringConvertible {
    case connectionFailed
    case timedOut

    var description: String {
        switch self {
        case .connectionFailed: return "the connection was lost before it succeeded"
        case .timedOut: return "timed out waiting for the server"
        }
    }
}

func displayName(_ user: TeamTalkUser) -> String {
    user.nickname.isEmpty ? user.username : user.nickname
}

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    print("""
    Usage: TeamTalkKitExample <host> [tcpPort] [udpPort] [nickname]

    Connects to a TeamTalk server as a guest, prints the channel list, joins
    the root channel, and prints text messages/join events for 15 seconds.

    Example:
      swift run TeamTalkKitExample talk.example.org 10333 10333 ExampleBot
    """)
    exit(1)
}

let host = arguments[1]
let tcpPort = arguments.count > 2 ? Int32(arguments[2]) ?? 10333 : 10333
let udpPort = arguments.count > 3 ? Int32(arguments[3]) ?? tcpPort : tcpPort
let nickname = arguments.count > 4 ? arguments[4] : "TeamTalkKitExample"

// An empty license name/key runs the SDK unregistered, the same default
// iTeamTalk itself ships with (see iTeamTalk/License.swift). BearWare.dk
// issues a real license key for production use.
let session = TeamTalkSession()
session.start(licenseName: "", licenseKey: "")
session.startEventDispatching()

func shutDown(_ session: TeamTalkSession) async {
    print("\nLogging out and disconnecting...")
    do {
        // Same overload-disambiguation reason as the logIn() call below.
        let _: Void = try await session.logOut()
    } catch {
        // Ignore — we're tearing down either way.
    }
    session.disconnect()
    session.stopEventDispatching()
    session.close()
}

do {
    print("Connecting to \(host):\(tcpPort) (UDP \(udpPort))...")
    guard session.connect(toHost: host, tcpPort: tcpPort, udpPort: udpPort, encrypted: false) else {
        print("Failed to start the connection.")
        exit(1)
    }

    try await waitForConnection(session, timeoutSeconds: 10)
    print("Connected. Logging in as \"\(nickname)\"...")

    // Annotating the expected type matters here: TeamTalkSession has both a
    // sync logIn(...) -> TeamTalkCommandID and this async logIn(...) async
    // throws -> TeamTalkUser overload with the same argument labels, and
    // `try await` alone doesn't reliably disambiguate a `let`-bound call
    // between them.
    let me: TeamTalkUser = try await session.logIn(nickname: nickname, username: "", password: "", clientName: "TeamTalkKitExample")
    print("Logged in as user #\(me.id) (\(displayName(me))).")

    let channels = session.channels().sorted { $0.name < $1.name }
    print("\n\(channels.count) channel(s):")
    for channel in channels {
        let suffix = channel.isPasswordProtected ? " (password protected)" : ""
        print("  #\(channel.id) \(channel.name)\(suffix)")
    }

    if let root = session.channel(id: TeamTalkChannelID(session.rootChannelID)) {
        print("\nJoining \"\(root.name)\"...")
        let _: Void = try await session.joinChannel(root)
        print("Joined.")
    }

    print("\nListening for 15 seconds (Ctrl+C to stop earlier)...")
    let deadline = Date().addingTimeInterval(15)
    for await event in session.events {
        switch event.kind {
        case .textMessage(let message):
            print("Message: \(message.content)")
        case .userJoined(let user) where user.userID != me.userID:
            print("\(displayName(user)) joined.")
        case .userLeft(_, let user) where user.userID != me.userID:
            print("\(displayName(user)) left.")
        default:
            break
        }
        if Date() >= deadline {
            break
        }
    }
} catch {
    print("Error: \(error)")
}

await shutDown(session)
print("Done.")
