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
    ) async throws {
        try await performCommand {
            logIn(
                nickname: nickname,
                username: username,
                password: password,
                clientName: clientName
            )
        }
    }

    public func logOut() async throws {
        try await performCommand { logOut() }
    }

    public func join(_ channel: TeamTalkChannel) async throws {
        try await performCommand { join(channel) }
    }

    public func join(_ channel: Channel) async throws {
        try await join(TeamTalkChannel(channel))
    }

    public func join(_ configuration: TeamTalkChannelConfiguration) async throws {
        try await performCommand { join(configuration) }
    }

    public func joinChannel(withID channelID: Int32, password: String = "") async throws {
        try await performCommand { joinChannel(withID: channelID, password: password) }
    }

    public func joinChannel(withID channelID: TeamTalkChannelID, password: String = "") async throws {
        try await performCommand { joinChannel(withID: channelID, password: password) }
    }

    public func joinChannel(_ channel: TeamTalkChannel, password: String = "") async throws {
        try await performCommand { joinChannel(channel, password: password) }
    }

    public func joinChannel(_ channel: Channel, password: String = "") async throws {
        try await performCommand { joinChannel(channel, password: password) }
    }

    public func leaveChannel() async throws {
        try await performCommand { leaveChannel() }
    }

    public func createChannel(_ configuration: TeamTalkChannelConfiguration) async throws {
        try await performCommand { createChannel(configuration) }
    }

    public func updateChannel(_ channel: TeamTalkChannel) async throws {
        try await performCommand { updateChannel(channel) }
    }

    public func updateChannel(_ configuration: TeamTalkChannelConfiguration) async throws {
        try await performCommand { updateChannel(configuration) }
    }

    public func removeChannel(withID channelID: Int32) async throws {
        try await performCommand { removeChannel(withID: channelID) }
    }

    public func removeChannel(withID channelID: TeamTalkChannelID) async throws {
        try await performCommand { removeChannel(withID: channelID) }
    }

    public func removeChannel(_ channel: TeamTalkChannel) async throws {
        try await performCommand { removeChannel(channel) }
    }

    public func removeChannel(_ channel: Channel) async throws {
        try await performCommand { removeChannel(channel) }
    }

    public func kickUser(withID userID: Int32, fromChannelID channelID: Int32 = 0) async throws {
        try await performCommand { kickUser(withID: userID, fromChannelID: channelID) }
    }

    public func kickUser(withID userID: TeamTalkUserID, fromChannelID channelID: TeamTalkChannelID = .none) async throws {
        try await performCommand { kickUser(withID: userID, fromChannelID: channelID) }
    }

    public func kickUser(_ user: TeamTalkUser, fromChannel channel: TeamTalkChannel? = nil) async throws {
        try await performCommand { kickUser(user, fromChannel: channel) }
    }

    public func kickUser(_ user: User, fromChannel channel: Channel? = nil) async throws {
        try await performCommand { kickUser(user, fromChannel: channel) }
    }

    public func banUser(withID userID: Int32, fromChannelID channelID: Int32 = 0) async throws {
        try await performCommand { banUser(withID: userID, fromChannelID: channelID) }
    }

    public func banUser(withID userID: TeamTalkUserID, fromChannelID channelID: TeamTalkChannelID = .none) async throws {
        try await performCommand { banUser(withID: userID, fromChannelID: channelID) }
    }

    public func banUser(_ user: TeamTalkUser, fromChannel channel: TeamTalkChannel? = nil) async throws {
        try await performCommand { banUser(user, fromChannel: channel) }
    }

    public func banUser(_ user: User, fromChannel channel: Channel? = nil) async throws {
        try await performCommand { banUser(user, fromChannel: channel) }
    }

    public func banUser(withID userID: Int32, types: TeamTalkBanTypes) async throws {
        try await performCommand { banUser(withID: userID, types: types) }
    }

    public func banUser(withID userID: TeamTalkUserID, types: TeamTalkBanTypes) async throws {
        try await performCommand { banUser(withID: userID, types: types) }
    }

    public func banUser(_ user: TeamTalkUser, types: TeamTalkBanTypes) async throws {
        try await performCommand { banUser(user, types: types) }
    }

    public func banUser(_ user: User, types: TeamTalkBanTypes) async throws {
        try await performCommand { banUser(user, types: types) }
    }

    public func moveUser(withID userID: Int32, toChannelID channelID: Int32) async throws {
        try await performCommand { moveUser(withID: userID, toChannelID: channelID) }
    }

    public func moveUser(withID userID: TeamTalkUserID, toChannelID channelID: TeamTalkChannelID) async throws {
        try await performCommand { moveUser(withID: userID, toChannelID: channelID) }
    }

    public func moveUser(_ user: TeamTalkUser, to channel: TeamTalkChannel) async throws {
        try await performCommand { moveUser(user, to: channel) }
    }

    public func moveUser(_ user: User, to channel: Channel) async throws {
        try await performCommand { moveUser(user, to: channel) }
    }

    public func sendTextMessage(_ message: TeamTalkOutgoingTextMessage) async throws {
        try await performCommands { sendTextMessage(message) }
    }

    public func sendTextMessage(_ message: TextMessage, content: String) async throws {
        let outgoing = TeamTalkOutgoingTextMessage(
            type: TeamTalkTextMessageType(rawValue: message.nMsgType),
            toUserID: message.nToUserID,
            channelID: message.nChannelID,
            content: content
        )
        try await sendTextMessage(outgoing)
    }

    public func uploadFile(at localURL: URL, toChannelID channelID: Int32) async throws {
        try await performCommand { uploadFileCommand(at: localURL, toChannelID: channelID) }
    }

    public func uploadFile(at localURL: URL, toChannelID channelID: TeamTalkChannelID) async throws {
        try await performCommand { uploadFileCommand(at: localURL, toChannelID: channelID) }
    }

    public func uploadFile(at localURL: URL, toChannel channel: Channel) async throws {
        try await performCommand { uploadFileCommand(at: localURL, toChannel: channel) }
    }

    public func uploadFile(at localURL: URL, to channel: TeamTalkChannel) async throws {
        try await performCommand { uploadFile(at: localURL, to: channel) }
    }

    public func downloadFile(channelID: Int32, fileID: Int32, to localURL: URL) async throws {
        try await performCommand { downloadFileCommand(channelID: channelID, fileID: fileID, to: localURL) }
    }

    public func downloadFile(channelID: TeamTalkChannelID, fileID: TeamTalkFileID, to localURL: URL) async throws {
        try await performCommand { downloadFileCommand(channelID: channelID, fileID: fileID, to: localURL) }
    }

    public func downloadFile(_ file: RemoteFile, to localURL: URL) async throws {
        try await performCommand { downloadFileCommand(file, to: localURL) }
    }

    public func downloadFile(_ file: TeamTalkRemoteFile, to localURL: URL) async throws {
        try await performCommand { downloadFileCommand(file, to: localURL) }
    }

    public func deleteFile(channelID: Int32, fileID: Int32) async throws {
        try await performCommand { deleteFileCommand(channelID: channelID, fileID: fileID) }
    }

    public func deleteFile(channelID: TeamTalkChannelID, fileID: TeamTalkFileID) async throws {
        try await performCommand { deleteFileCommand(channelID: channelID, fileID: fileID) }
    }

    public func deleteFile(_ file: RemoteFile) async throws {
        try await performCommand { deleteFileCommand(file) }
    }

    public func deleteFile(_ file: TeamTalkRemoteFile) async throws {
        try await performCommand { deleteFileCommand(file) }
    }
}
