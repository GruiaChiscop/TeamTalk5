import Foundation
import TeamTalkC

public struct TeamTalkChannel: Identifiable {
    public let rawValue: Channel

    public init(_ rawValue: Channel) {
        self.rawValue = rawValue
    }

    public var cValue: Channel {
        rawValue
    }

    public var id: Int32 {
        rawValue.id
    }

    public var channelID: TeamTalkChannelID {
        TeamTalkChannelID(id)
    }

    public var parentID: Int32 {
        rawValue.parentID
    }

    public var parentChannelID: TeamTalkChannelID {
        TeamTalkChannelID(parentID)
    }

    public var name: String {
        rawValue.name
    }

    public var topic: String {
        rawValue.topic
    }

    public var password: String {
        rawValue.password
    }

    public var operatorPassword: String {
        rawValue.operatorPassword
    }

    public var types: TeamTalkChannelTypes {
        rawValue.types
    }

    public var userData: Int32 {
        rawValue.nUserData
    }

    public var diskQuota: Int64 {
        rawValue.nDiskQuota
    }

    public var maxUsers: Int32 {
        rawValue.nMaxUsers
    }

    public var audioCodecType: TeamTalkCodec {
        rawValue.audioCodecType
    }

    public var transmitUsers: [TeamTalkChannelTransmitUser] {
        rawValue.transmitUserList
    }

    public var transmitUsersQueue: [TeamTalkUserID] {
        rawValue.transmitQueueUsers
    }

    public var transmitUsersQueueDelayMilliseconds: Int32 {
        rawValue.transmitQueueDelayMilliseconds
    }

    public var voiceTimeoutMilliseconds: Int32 {
        rawValue.voiceTimeoutMilliseconds
    }

    public var mediaFileTimeoutMilliseconds: Int32 {
        rawValue.mediaFileTimeoutMilliseconds
    }

    public var isRoot: Bool {
        rawValue.isRoot
    }

    public var isPasswordProtected: Bool {
        rawValue.isPasswordProtected
    }
}

public struct TeamTalkChannelConfiguration {
    public var id: Int32
    public var parentID: Int32
    public var name: String
    public var topic: String
    public var password: String
    public var operatorPassword: String
    public var types: TeamTalkChannelTypes
    public var userData: Int32
    public var diskQuota: Int64
    public var maxUsers: Int32
    public var audioCodec: AudioCodec
    public var transmitUsers: [TeamTalkChannelTransmitUser]
    public var transmitUsersQueueDelayMilliseconds: Int32
    public var voiceTimeoutMilliseconds: Int32
    public var mediaFileTimeoutMilliseconds: Int32

    public init(
        id: Int32 = 0,
        parentID: Int32,
        name: String,
        topic: String = "",
        password: String = "",
        operatorPassword: String = "",
        types: TeamTalkChannelTypes = .default,
        userData: Int32 = 0,
        diskQuota: Int64 = 0,
        maxUsers: Int32 = 0,
        audioCodec: AudioCodec = TeamTalkAudioCodec.makeAudioCodec(.opus),
        transmitUsers: [TeamTalkChannelTransmitUser] = [],
        transmitUsersQueueDelayMilliseconds: Int32 = 500,
        voiceTimeoutMilliseconds: Int32 = 0,
        mediaFileTimeoutMilliseconds: Int32 = 0
    ) {
        self.id = id
        self.parentID = parentID
        self.name = name
        self.topic = topic
        self.password = password
        self.operatorPassword = operatorPassword
        self.types = types
        self.userData = userData
        self.diskQuota = diskQuota
        self.maxUsers = maxUsers
        self.audioCodec = audioCodec
        self.transmitUsers = transmitUsers
        self.transmitUsersQueueDelayMilliseconds = transmitUsersQueueDelayMilliseconds
        self.voiceTimeoutMilliseconds = voiceTimeoutMilliseconds
        self.mediaFileTimeoutMilliseconds = mediaFileTimeoutMilliseconds
    }

    public init(
        channelID: TeamTalkChannelID = .none,
        parentChannelID: TeamTalkChannelID,
        name: String,
        topic: String = "",
        password: String = "",
        operatorPassword: String = "",
        types: TeamTalkChannelTypes = .default,
        userData: Int32 = 0,
        diskQuota: Int64 = 0,
        maxUsers: Int32 = 0,
        audioCodec: AudioCodec = TeamTalkAudioCodec.makeAudioCodec(.opus),
        transmitUsers: [TeamTalkChannelTransmitUser] = [],
        transmitUsersQueueDelayMilliseconds: Int32 = 500,
        voiceTimeoutMilliseconds: Int32 = 0,
        mediaFileTimeoutMilliseconds: Int32 = 0
    ) {
        self.init(
            id: channelID.cValue,
            parentID: parentChannelID.cValue,
            name: name,
            topic: topic,
            password: password,
            operatorPassword: operatorPassword,
            types: types,
            userData: userData,
            diskQuota: diskQuota,
            maxUsers: maxUsers,
            audioCodec: audioCodec,
            transmitUsers: transmitUsers,
            transmitUsersQueueDelayMilliseconds: transmitUsersQueueDelayMilliseconds,
            voiceTimeoutMilliseconds: voiceTimeoutMilliseconds,
            mediaFileTimeoutMilliseconds: mediaFileTimeoutMilliseconds
        )
    }

    public init(_ channel: TeamTalkChannel) {
        self.init(
            id: channel.id,
            parentID: channel.parentID,
            name: channel.name,
            topic: channel.topic,
            password: channel.password,
            operatorPassword: channel.operatorPassword,
            types: channel.types,
            userData: channel.userData,
            diskQuota: channel.diskQuota,
            maxUsers: channel.maxUsers,
            audioCodec: channel.rawValue.audiocodec,
            transmitUsers: channel.transmitUsers,
            transmitUsersQueueDelayMilliseconds: channel.transmitUsersQueueDelayMilliseconds,
            voiceTimeoutMilliseconds: channel.voiceTimeoutMilliseconds,
            mediaFileTimeoutMilliseconds: channel.mediaFileTimeoutMilliseconds
        )
    }

    public var cValue: Channel {
        var channel = Channel()
        channel.nChannelID = id
        channel.nParentID = parentID
        TeamTalkString.setChannel(.name, on: &channel, to: name)
        TeamTalkString.setChannel(.topic, on: &channel, to: topic)
        TeamTalkString.setChannel(.password, on: &channel, to: password)
        TeamTalkString.setChannel(.operatorPassword, on: &channel, to: operatorPassword)
        channel.bPassword = password.isEmpty ? 0 : 1
        channel.types = types
        channel.nUserData = userData
        channel.nDiskQuota = diskQuota
        channel.nMaxUsers = maxUsers
        channel.audiocodec = audioCodec
        channel.transmitUserList = transmitUsers
        channel.transmitQueueDelayMilliseconds = transmitUsersQueueDelayMilliseconds
        channel.voiceTimeoutMilliseconds = voiceTimeoutMilliseconds
        channel.mediaFileTimeoutMilliseconds = mediaFileTimeoutMilliseconds
        return channel
    }
}
