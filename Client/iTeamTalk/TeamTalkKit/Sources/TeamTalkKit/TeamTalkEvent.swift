import Foundation
import TeamTalkC

public struct TeamTalkEvent {
    public let rawMessage: TTMessage
    public let kind: Kind

    public init(_ rawMessage: TTMessage) {
        self.rawMessage = rawMessage
        self.kind = Kind(rawMessage)
    }
}

public extension TeamTalkEvent {
    enum Kind {
        case none
        case connectionSucceeded
        case connectionEncryptionError(TeamTalkClientError)
        case connectionFailed
        case connectionLost
        case connectionMaxPayloadUpdated(source: Int32)
        case commandProcessing(commandID: TeamTalkCommandID, isActive: Bool)
        case commandError(commandID: TeamTalkCommandID, error: TeamTalkClientError)
        case commandSucceeded(commandID: TeamTalkCommandID)
        case myselfLoggedIn(userID: Int32, account: TeamTalkUserAccount)
        case myselfLoggedOut
        case myselfKicked(channelID: Int32, by: TeamTalkUser?)
        case userLoggedIn(TeamTalkUser)
        case userLoggedOut(TeamTalkUser)
        case userUpdated(TeamTalkUser)
        case userJoined(TeamTalkUser)
        case userLeft(previousChannelID: Int32, user: TeamTalkUser)
        case textMessage(TeamTalkTextMessage)
        case channelCreated(TeamTalkChannel)
        case channelUpdated(TeamTalkChannel)
        case channelRemoved(TeamTalkChannel)
        case serverUpdated(TeamTalkServerProperties)
        case serverStatistics(TeamTalkServerStatistics)
        case fileCreated(TeamTalkRemoteFile)
        case fileRemoved(TeamTalkRemoteFile)
        case userAccount(TeamTalkUserAccount)
        case userAccountCreated(TeamTalkUserAccount)
        case userAccountRemoved(TeamTalkUserAccount)
        case bannedUser(TeamTalkBannedUser)
        case userStateChanged(TeamTalkUser)
        case userVideoCapture(userID: Int32, streamID: Int32)
        case userMediaFileVideo(userID: Int32, streamID: Int32)
        case userDesktopWindow(userID: Int32, streamID: Int32)
        case userDesktopCursor(userID: Int32)
        case userDesktopInput(userID: Int32)
        case userRecordMediaFile(userID: Int32)
        case userAudioBlock(userID: Int32, streamType: TeamTalkStreamTypes)
        case internalError(TeamTalkClientError)
        case voiceActivation(isActive: Bool)
        case hotkey(id: Int32, isActive: Bool)
        case hotkeyTest(keyCode: Int32, isActive: Bool)
        case fileTransfer(TeamTalkFileTransfer)
        case desktopWindowTransfer(sessionID: Int32, bytesRemaining: Int32)
        case streamMediaFile
        case localMediaFile(sessionID: Int32)
        case audioInput(streamID: Int32)
        case userFirstVoiceStreamPacket(streamID: Int32, user: TeamTalkUser)
        case soundDeviceAdded
        case soundDeviceRemoved
        case soundDeviceUnplugged
        case soundDeviceNewDefaultInput
        case soundDeviceNewDefaultOutput
        case soundDeviceNewDefaultInputCommunicationDevice
        case soundDeviceNewDefaultOutputCommunicationDevice
        case unhandled(event: TeamTalkClientEvent, payloadType: TeamTalkPayloadType)
    }
}

private extension TeamTalkEvent.Kind {
    init(_ message: TTMessage) {
        switch message.event {
        case .none:
            self = .none
        case .connectionSucceeded:
            self = .connectionSucceeded
        case .connectionEncryptionError:
            self = .connectionEncryptionError(TeamTalkClientError(TeamTalkMessagePayload.clientError(from: message)))
        case .connectionFailed:
            self = .connectionFailed
        case .connectionLost:
            self = .connectionLost
        case .connectionMaxPayloadUpdated:
            self = .connectionMaxPayloadUpdated(source: message.source)
        case .commandProcessing:
            self = .commandProcessing(commandID: TeamTalkCommandID(message.source), isActive: message.isActive)
        case .commandError:
            self = .commandError(
                commandID: TeamTalkCommandID(message.source),
                error: TeamTalkClientError(TeamTalkMessagePayload.clientError(from: message))
            )
        case .commandSucceeded:
            self = .commandSucceeded(commandID: TeamTalkCommandID(message.source))
        case .myselfLoggedIn:
            self = .myselfLoggedIn(
                userID: message.source,
                account: TeamTalkUserAccount(TeamTalkMessagePayload.userAccount(from: message))
            )
        case .myselfLoggedOut:
            self = .myselfLoggedOut
        case .myselfKicked:
            let user = message.payloadType == .user ? TeamTalkUser(TeamTalkMessagePayload.user(from: message)) : nil
            self = .myselfKicked(channelID: message.source, by: user)
        case .userLoggedIn:
            self = .userLoggedIn(TeamTalkUser(TeamTalkMessagePayload.user(from: message)))
        case .userLoggedOut:
            self = .userLoggedOut(TeamTalkUser(TeamTalkMessagePayload.user(from: message)))
        case .userUpdated:
            self = .userUpdated(TeamTalkUser(TeamTalkMessagePayload.user(from: message)))
        case .userJoined:
            self = .userJoined(TeamTalkUser(TeamTalkMessagePayload.user(from: message)))
        case .userLeft:
            self = .userLeft(
                previousChannelID: message.source,
                user: TeamTalkUser(TeamTalkMessagePayload.user(from: message))
            )
        case .userTextMessage:
            self = .textMessage(TeamTalkTextMessage(TeamTalkMessagePayload.textMessage(from: message)))
        case .channelCreated:
            self = .channelCreated(TeamTalkChannel(TeamTalkMessagePayload.channel(from: message)))
        case .channelUpdated:
            self = .channelUpdated(TeamTalkChannel(TeamTalkMessagePayload.channel(from: message)))
        case .channelRemoved:
            self = .channelRemoved(TeamTalkChannel(TeamTalkMessagePayload.channel(from: message)))
        case .serverUpdated:
            self = .serverUpdated(TeamTalkServerProperties(TeamTalkMessagePayload.serverProperties(from: message)))
        case .serverStatistics:
            self = .serverStatistics(TeamTalkServerStatistics(TeamTalkMessagePayload.serverStatistics(from: message)))
        case .fileCreated:
            self = .fileCreated(TeamTalkRemoteFile(TeamTalkMessagePayload.remoteFile(from: message)))
        case .fileRemoved:
            self = .fileRemoved(TeamTalkRemoteFile(TeamTalkMessagePayload.remoteFile(from: message)))
        case .userAccount:
            self = .userAccount(TeamTalkUserAccount(TeamTalkMessagePayload.userAccount(from: message)))
        case .bannedUser:
            self = .bannedUser(TeamTalkBannedUser(TeamTalkMessagePayload.bannedUser(from: message)))
        case .userAccountCreated:
            self = .userAccountCreated(TeamTalkUserAccount(TeamTalkMessagePayload.userAccount(from: message)))
        case .userAccountRemoved:
            self = .userAccountRemoved(TeamTalkUserAccount(TeamTalkMessagePayload.userAccount(from: message)))
        case .userStateChanged:
            self = .userStateChanged(TeamTalkUser(TeamTalkMessagePayload.user(from: message)))
        case .userVideoCapture:
            self = .userVideoCapture(userID: message.source, streamID: message.nStreamID)
        case .userMediaFileVideo:
            self = .userMediaFileVideo(userID: message.source, streamID: message.nStreamID)
        case .userDesktopWindow:
            self = .userDesktopWindow(userID: message.source, streamID: message.nStreamID)
        case .userDesktopCursor:
            self = .userDesktopCursor(userID: message.source)
        case .userDesktopInput:
            self = .userDesktopInput(userID: message.source)
        case .userRecordMediaFile:
            self = .userRecordMediaFile(userID: message.source)
        case .userAudioBlock:
            self = .userAudioBlock(userID: message.source, streamType: message.streamType)
        case .internalError:
            self = .internalError(TeamTalkClientError(TeamTalkMessagePayload.clientError(from: message)))
        case .voiceActivation:
            self = .voiceActivation(isActive: message.isActive)
        case .hotkey:
            self = .hotkey(id: message.source, isActive: message.isActive)
        case .hotkeyTest:
            self = .hotkeyTest(keyCode: message.source, isActive: message.isActive)
        case .fileTransfer:
            self = .fileTransfer(TeamTalkFileTransfer(TeamTalkMessagePayload.fileTransfer(from: message)))
        case .desktopWindowTransfer:
            self = .desktopWindowTransfer(sessionID: message.source, bytesRemaining: message.nBytesRemain)
        case .streamMediaFile:
            self = .streamMediaFile
        case .localMediaFile:
            self = .localMediaFile(sessionID: message.source)
        case .audioInput:
            self = .audioInput(streamID: message.source)
        case .userFirstVoiceStreamPacket:
            self = .userFirstVoiceStreamPacket(
                streamID: message.source,
                user: TeamTalkUser(TeamTalkMessagePayload.user(from: message))
            )
        case .soundDeviceAdded:
            self = .soundDeviceAdded
        case .soundDeviceRemoved:
            self = .soundDeviceRemoved
        case .soundDeviceUnplugged:
            self = .soundDeviceUnplugged
        case .soundDeviceNewDefaultInput:
            self = .soundDeviceNewDefaultInput
        case .soundDeviceNewDefaultOutput:
            self = .soundDeviceNewDefaultOutput
        case .soundDeviceNewDefaultInputCommunicationDevice:
            self = .soundDeviceNewDefaultInputCommunicationDevice
        case .soundDeviceNewDefaultOutputCommunicationDevice:
            self = .soundDeviceNewDefaultOutputCommunicationDevice
        default:
            self = .unhandled(event: message.event, payloadType: message.payloadType)
        }
    }
}
