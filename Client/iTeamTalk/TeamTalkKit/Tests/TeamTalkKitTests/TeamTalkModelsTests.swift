import TeamTalkC
import TeamTalkKit
import XCTest

final class TeamTalkModelsTests: XCTestCase {
    func testModelTypedIdentifiersMirrorRawIDs() {
        var rawUser = User()
        rawUser.nUserID = 11
        rawUser.nChannelID = 22
        let user = TeamTalkUser(rawUser)
        XCTAssertEqual(user.userID, TeamTalkUserID(11))
        XCTAssertEqual(user.channelIdentifier, TeamTalkChannelID(22))
        XCTAssertEqual(rawUser.userID, TeamTalkUserID(11))
        XCTAssertEqual(rawUser.channelIdentifier, TeamTalkChannelID(22))

        var rawFile = RemoteFile()
        rawFile.nFileID = 33
        rawFile.nChannelID = 44
        let file = TeamTalkRemoteFile(rawFile)
        XCTAssertEqual(file.fileID, TeamTalkFileID(33))
        XCTAssertEqual(file.channelIdentifier, TeamTalkChannelID(44))
        XCTAssertEqual(rawFile.fileID, TeamTalkFileID(33))
        XCTAssertEqual(rawFile.channelIdentifier, TeamTalkChannelID(44))

        var rawTransfer = FileTransfer()
        rawTransfer.nTransferID = 55
        rawTransfer.nChannelID = 66
        let transfer = TeamTalkFileTransfer(rawTransfer)
        XCTAssertEqual(transfer.transferID, TeamTalkTransferID(55))
        XCTAssertEqual(transfer.channelIdentifier, TeamTalkChannelID(66))
        XCTAssertEqual(rawTransfer.transferID, TeamTalkTransferID(55))
        XCTAssertEqual(rawTransfer.channelIdentifier, TeamTalkChannelID(66))
    }

    func testUserAccountConfigurationRoundTrip() {
        let configuration = TeamTalkUserAccountConfiguration(
            username: "guest",
            password: "secret",
            types: [.defaultUser, .administrator],
            rights: [.canUploadFiles, .canDownloadFiles, .canSendChannelTextMessages],
            userData: 17,
            note: "trusted account",
            initialChannel: "/Lobby",
            autoOperatorChannelIDs: [10, 20],
            audioCodecBitrateLimit: 64_000,
            commandLimit: 12,
            commandIntervalMilliseconds: 1_500
        )

        let account = TeamTalkUserAccount(configuration.cValue)

        XCTAssertEqual(account.username, "guest")
        XCTAssertEqual(account.password, "secret")
        XCTAssertEqual(account.note, "trusted account")
        XCTAssertEqual(account.initialChannel, "/Lobby")
        XCTAssertEqual(account.types, [.defaultUser, .administrator])
        XCTAssertEqual(account.rights, [.canUploadFiles, .canDownloadFiles, .canSendChannelTextMessages])
        XCTAssertEqual(account.userData, 17)
        XCTAssertEqual(account.autoOperatorChannelIDs, [10, 20])
        XCTAssertEqual(account.audioCodecBitrateLimit, 64_000)
        XCTAssertEqual(account.commandLimit, 12)
        XCTAssertEqual(account.commandIntervalMilliseconds, 1_500)
        XCTAssertTrue(account.getUserRight(.canUploadFiles))
        XCTAssertEqual(account.cValue.autoOperatorChannelIdentifiers, [TeamTalkChannelID(10), TeamTalkChannelID(20)])
    }

    func testChannelConfigurationRoundTrip() {
        let configuration = TeamTalkChannelConfiguration(
            channelID: TeamTalkChannelID(7),
            parentChannelID: TeamTalkChannelID(1),
            name: "Lobby",
            topic: "Daily chat",
            password: "room-password",
            operatorPassword: "op-password",
            types: [.permanent, .noRecording],
            userData: 99,
            diskQuota: 4_096,
            maxUsers: 25
        )

        let channel = TeamTalkChannel(configuration.cValue)

        XCTAssertEqual(channel.id, 7)
        XCTAssertEqual(channel.parentID, 1)
        XCTAssertEqual(channel.channelID, TeamTalkChannelID(7))
        XCTAssertEqual(channel.parentChannelID, TeamTalkChannelID(1))
        XCTAssertEqual(channel.name, "Lobby")
        XCTAssertEqual(channel.topic, "Daily chat")
        XCTAssertEqual(channel.password, "room-password")
        XCTAssertEqual(channel.operatorPassword, "op-password")
        XCTAssertEqual(channel.types, [.permanent, .noRecording])
        XCTAssertEqual(channel.userData, 99)
        XCTAssertEqual(channel.diskQuota, 4_096)
        XCTAssertEqual(channel.maxUsers, 25)
        XCTAssertTrue(channel.isPasswordProtected)
    }

    func testServerPropertiesConfigurationRoundTrip() {
        let configuration = TeamTalkServerPropertiesConfiguration(
            name: "Main Server",
            rawMessageOfTheDay: "Welcome <b>home</b>",
            maxUsers: 100,
            maxLoginAttempts: 5,
            maxLoginsPerIPAddress: 3,
            maxVoiceTransmissionBytesPerSecond: 8_000,
            maxVideoCaptureTransmissionBytesPerSecond: 16_000,
            maxMediaFileTransmissionBytesPerSecond: 24_000,
            maxDesktopTransmissionBytesPerSecond: 32_000,
            maxTotalTransmissionBytesPerSecond: 64_000,
            tcpPort: 10333,
            udpPort: 10333,
            userTimeout: 60,
            loginDelayMilliseconds: 250,
            logEvents: [.userLoggedIn, .fileUploaded],
            autoSave: true
        )

        let properties = TeamTalkServerProperties(configuration.cValue)

        XCTAssertEqual(properties.name, "Main Server")
        XCTAssertEqual(properties.rawMessageOfTheDay, "Welcome <b>home</b>")
        XCTAssertEqual(properties.maxUsers, 100)
        XCTAssertEqual(properties.maxLoginAttempts, 5)
        XCTAssertEqual(properties.maxLoginsPerIPAddress, 3)
        XCTAssertEqual(properties.maxVoiceTransmissionBytesPerSecond, 8_000)
        XCTAssertEqual(properties.maxVideoCaptureTransmissionBytesPerSecond, 16_000)
        XCTAssertEqual(properties.maxMediaFileTransmissionBytesPerSecond, 24_000)
        XCTAssertEqual(properties.maxDesktopTransmissionBytesPerSecond, 32_000)
        XCTAssertEqual(properties.maxTotalTransmissionBytesPerSecond, 64_000)
        XCTAssertEqual(properties.tcpPort, 10333)
        XCTAssertEqual(properties.udpPort, 10333)
        XCTAssertEqual(properties.userTimeout, 60)
        XCTAssertEqual(properties.loginDelayMilliseconds, 250)
        XCTAssertEqual(properties.logEvents, [.userLoggedIn, .fileUploaded])
        XCTAssertTrue(properties.autoSave)
    }

    func testUserStatisticsExposeFriendlyProperties() {
        var rawStatistics = UserStatistics()
        rawStatistics.nVoicePacketsRecv = 101
        rawStatistics.nVoicePacketsLost = 7
        rawStatistics.nVideoCapturePacketsRecv = 88
        rawStatistics.nVideoCaptureFramesRecv = 44
        rawStatistics.nVideoCaptureFramesLost = 3
        rawStatistics.nVideoCaptureFramesDropped = 2
        rawStatistics.nMediaFileAudioPacketsRecv = 65
        rawStatistics.nMediaFileAudioPacketsLost = 5
        rawStatistics.nMediaFileVideoPacketsRecv = 54
        rawStatistics.nMediaFileVideoFramesRecv = 27
        rawStatistics.nMediaFileVideoFramesLost = 4
        rawStatistics.nMediaFileVideoFramesDropped = 1

        let statistics = TeamTalkUserStatistics(rawStatistics)

        XCTAssertEqual(statistics.voicePacketsReceived, 101)
        XCTAssertEqual(statistics.voicePacketsLost, 7)
        XCTAssertEqual(statistics.videoCapturePacketsReceived, 88)
        XCTAssertEqual(statistics.videoCaptureFramesReceived, 44)
        XCTAssertEqual(statistics.videoCaptureFramesLost, 3)
        XCTAssertEqual(statistics.videoCaptureFramesDropped, 2)
        XCTAssertEqual(statistics.mediaFileAudioPacketsReceived, 65)
        XCTAssertEqual(statistics.mediaFileAudioPacketsLost, 5)
        XCTAssertEqual(statistics.mediaFileVideoPacketsReceived, 54)
        XCTAssertEqual(statistics.mediaFileVideoFramesReceived, 27)
        XCTAssertEqual(statistics.mediaFileVideoFramesLost, 4)
        XCTAssertEqual(statistics.mediaFileVideoFramesDropped, 1)
        XCTAssertEqual(rawStatistics.voicePacketsReceived, 101)
    }

    func testClientStatisticsExposeFriendlyProperties() {
        var rawStatistics = ClientStatistics()
        rawStatistics.nUdpBytesSent = 1000
        rawStatistics.nUdpBytesRecv = 1100
        rawStatistics.nVoiceBytesSent = 1200
        rawStatistics.nVoiceBytesRecv = 1300
        rawStatistics.nVideoCaptureBytesSent = 1400
        rawStatistics.nVideoCaptureBytesRecv = 1500
        rawStatistics.nMediaFileAudioBytesSent = 1600
        rawStatistics.nMediaFileAudioBytesRecv = 1700
        rawStatistics.nMediaFileVideoBytesSent = 1800
        rawStatistics.nMediaFileVideoBytesRecv = 1900
        rawStatistics.nDesktopBytesSent = 2000
        rawStatistics.nDesktopBytesRecv = 2100
        rawStatistics.nUdpPingTimeMs = -1
        rawStatistics.nTcpPingTimeMs = 42
        rawStatistics.nTcpServerSilenceSec = 9
        rawStatistics.nUdpServerSilenceSec = 11
        rawStatistics.nSoundInputDeviceDelayMSec = 17

        let statistics = TeamTalkClientStatistics(rawStatistics)

        XCTAssertEqual(statistics.udpBytesSent, 1000)
        XCTAssertEqual(statistics.udpBytesReceived, 1100)
        XCTAssertEqual(statistics.voiceBytesSent, 1200)
        XCTAssertEqual(statistics.voiceBytesReceived, 1300)
        XCTAssertEqual(statistics.videoCaptureBytesSent, 1400)
        XCTAssertEqual(statistics.videoCaptureBytesReceived, 1500)
        XCTAssertEqual(statistics.mediaFileAudioBytesSent, 1600)
        XCTAssertEqual(statistics.mediaFileAudioBytesReceived, 1700)
        XCTAssertEqual(statistics.mediaFileVideoBytesSent, 1800)
        XCTAssertEqual(statistics.mediaFileVideoBytesReceived, 1900)
        XCTAssertEqual(statistics.desktopBytesSent, 2000)
        XCTAssertEqual(statistics.desktopBytesReceived, 2100)
        XCTAssertNil(statistics.udpPingTimeMilliseconds)
        XCTAssertEqual(statistics.tcpPingTimeMilliseconds, 42)
        XCTAssertEqual(statistics.tcpServerSilenceSeconds, 9)
        XCTAssertEqual(statistics.udpServerSilenceSeconds, 11)
        XCTAssertEqual(statistics.soundInputDeviceDelayMilliseconds, 17)
        XCTAssertNil(rawStatistics.udpPingTimeMilliseconds)
        XCTAssertEqual(rawStatistics.tcpPingTimeMilliseconds, 42)
    }

    func testClientKeepAliveConfigurationRoundTrip() {
        let configuration = TeamTalkClientKeepAliveConfiguration(
            connectionLostMilliseconds: 15_000,
            tcpKeepAliveIntervalMilliseconds: 7_500,
            udpKeepAliveIntervalMilliseconds: 2_000,
            udpKeepAliveRetransmitMilliseconds: 500,
            udpConnectRetransmitMilliseconds: 750,
            udpConnectTimeoutMilliseconds: 10_000
        )

        let keepAlive = TeamTalkClientKeepAlive(configuration.cValue)

        XCTAssertEqual(keepAlive.connectionLostMilliseconds, 15_000)
        XCTAssertEqual(keepAlive.tcpKeepAliveIntervalMilliseconds, 7_500)
        XCTAssertEqual(keepAlive.udpKeepAliveIntervalMilliseconds, 2_000)
        XCTAssertEqual(keepAlive.udpKeepAliveRetransmitMilliseconds, 500)
        XCTAssertEqual(keepAlive.udpConnectRetransmitMilliseconds, 750)
        XCTAssertEqual(keepAlive.udpConnectTimeoutMilliseconds, 10_000)

        let roundTripped = TeamTalkClientKeepAliveConfiguration(keepAlive).cValue
        XCTAssertEqual(roundTripped.connectionLostMilliseconds, 15_000)
        XCTAssertEqual(roundTripped.tcpKeepAliveIntervalMilliseconds, 7_500)
        XCTAssertEqual(roundTripped.udpKeepAliveIntervalMilliseconds, 2_000)
        XCTAssertEqual(roundTripped.udpKeepAliveRetransmitMilliseconds, 500)
        XCTAssertEqual(roundTripped.udpConnectRetransmitMilliseconds, 750)
        XCTAssertEqual(roundTripped.udpConnectTimeoutMilliseconds, 10_000)
    }

    func testBanConfigurationRoundTrip() {
        let configuration = TeamTalkBanConfiguration(
            ipAddress: "192.168.1.*",
            channelPath: "/Lobby",
            username: "guest",
            types: [.ipAddress, .username, .channel]
        )

        let bannedUser = TeamTalkBannedUser(configuration.cValue)

        XCTAssertEqual(bannedUser.ipAddress, "192.168.1.*")
        XCTAssertEqual(bannedUser.channelPath, "/Lobby")
        XCTAssertEqual(bannedUser.username, "guest")
        XCTAssertEqual(bannedUser.types, [.ipAddress, .username, .channel])
        XCTAssertTrue(bannedUser.hasBanType(.username))
    }

    func testOutgoingTextMessageRoundTrip() {
        let outgoing = TeamTalkOutgoingTextMessage.channel(42, content: "Hello channel")
        let message = TeamTalkTextMessage(outgoing.cValue)

        XCTAssertEqual(message.type, .channel)
        XCTAssertEqual(message.channelID, 42)
        XCTAssertEqual(message.channelIdentifier, TeamTalkChannelID(42))
        XCTAssertEqual(message.content, "Hello channel")
        XCTAssertFalse(message.hasMoreContent)

        var typedOutgoing = TeamTalkOutgoingTextMessage.user(to: TeamTalkUserID(9), content: "Hello user")
        XCTAssertEqual(typedOutgoing.toUserIdentifier, TeamTalkUserID(9))
        typedOutgoing.channelIdentifier = TeamTalkChannelID(12)
        XCTAssertEqual(typedOutgoing.channelID, 12)
    }

    func testTextMessageFactorySplitsLongContent() {
        let content = String(repeating: "a", count: Int(TT_STRLEN) + 10)
        let messages = TeamTalkTextMessageFactory.messages(from: TeamTalkOutgoingTextMessage.broadcast(content: "").cValue, content: content)

        XCTAssertGreaterThan(messages.count, 1)
        XCTAssertTrue(messages.dropLast().allSatisfy { $0.bMore != 0 })
        XCTAssertEqual(messages.last?.bMore, 0)
        XCTAssertEqual(messages.map(\.content).joined(), content)
    }

    func testClientErrorExposesTypedCode() {
        var rawError = ClientErrorMsg()
        rawError.nErrorNo = TeamTalkErrorCode.fileNotFound.cValue

        let error = TeamTalkClientError(rawError)

        XCTAssertEqual(error.code, TeamTalkErrorCode.fileNotFound.cValue)
        XCTAssertEqual(error.errorCode, .fileNotFound)
        XCTAssertTrue(error.errorCode.isCommandError)
    }
}
