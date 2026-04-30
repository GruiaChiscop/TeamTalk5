import Foundation

public enum TeamTalkCommandAsyncError: Error, LocalizedError {
    case invalidCommand
    case commandFailed(commandID: TeamTalkCommandID, error: TeamTalkClientError)
    case eventStreamEnded(commandID: TeamTalkCommandID)

    public var errorDescription: String? {
        switch self {
        case .invalidCommand:
            return "The TeamTalk command could not be started."
        case .commandFailed(_, let error):
            return error.message
        case .eventStreamEnded(let commandID):
            return "The TeamTalk event stream ended before command \(commandID) completed."
        }
    }
}

private extension TeamTalkClient {
    func awaitCommandCompletion(_ commandID: TeamTalkCommandID, in events: AsyncStream<TeamTalkEvent>) async throws {
        for await event in events {
            switch event.kind {
            case .commandError(let observedCommandID, let error)
                where observedCommandID == commandID:
                throw TeamTalkCommandAsyncError.commandFailed(commandID: observedCommandID, error: error)

            case .commandProcessing(let observedCommandID, let isActive)
                where observedCommandID == commandID && !isActive:
                return

            case .commandSucceeded(let observedCommandID)
                where observedCommandID == commandID:
                return

            default:
                continue
            }
        }

        throw TeamTalkCommandAsyncError.eventStreamEnded(commandID: commandID)
    }

    func awaitCommandCompletions(_ commandIDs: Set<TeamTalkCommandID>, in events: AsyncStream<TeamTalkEvent>) async throws {
        var pending = commandIDs

        for await event in events {
            switch event.kind {
            case .commandError(let observedCommandID, let error)
                where pending.contains(observedCommandID):
                throw TeamTalkCommandAsyncError.commandFailed(commandID: observedCommandID, error: error)

            case .commandProcessing(let observedCommandID, let isActive)
                where pending.contains(observedCommandID) && !isActive:
                pending.remove(observedCommandID)
                if pending.isEmpty {
                    return
                }

            case .commandSucceeded(let observedCommandID)
                where pending.contains(observedCommandID):
                pending.remove(observedCommandID)
                if pending.isEmpty {
                    return
                }

            default:
                continue
            }
        }

        throw TeamTalkCommandAsyncError.eventStreamEnded(commandID: pending.first ?? .invalid)
    }

    func performCommand(_ start: () -> TeamTalkCommandID) async throws {
        let eventStream = events
        let commandID = start()

        guard commandID.isValid else {
            throw TeamTalkCommandAsyncError.invalidCommand
        }

        try await awaitCommandCompletion(commandID, in: eventStream)
    }

    func performCommands(_ start: () -> [TeamTalkCommandID]) async throws {
        let eventStream = events
        let commandIDs = start()

        guard !commandIDs.isEmpty else {
            throw TeamTalkCommandAsyncError.invalidCommand
        }

        let validCommandIDs = Set(commandIDs.filter(\.isValid))
        guard validCommandIDs.count == commandIDs.count else {
            throw TeamTalkCommandAsyncError.invalidCommand
        }

        try await awaitCommandCompletions(validCommandIDs, in: eventStream)
    }

    /// Awaits commandSucceeded for `commandID` AND a payload event matched by `extract`,
    /// emitted in either order. Times out to avoid hangs when the SDK skips one event.
    func performCommand<T: Sendable>(
        timeoutSeconds: TimeInterval = 15,
        _ start: () -> TeamTalkCommandID,
        extract: @escaping @Sendable (TeamTalkEvent.Kind, TeamTalkCommandID) -> T?
    ) async throws -> T {
        let stream = events
        let commandID = start()
        guard commandID.isValid else {
            throw TeamTalkCommandAsyncError.invalidCommand
        }

        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                var payload: T? = nil
                var succeeded = false
                for await event in stream {
                    if let value = extract(event.kind, commandID) {
                        payload = value
                    }
                    switch event.kind {
                    case .commandError(let observedID, let err) where observedID == commandID:
                        throw TeamTalkCommandAsyncError.commandFailed(commandID: observedID, error: err)
                    case .commandSucceeded(let observedID) where observedID == commandID:
                        succeeded = true
                    case .commandProcessing(let observedID, let isActive) where observedID == commandID && !isActive:
                        succeeded = true
                    default:
                        break
                    }
                    if succeeded, let p = payload {
                        return p
                    }
                }
                throw TeamTalkCommandAsyncError.eventStreamEnded(commandID: commandID)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                throw TeamTalkCommandAsyncError.eventStreamEnded(commandID: commandID)
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

extension TeamTalkClient {
    public func ping() async throws {
        try await performCommand { ping() }
    }

    public func logIn(
        nickname: String,
        username: String,
        password: String,
        clientName: String = ""
    ) async throws -> TeamTalkUser {
        let userID = try await performCommand({
            logIn(nickname: nickname, username: username, password: password, clientName: clientName)
        }) { kind, _ in
            if case .myselfLoggedIn(let id, _) = kind { return id } else { return nil }
        }
        guard let me = user(id: userID) else {
            throw TeamTalkCommandAsyncError.invalidCommand
        }
        return me
    }

    public func logOut() async throws {
        try await performCommand { logOut() }
    }

    public func joinChannel(_ channel: TeamTalkChannel, password: String = "") async throws {
        try await performCommand { joinChannel(channel, password: password) }
    }

    public func joinChannel(_ configuration: TeamTalkChannelConfiguration, password: String = "") async throws {
        try await performCommand { joinChannel(configuration, password: password) }
    }

    public func leaveChannel() async throws {
        try await performCommand { leaveChannel() }
    }

    public func createChannel(_ configuration: TeamTalkChannelConfiguration) async throws -> TeamTalkChannel {
        try await performCommand({ createChannel(configuration) }) { kind, _ in
            if case .channelCreated(let ch) = kind,
               ch.parentID == configuration.parentID,
               ch.name == configuration.name {
                return ch
            }
            return nil
        }
    }

    public func updateChannel(_ channel: TeamTalkChannel) async throws {
        try await performCommand { updateChannel(channel) }
    }

    public func updateChannel(_ configuration: TeamTalkChannelConfiguration) async throws {
        try await performCommand { updateChannel(configuration) }
    }

    public func removeChannel(_ channel: TeamTalkChannel) async throws {
        try await performCommand { removeChannel(channel) }
    }

    public func setNickname(_ nickname: String) async throws {
        try await performCommand { setNickname(nickname) }
    }

    public func setStatus(mode: TeamTalkStatusMode, message: String = "") async throws {
        try await performCommand { setStatus(mode: mode, message: message) }
    }

    public func kickUser(_ user: TeamTalkUser, from channel: TeamTalkChannel? = nil) async throws {
        try await performCommand { kickUser(user, from: channel) }
    }

    public func banUser(_ user: TeamTalkUser, from channel: TeamTalkChannel? = nil) async throws {
        try await performCommand { banUser(user, from: channel) }
    }

    public func banUser(_ user: TeamTalkUser, types: TeamTalkBanTypes) async throws {
        try await performCommand { banUser(user, types: types) }
    }

    public func ban(_ configuration: TeamTalkBanConfiguration) async throws {
        try await performCommand { ban(configuration) }
    }

    public func banIPAddress(_ ipAddress: String, in channel: TeamTalkChannel? = nil) async throws {
        try await performCommand { banIPAddress(ipAddress, in: channel) }
    }

    public func unbanIPAddress(_ ipAddress: String, in channel: TeamTalkChannel? = nil) async throws {
        try await performCommand { unbanIPAddress(ipAddress, in: channel) }
    }

    public func unban(_ configuration: TeamTalkBanConfiguration) async throws {
        try await performCommand { unban(configuration) }
    }

    public func listBans(in channel: TeamTalkChannel? = nil, startingAt index: Int32 = 0, count: Int32 = 100) async throws {
        try await performCommand { listBans(in: channel, startingAt: index, count: count) }
    }

    public func moveUser(_ user: TeamTalkUser, to channel: TeamTalkChannel) async throws {
        try await performCommand { moveUser(user, to: channel) }
    }

    public func setChannelOperator(_ user: TeamTalkUser, in channel: TeamTalkChannel, enabled: Bool) async throws {
        try await performCommand { setChannelOperator(user, in: channel, enabled: enabled) }
    }

    public func setChannelOperator(
        _ user: TeamTalkUser,
        in channel: TeamTalkChannel,
        operatorPassword: String,
        enabled: Bool
    ) async throws {
        try await performCommand { setChannelOperator(user, in: channel, operatorPassword: operatorPassword, enabled: enabled) }
    }

    public func subscribe(_ subscriptions: TeamTalkSubscriptions, to user: TeamTalkUser) async throws {
        try await performCommand { subscribe(subscriptions, to: user) }
    }

    public func unsubscribe(_ subscriptions: TeamTalkSubscriptions, from user: TeamTalkUser) async throws {
        try await performCommand { unsubscribe(subscriptions, from: user) }
    }

    public func sendTextMessage(_ message: TeamTalkOutgoingTextMessage) async throws {
        try await performCommands { sendTextMessage(message) }
    }

    public func sendTextMessage(to user: TeamTalkUser, content: String) async throws {
        try await sendTextMessage(.user(to: user, content: content))
    }

    public func sendTextMessage(to channel: TeamTalkChannel, content: String) async throws {
        try await sendTextMessage(.channel(channel, content: content))
    }

    public func sendChannelMessage(_ content: String) async throws {
        guard let channel = currentChannel() else {
            throw TeamTalkCommandAsyncError.invalidCommand
        }
        try await sendTextMessage(to: channel, content: content)
    }

    public func reply(to message: TeamTalkTextMessage, content: String) async throws {
        try await sendTextMessage(.reply(to: message, content: content))
    }

    public func uploadFile(at localURL: URL, to channel: TeamTalkChannel) async throws -> TeamTalkRemoteFile {
        let targetChannelID = channel.channelID
        return try await performCommand({ uploadFile(at: localURL, to: channel) }) { kind, _ in
            if case .fileCreated(let f) = kind, f.channelIdentifier == targetChannelID {
                return f
            }
            return nil
        }
    }

    public func downloadFile(_ file: TeamTalkRemoteFile, to localURL: URL) async throws {
        try await performCommand { downloadFile(file, to: localURL) }
    }

    public func deleteFile(_ file: TeamTalkRemoteFile) async throws {
        try await performCommand { deleteFile(file) }
    }

    public func updateServer(_ configuration: TeamTalkServerPropertiesConfiguration) async throws {
        try await performCommand { updateServer(configuration) }
    }

    public func updateServer(_ properties: TeamTalkServerProperties) async throws {
        try await performCommand { updateServer(properties) }
    }

    public func listUserAccounts(startingAt index: Int32 = 0, count: Int32 = 100) async throws {
        try await performCommand { listUserAccounts(startingAt: index, count: count) }
    }

    public func createUserAccount(_ configuration: TeamTalkUserAccountConfiguration) async throws {
        try await performCommand { createUserAccount(configuration) }
    }

    public func createUserAccount(_ account: TeamTalkUserAccount) async throws {
        try await performCommand { createUserAccount(account) }
    }

    public func deleteUserAccount(username: String) async throws {
        try await performCommand { deleteUserAccount(username: username) }
    }

    public func saveServerConfiguration() async throws {
        try await performCommand { saveServerConfiguration() }
    }

    public func queryServerStatistics() async throws {
        try await performCommand { queryServerStatistics() }
    }
}
