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
