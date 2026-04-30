import Foundation
import TeamTalkC

public struct TeamTalkFileTransfer: Identifiable {
    public let rawValue: FileTransfer

    public init(_ rawValue: FileTransfer) {
        self.rawValue = rawValue
    }

    public var cValue: FileTransfer {
        rawValue
    }

    public var id: Int32 {
        rawValue.id
    }

    public var transferID: TeamTalkTransferID {
        TeamTalkTransferID(id)
    }

    public var channelID: Int32 {
        rawValue.channelID
    }

    public var channelIdentifier: TeamTalkChannelID {
        TeamTalkChannelID(channelID)
    }

    public var status: TeamTalkFileTransferStatus {
        rawValue.status
    }

    public var localFilePath: String {
        rawValue.localFilePath
    }

    public var remoteFileName: String {
        rawValue.remoteFileName
    }

    public var fileSize: Int64 {
        rawValue.nFileSize
    }

    public var transferredBytes: Int64 {
        rawValue.nTransferred
    }

    public var isDownload: Bool {
        rawValue.isDownload
    }

    public var progress: Double {
        rawValue.progress
    }
}

public struct TeamTalkTextMessage {
    public let rawValue: TextMessage

    public init(_ rawValue: TextMessage) {
        self.rawValue = rawValue
    }

    public var cValue: TextMessage {
        rawValue
    }

    public var type: TeamTalkTextMessageType {
        rawValue.type
    }

    public var fromUserID: Int32 {
        rawValue.nFromUserID
    }

    public var fromUserIdentifier: TeamTalkUserID {
        TeamTalkUserID(fromUserID)
    }

    public var toUserID: Int32 {
        rawValue.nToUserID
    }

    public var toUserIdentifier: TeamTalkUserID {
        TeamTalkUserID(toUserID)
    }

    public var channelID: Int32 {
        rawValue.nChannelID
    }

    public var channelIdentifier: TeamTalkChannelID {
        TeamTalkChannelID(channelID)
    }

    public var content: String {
        rawValue.content
    }

    public var hasMoreContent: Bool {
        rawValue.bMore != 0
    }
}

public struct TeamTalkTextMessageMultipartKey: Hashable, Sendable {
    public let type: TeamTalkTextMessageType
    public let fromUserID: TeamTalkUserID

    public init(type: TeamTalkTextMessageType, fromUserID: TeamTalkUserID) {
        self.type = type
        self.fromUserID = fromUserID
    }

    public init(_ message: TeamTalkTextMessage) {
        self.init(type: message.type, fromUserID: message.fromUserIdentifier)
    }
}

public struct TeamTalkTextMessageAssembler {
    private var messageFragments = [TeamTalkTextMessageMultipartKey: [String]]()

    public init() {}

    public mutating func append(_ message: TeamTalkTextMessage) -> String? {
        let key = TeamTalkTextMessageMultipartKey(message)

        if message.hasMoreContent {
            if messageFragments[key] == nil {
                messageFragments[key] = []
            }
            messageFragments[key]?.append(message.content)
            if messageFragments[key]?.count ?? 0 > 1000 {
                messageFragments.removeValue(forKey: key)
            }
            return nil
        }

        guard let fragments = messageFragments.removeValue(forKey: key), !fragments.isEmpty else {
            return message.content
        }

        return fragments.joined() + message.content
    }

    public mutating func clear() {
        messageFragments.removeAll()
    }
}

public struct TeamTalkOutgoingTextMessage {
    public var type: TeamTalkTextMessageType
    public var toUserID: Int32
    public var channelID: Int32
    public var content: String

    public init(
        type: TeamTalkTextMessageType,
        toUserID: Int32 = 0,
        channelID: Int32 = 0,
        content: String
    ) {
        self.type = type
        self.toUserID = toUserID
        self.channelID = channelID
        self.content = content
    }

    public static func user(to userID: Int32, content: String) -> TeamTalkOutgoingTextMessage {
        TeamTalkOutgoingTextMessage(type: .user, toUserID: userID, content: content)
    }

    public static func user(to userID: TeamTalkUserID, content: String) -> TeamTalkOutgoingTextMessage {
        user(to: userID.cValue, content: content)
    }

    public static func user(to user: User, content: String) -> TeamTalkOutgoingTextMessage {
        TeamTalkOutgoingTextMessage.user(to: user.userID, content: content)
    }

    public static func user(to user: TeamTalkUser, content: String) -> TeamTalkOutgoingTextMessage {
        TeamTalkOutgoingTextMessage.user(to: user.userID, content: content)
    }

    public static func channel(_ channelID: Int32, content: String) -> TeamTalkOutgoingTextMessage {
        TeamTalkOutgoingTextMessage(type: .channel, channelID: channelID, content: content)
    }

    public static func channel(_ channelID: TeamTalkChannelID, content: String) -> TeamTalkOutgoingTextMessage {
        channel(channelID.cValue, content: content)
    }

    public static func channel(_ channel: Channel, content: String) -> TeamTalkOutgoingTextMessage {
        TeamTalkOutgoingTextMessage.channel(channel.channelID, content: content)
    }

    public static func channel(_ channel: TeamTalkChannel, content: String) -> TeamTalkOutgoingTextMessage {
        TeamTalkOutgoingTextMessage.channel(channel.channelID, content: content)
    }

    public static func broadcast(content: String) -> TeamTalkOutgoingTextMessage {
        TeamTalkOutgoingTextMessage(type: .broadcast, content: content)
    }

    public var toUserIdentifier: TeamTalkUserID {
        get { TeamTalkUserID(toUserID) }
        set { toUserID = newValue.cValue }
    }

    public var channelIdentifier: TeamTalkChannelID {
        get { TeamTalkChannelID(channelID) }
        set { channelID = newValue.cValue }
    }

    public var cValue: TextMessage {
        var message = TextMessage()
        message.type = type
        message.nToUserID = toUserID
        message.nChannelID = channelID
        TeamTalkString.setTextMessage(&message, to: content)
        return message
    }
}

public struct TeamTalkClientError {
    public let rawValue: ClientErrorMsg

    public init(_ rawValue: ClientErrorMsg) {
        self.rawValue = rawValue
    }

    public var cValue: ClientErrorMsg {
        rawValue
    }

    public var code: Int32 {
        rawValue.nErrorNo
    }

    public var errorCode: TeamTalkErrorCode {
        TeamTalkErrorCode(rawValue: code)
    }

    public var message: String {
        TeamTalkString.clientError(rawValue)
    }
}
