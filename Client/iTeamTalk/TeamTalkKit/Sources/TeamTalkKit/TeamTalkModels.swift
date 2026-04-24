import Foundation
import TeamTalkC

public struct TeamTalkUser: Identifiable {
    public let rawValue: User

    public init(_ rawValue: User) {
        self.rawValue = rawValue
    }

    public var cValue: User {
        rawValue
    }

    public var id: Int32 {
        rawValue.id
    }

    public var userID: TeamTalkUserID {
        TeamTalkUserID(id)
    }

    public var channelID: Int32 {
        rawValue.channelID
    }

    public var channelIdentifier: TeamTalkChannelID {
        TeamTalkChannelID(channelID)
    }

    public var username: String {
        rawValue.username
    }

    public var nickname: String {
        rawValue.nickname
    }

    public var statusMessage: String {
        rawValue.statusMessage
    }

    public var ipAddress: String {
        rawValue.ipAddress
    }

    public var clientName: String {
        rawValue.clientName
    }

    public var types: TeamTalkUserTypes {
        rawValue.types
    }

    public var localSubscriptions: TeamTalkSubscriptions {
        rawValue.localSubscriptions
    }

    public var peerSubscriptions: TeamTalkSubscriptions {
        rawValue.peerSubscriptions
    }

    public var statusMode: TeamTalkStatusMode {
        rawValue.statusMode
    }

    public var states: TeamTalkUserStates {
        rawValue.states
    }

    public var isAdministrator: Bool {
        rawValue.isAdministrator
    }

    public var isInChannel: Bool {
        rawValue.isInChannel
    }

    public func hasUserType(_ type: TeamTalkUserTypes) -> Bool {
        rawValue.hasUserType(type)
    }

    public func hasSubscription(_ subscription: TeamTalkSubscriptions) -> Bool {
        rawValue.hasSubscription(subscription)
    }

    public func hasPeerSubscription(_ subscription: TeamTalkSubscriptions) -> Bool {
        rawValue.hasPeerSubscription(subscription)
    }

    public func hasState(_ state: TeamTalkUserStates) -> Bool {
        rawValue.hasState(state)
    }
}

public struct TeamTalkUserAccount {
    public let rawValue: UserAccount

    public init(_ rawValue: UserAccount) {
        self.rawValue = rawValue
    }

    public var cValue: UserAccount {
        rawValue
    }

    public var username: String {
        rawValue.username
    }

    public var initialChannel: String {
        rawValue.initialChannel
    }

    public var note: String {
        rawValue.note
    }

    public var password: String {
        rawValue.password
    }

    public var lastModified: String {
        rawValue.lastModified
    }

    public var lastLoginTime: String {
        rawValue.lastLoginTime
    }

    public var types: TeamTalkUserTypes {
        rawValue.types
    }

    public var rights: TeamTalkUserRights {
        rawValue.rights
    }

    public var userData: Int32 {
        rawValue.nUserData
    }

    public var audioCodecBitrateLimit: Int32 {
        rawValue.nAudioCodecBpsLimit
    }

    public var autoOperatorChannelIDs: [Int32] {
        rawValue.autoOperatorChannelIDs
    }

    public var commandLimit: Int32 {
        rawValue.commandLimit
    }

    public var commandIntervalMilliseconds: Int32 {
        rawValue.commandIntervalMilliseconds
    }

    public var isAdministrator: Bool {
        rawValue.isAdministrator
    }

    public func getUserRight(_ right: TeamTalkUserRights) -> Bool {
        rawValue.getUserRight(right)
    }

    public func hasUserRight(_ right: TeamTalkUserRights) -> Bool {
        rawValue.hasUserRight(right)
    }
}

public struct TeamTalkUserAccountConfiguration {
    public var username: String
    public var password: String
    public var types: TeamTalkUserTypes
    public var rights: TeamTalkUserRights
    public var userData: Int32
    public var note: String
    public var initialChannel: String
    public var autoOperatorChannelIDs: [Int32]
    public var audioCodecBitrateLimit: Int32
    public var commandLimit: Int32
    public var commandIntervalMilliseconds: Int32

    public init(
        username: String,
        password: String = "",
        types: TeamTalkUserTypes = .defaultUser,
        rights: TeamTalkUserRights = .none,
        userData: Int32 = 0,
        note: String = "",
        initialChannel: String = "",
        autoOperatorChannelIDs: [Int32] = [],
        audioCodecBitrateLimit: Int32 = 0,
        commandLimit: Int32 = 0,
        commandIntervalMilliseconds: Int32 = 0
    ) {
        self.username = username
        self.password = password
        self.types = types
        self.rights = rights
        self.userData = userData
        self.note = note
        self.initialChannel = initialChannel
        self.autoOperatorChannelIDs = autoOperatorChannelIDs
        self.audioCodecBitrateLimit = audioCodecBitrateLimit
        self.commandLimit = commandLimit
        self.commandIntervalMilliseconds = commandIntervalMilliseconds
    }

    public init(_ account: TeamTalkUserAccount, password: String = "") {
        self.init(
            username: account.username,
            password: password,
            types: account.types,
            rights: account.rights,
            userData: account.userData,
            note: account.note,
            initialChannel: account.initialChannel,
            autoOperatorChannelIDs: account.autoOperatorChannelIDs,
            audioCodecBitrateLimit: account.audioCodecBitrateLimit,
            commandLimit: account.commandLimit,
            commandIntervalMilliseconds: account.commandIntervalMilliseconds
        )
    }

    public var cValue: UserAccount {
        var account = UserAccount()
        TeamTalkString.setUserAccount(.username, on: &account, to: username)
        TeamTalkString.setUserAccount(.password, on: &account, to: password)
        TeamTalkString.setUserAccount(.note, on: &account, to: note)
        TeamTalkString.setUserAccount(.initialChannel, on: &account, to: initialChannel)
        account.types = types
        account.rights = rights
        account.nUserData = userData
        account.nAudioCodecBpsLimit = audioCodecBitrateLimit
        account.commandLimit = commandLimit
        account.commandIntervalMilliseconds = commandIntervalMilliseconds
        autoOperatorChannelIDs.withUnsafeBufferPointer { buffer in
            TTKitSetUserAccountAutoOperatorChannels(&account, buffer.baseAddress, Int32(buffer.count))
        }
        return account
    }
}

public struct TeamTalkServerProperties {
    public let rawValue: ServerProperties

    public init(_ rawValue: ServerProperties) {
        self.rawValue = rawValue
    }

    public var cValue: ServerProperties {
        rawValue
    }

    public var name: String {
        rawValue.name
    }

    public var messageOfTheDay: String {
        rawValue.messageOfTheDay
    }

    public var rawMessageOfTheDay: String {
        rawValue.rawMessageOfTheDay
    }

    public var version: String {
        rawValue.version
    }

    public var protocolVersion: String {
        rawValue.protocolVersion
    }

    public var accessToken: String {
        rawValue.accessToken
    }

    public var maxUsers: Int32 {
        rawValue.nMaxUsers
    }

    public var maxLoginAttempts: Int32 {
        rawValue.nMaxLoginAttempts
    }

    public var maxLoginsPerIPAddress: Int32 {
        rawValue.nMaxLoginsPerIPAddress
    }

    public var maxVoiceTransmissionBytesPerSecond: Int32 {
        rawValue.nMaxVoiceTxPerSecond
    }

    public var maxVideoCaptureTransmissionBytesPerSecond: Int32 {
        rawValue.nMaxVideoCaptureTxPerSecond
    }

    public var maxMediaFileTransmissionBytesPerSecond: Int32 {
        rawValue.nMaxMediaFileTxPerSecond
    }

    public var maxDesktopTransmissionBytesPerSecond: Int32 {
        rawValue.nMaxDesktopTxPerSecond
    }

    public var maxTotalTransmissionBytesPerSecond: Int32 {
        rawValue.nMaxTotalTxPerSecond
    }

    public var tcpPort: Int32 {
        rawValue.nTcpPort
    }

    public var udpPort: Int32 {
        rawValue.nUdpPort
    }

    public var userTimeout: Int32 {
        rawValue.nUserTimeout
    }

    public var loginDelayMilliseconds: Int32 {
        rawValue.nLoginDelayMSec
    }

    public var logEvents: TeamTalkServerLogEvents {
        rawValue.logEvents
    }

    public var autoSave: Bool {
        rawValue.autoSave
    }
}

public struct TeamTalkServerPropertiesConfiguration {
    public var name: String
    public var rawMessageOfTheDay: String
    public var maxUsers: Int32
    public var maxLoginAttempts: Int32
    public var maxLoginsPerIPAddress: Int32
    public var maxVoiceTransmissionBytesPerSecond: Int32
    public var maxVideoCaptureTransmissionBytesPerSecond: Int32
    public var maxMediaFileTransmissionBytesPerSecond: Int32
    public var maxDesktopTransmissionBytesPerSecond: Int32
    public var maxTotalTransmissionBytesPerSecond: Int32
    public var tcpPort: Int32
    public var udpPort: Int32
    public var userTimeout: Int32
    public var loginDelayMilliseconds: Int32
    public var logEvents: TeamTalkServerLogEvents
    public var autoSave: Bool

    public init(
        name: String = "",
        rawMessageOfTheDay: String = "",
        maxUsers: Int32 = 0,
        maxLoginAttempts: Int32 = 0,
        maxLoginsPerIPAddress: Int32 = 0,
        maxVoiceTransmissionBytesPerSecond: Int32 = 0,
        maxVideoCaptureTransmissionBytesPerSecond: Int32 = 0,
        maxMediaFileTransmissionBytesPerSecond: Int32 = 0,
        maxDesktopTransmissionBytesPerSecond: Int32 = 0,
        maxTotalTransmissionBytesPerSecond: Int32 = 0,
        tcpPort: Int32 = 0,
        udpPort: Int32 = 0,
        userTimeout: Int32 = 0,
        loginDelayMilliseconds: Int32 = 0,
        logEvents: TeamTalkServerLogEvents = .none,
        autoSave: Bool = false
    ) {
        self.name = name
        self.rawMessageOfTheDay = rawMessageOfTheDay
        self.maxUsers = maxUsers
        self.maxLoginAttempts = maxLoginAttempts
        self.maxLoginsPerIPAddress = maxLoginsPerIPAddress
        self.maxVoiceTransmissionBytesPerSecond = maxVoiceTransmissionBytesPerSecond
        self.maxVideoCaptureTransmissionBytesPerSecond = maxVideoCaptureTransmissionBytesPerSecond
        self.maxMediaFileTransmissionBytesPerSecond = maxMediaFileTransmissionBytesPerSecond
        self.maxDesktopTransmissionBytesPerSecond = maxDesktopTransmissionBytesPerSecond
        self.maxTotalTransmissionBytesPerSecond = maxTotalTransmissionBytesPerSecond
        self.tcpPort = tcpPort
        self.udpPort = udpPort
        self.userTimeout = userTimeout
        self.loginDelayMilliseconds = loginDelayMilliseconds
        self.logEvents = logEvents
        self.autoSave = autoSave
    }

    public init(_ properties: TeamTalkServerProperties) {
        self.init(
            name: properties.name,
            rawMessageOfTheDay: properties.rawMessageOfTheDay,
            maxUsers: properties.maxUsers,
            maxLoginAttempts: properties.maxLoginAttempts,
            maxLoginsPerIPAddress: properties.maxLoginsPerIPAddress,
            maxVoiceTransmissionBytesPerSecond: properties.maxVoiceTransmissionBytesPerSecond,
            maxVideoCaptureTransmissionBytesPerSecond: properties.maxVideoCaptureTransmissionBytesPerSecond,
            maxMediaFileTransmissionBytesPerSecond: properties.maxMediaFileTransmissionBytesPerSecond,
            maxDesktopTransmissionBytesPerSecond: properties.maxDesktopTransmissionBytesPerSecond,
            maxTotalTransmissionBytesPerSecond: properties.maxTotalTransmissionBytesPerSecond,
            tcpPort: properties.tcpPort,
            udpPort: properties.udpPort,
            userTimeout: properties.userTimeout,
            loginDelayMilliseconds: properties.loginDelayMilliseconds,
            logEvents: properties.logEvents,
            autoSave: properties.autoSave
        )
    }

    public var cValue: ServerProperties {
        var properties = ServerProperties()
        TeamTalkString.setServerProperties(.name, on: &properties, to: name)
        TeamTalkString.setServerProperties(.rawMessageOfTheDay, on: &properties, to: rawMessageOfTheDay)
        properties.nMaxUsers = maxUsers
        properties.nMaxLoginAttempts = maxLoginAttempts
        properties.nMaxLoginsPerIPAddress = maxLoginsPerIPAddress
        properties.nMaxVoiceTxPerSecond = maxVoiceTransmissionBytesPerSecond
        properties.nMaxVideoCaptureTxPerSecond = maxVideoCaptureTransmissionBytesPerSecond
        properties.nMaxMediaFileTxPerSecond = maxMediaFileTransmissionBytesPerSecond
        properties.nMaxDesktopTxPerSecond = maxDesktopTransmissionBytesPerSecond
        properties.nMaxTotalTxPerSecond = maxTotalTransmissionBytesPerSecond
        properties.nTcpPort = tcpPort
        properties.nUdpPort = udpPort
        properties.nUserTimeout = userTimeout
        properties.nLoginDelayMSec = loginDelayMilliseconds
        properties.logEvents = logEvents
        properties.autoSave = autoSave
        return properties
    }
}

public struct TeamTalkServerStatistics {
    public let rawValue: ServerStatistics

    public init(_ rawValue: ServerStatistics) {
        self.rawValue = rawValue
    }

    public var cValue: ServerStatistics {
        rawValue
    }

    public var totalBytesTransmitted: Int64 { rawValue.nTotalBytesTX }
    public var totalBytesReceived: Int64 { rawValue.nTotalBytesRX }
    public var voiceBytesTransmitted: Int64 { rawValue.nVoiceBytesTX }
    public var voiceBytesReceived: Int64 { rawValue.nVoiceBytesRX }
    public var videoCaptureBytesTransmitted: Int64 { rawValue.nVideoCaptureBytesTX }
    public var videoCaptureBytesReceived: Int64 { rawValue.nVideoCaptureBytesRX }
    public var mediaFileBytesTransmitted: Int64 { rawValue.nMediaFileBytesTX }
    public var mediaFileBytesReceived: Int64 { rawValue.nMediaFileBytesRX }
    public var desktopBytesTransmitted: Int64 { rawValue.nDesktopBytesTX }
    public var desktopBytesReceived: Int64 { rawValue.nDesktopBytesRX }
    public var usersServed: Int32 { rawValue.nUsersServed }
    public var usersPeak: Int32 { rawValue.nUsersPeak }
    public var filesBytesTransmitted: Int64 { rawValue.nFilesTx }
    public var filesBytesReceived: Int64 { rawValue.nFilesRx }
    public var uptimeMilliseconds: Int64 { rawValue.nUptimeMSec }
}

public struct TeamTalkUserStatistics {
    public let rawValue: UserStatistics

    public init(_ rawValue: UserStatistics) {
        self.rawValue = rawValue
    }

    public var cValue: UserStatistics {
        rawValue
    }

    public var voicePacketsReceived: Int64 { rawValue.voicePacketsReceived }
    public var voicePacketsLost: Int64 { rawValue.voicePacketsLost }
    public var videoCapturePacketsReceived: Int64 { rawValue.videoCapturePacketsReceived }
    public var videoCaptureFramesReceived: Int64 { rawValue.videoCaptureFramesReceived }
    public var videoCaptureFramesLost: Int64 { rawValue.videoCaptureFramesLost }
    public var videoCaptureFramesDropped: Int64 { rawValue.videoCaptureFramesDropped }
    public var mediaFileAudioPacketsReceived: Int64 { rawValue.mediaFileAudioPacketsReceived }
    public var mediaFileAudioPacketsLost: Int64 { rawValue.mediaFileAudioPacketsLost }
    public var mediaFileVideoPacketsReceived: Int64 { rawValue.mediaFileVideoPacketsReceived }
    public var mediaFileVideoFramesReceived: Int64 { rawValue.mediaFileVideoFramesReceived }
    public var mediaFileVideoFramesLost: Int64 { rawValue.mediaFileVideoFramesLost }
    public var mediaFileVideoFramesDropped: Int64 { rawValue.mediaFileVideoFramesDropped }
}

public struct TeamTalkClientStatistics {
    public let rawValue: ClientStatistics

    public init(_ rawValue: ClientStatistics) {
        self.rawValue = rawValue
    }

    public var cValue: ClientStatistics {
        rawValue
    }

    public var udpBytesSent: Int64 { rawValue.udpBytesSent }
    public var udpBytesReceived: Int64 { rawValue.udpBytesReceived }
    public var voiceBytesSent: Int64 { rawValue.voiceBytesSent }
    public var voiceBytesReceived: Int64 { rawValue.voiceBytesReceived }
    public var videoCaptureBytesSent: Int64 { rawValue.videoCaptureBytesSent }
    public var videoCaptureBytesReceived: Int64 { rawValue.videoCaptureBytesReceived }
    public var mediaFileAudioBytesSent: Int64 { rawValue.mediaFileAudioBytesSent }
    public var mediaFileAudioBytesReceived: Int64 { rawValue.mediaFileAudioBytesReceived }
    public var mediaFileVideoBytesSent: Int64 { rawValue.mediaFileVideoBytesSent }
    public var mediaFileVideoBytesReceived: Int64 { rawValue.mediaFileVideoBytesReceived }
    public var desktopBytesSent: Int64 { rawValue.desktopBytesSent }
    public var desktopBytesReceived: Int64 { rawValue.desktopBytesReceived }
    public var udpPingTimeMilliseconds: Int32? { rawValue.udpPingTimeMilliseconds }
    public var tcpPingTimeMilliseconds: Int32? { rawValue.tcpPingTimeMilliseconds }
    public var tcpServerSilenceSeconds: Int32 { rawValue.tcpServerSilenceSeconds }
    public var udpServerSilenceSeconds: Int32 { rawValue.udpServerSilenceSeconds }
    public var soundInputDeviceDelayMilliseconds: Int32 { rawValue.soundInputDeviceDelayMilliseconds }
}

public struct TeamTalkClientKeepAlive {
    public let rawValue: ClientKeepAlive

    public init(_ rawValue: ClientKeepAlive) {
        self.rawValue = rawValue
    }

    public var cValue: ClientKeepAlive {
        rawValue
    }

    public var connectionLostMilliseconds: Int32 { rawValue.connectionLostMilliseconds }
    public var tcpKeepAliveIntervalMilliseconds: Int32 { rawValue.tcpKeepAliveIntervalMilliseconds }
    public var udpKeepAliveIntervalMilliseconds: Int32 { rawValue.udpKeepAliveIntervalMilliseconds }
    public var udpKeepAliveRetransmitMilliseconds: Int32 { rawValue.udpKeepAliveRetransmitMilliseconds }
    public var udpConnectRetransmitMilliseconds: Int32 { rawValue.udpConnectRetransmitMilliseconds }
    public var udpConnectTimeoutMilliseconds: Int32 { rawValue.udpConnectTimeoutMilliseconds }
}

public struct TeamTalkClientKeepAliveConfiguration {
    public var connectionLostMilliseconds: Int32
    public var tcpKeepAliveIntervalMilliseconds: Int32
    public var udpKeepAliveIntervalMilliseconds: Int32
    public var udpKeepAliveRetransmitMilliseconds: Int32
    public var udpConnectRetransmitMilliseconds: Int32
    public var udpConnectTimeoutMilliseconds: Int32

    public init(
        connectionLostMilliseconds: Int32,
        tcpKeepAliveIntervalMilliseconds: Int32 = 0,
        udpKeepAliveIntervalMilliseconds: Int32 = 0,
        udpKeepAliveRetransmitMilliseconds: Int32 = 0,
        udpConnectRetransmitMilliseconds: Int32 = 0,
        udpConnectTimeoutMilliseconds: Int32 = 0
    ) {
        self.connectionLostMilliseconds = connectionLostMilliseconds
        self.tcpKeepAliveIntervalMilliseconds = tcpKeepAliveIntervalMilliseconds
        self.udpKeepAliveIntervalMilliseconds = udpKeepAliveIntervalMilliseconds
        self.udpKeepAliveRetransmitMilliseconds = udpKeepAliveRetransmitMilliseconds
        self.udpConnectRetransmitMilliseconds = udpConnectRetransmitMilliseconds
        self.udpConnectTimeoutMilliseconds = udpConnectTimeoutMilliseconds
    }

    public init(_ keepAlive: TeamTalkClientKeepAlive) {
        self.init(
            connectionLostMilliseconds: keepAlive.connectionLostMilliseconds,
            tcpKeepAliveIntervalMilliseconds: keepAlive.tcpKeepAliveIntervalMilliseconds,
            udpKeepAliveIntervalMilliseconds: keepAlive.udpKeepAliveIntervalMilliseconds,
            udpKeepAliveRetransmitMilliseconds: keepAlive.udpKeepAliveRetransmitMilliseconds,
            udpConnectRetransmitMilliseconds: keepAlive.udpConnectRetransmitMilliseconds,
            udpConnectTimeoutMilliseconds: keepAlive.udpConnectTimeoutMilliseconds
        )
    }

    public var cValue: ClientKeepAlive {
        var keepAlive = ClientKeepAlive()
        keepAlive.connectionLostMilliseconds = connectionLostMilliseconds
        keepAlive.tcpKeepAliveIntervalMilliseconds = tcpKeepAliveIntervalMilliseconds
        keepAlive.udpKeepAliveIntervalMilliseconds = udpKeepAliveIntervalMilliseconds
        keepAlive.udpKeepAliveRetransmitMilliseconds = udpKeepAliveRetransmitMilliseconds
        keepAlive.udpConnectRetransmitMilliseconds = udpConnectRetransmitMilliseconds
        keepAlive.udpConnectTimeoutMilliseconds = udpConnectTimeoutMilliseconds
        return keepAlive
    }
}

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

    public var isRoot: Bool {
        rawValue.isRoot
    }

    public var isPasswordProtected: Bool {
        rawValue.isPasswordProtected
    }

    public func hasChannelType(_ type: TeamTalkChannelTypes) -> Bool {
        rawValue.hasChannelType(type)
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
        audioCodec: AudioCodec = TeamTalkAudioCodec.makeAudioCodec(.opus)
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
        audioCodec: AudioCodec = TeamTalkAudioCodec.makeAudioCodec(.opus)
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
            audioCodec: audioCodec
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
            audioCodec: channel.rawValue.audiocodec
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
        return channel
    }
}

public struct TeamTalkRemoteFile: Identifiable {
    public let rawValue: RemoteFile

    public init(_ rawValue: RemoteFile) {
        self.rawValue = rawValue
    }

    public var cValue: RemoteFile {
        rawValue
    }

    public var id: Int32 {
        rawValue.id
    }

    public var fileID: TeamTalkFileID {
        TeamTalkFileID(id)
    }

    public var channelID: Int32 {
        rawValue.channelID
    }

    public var channelIdentifier: TeamTalkChannelID {
        TeamTalkChannelID(channelID)
    }

    public var name: String {
        rawValue.name
    }

    public var username: String {
        rawValue.username
    }

    public var uploadTime: String {
        rawValue.uploadTime
    }

    public var size: Int64 {
        rawValue.size
    }
}

public struct TeamTalkBannedUser: Identifiable {
    public let rawValue: BannedUser

    public init(_ rawValue: BannedUser) {
        self.rawValue = rawValue
    }

    public var cValue: BannedUser {
        rawValue
    }

    public var id: String {
        "\(ipAddress)|\(username)|\(channelPath)|\(types.rawValue)"
    }

    public var ipAddress: String {
        rawValue.ipAddress
    }

    public var channelPath: String {
        rawValue.channelPath
    }

    public var banTime: String {
        rawValue.banTime
    }

    public var nickname: String {
        rawValue.nickname
    }

    public var username: String {
        rawValue.username
    }

    public var owner: String {
        rawValue.owner
    }

    public var types: TeamTalkBanTypes {
        rawValue.types
    }

    public func hasBanType(_ type: TeamTalkBanTypes) -> Bool {
        rawValue.hasBanType(type)
    }
}

public struct TeamTalkBanConfiguration {
    public var ipAddress: String
    public var channelPath: String
    public var username: String
    public var types: TeamTalkBanTypes

    public init(
        ipAddress: String = "",
        channelPath: String = "",
        username: String = "",
        types: TeamTalkBanTypes
    ) {
        self.ipAddress = ipAddress
        self.channelPath = channelPath
        self.username = username
        self.types = types
    }

    public init(_ bannedUser: TeamTalkBannedUser) {
        self.init(
            ipAddress: bannedUser.ipAddress,
            channelPath: bannedUser.channelPath,
            username: bannedUser.username,
            types: bannedUser.types
        )
    }

    public var cValue: BannedUser {
        var bannedUser = BannedUser()
        TeamTalkString.setBannedUser(.ipAddress, on: &bannedUser, to: ipAddress)
        TeamTalkString.setBannedUser(.channelPath, on: &bannedUser, to: channelPath)
        TeamTalkString.setBannedUser(.username, on: &bannedUser, to: username)
        bannedUser.types = types
        return bannedUser
    }
}

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

    public static func channel(_ channelID: Int32, content: String) -> TeamTalkOutgoingTextMessage {
        TeamTalkOutgoingTextMessage(type: .channel, channelID: channelID, content: content)
    }

    public static func channel(_ channelID: TeamTalkChannelID, content: String) -> TeamTalkOutgoingTextMessage {
        channel(channelID.cValue, content: content)
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
