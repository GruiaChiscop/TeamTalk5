import Foundation
import TeamTalkC

public struct TeamTalkCommandID: RawRepresentable, Hashable, Sendable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public init(integerLiteral value: Int32) {
        self.init(rawValue: value)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkCommandID(rawValue: 0)
    public static let invalid = TeamTalkCommandID(rawValue: -1)
}

public struct TeamTalkUserID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkUserID(rawValue: 0)
    public static let invalid = TeamTalkUserID(rawValue: -1)
}

public struct TeamTalkChannelID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkChannelID(rawValue: 0)
    public static let invalid = TeamTalkChannelID(rawValue: -1)
}

public struct TeamTalkFileID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkFileID(rawValue: 0)
    public static let invalid = TeamTalkFileID(rawValue: -1)
}

public struct TeamTalkTransferID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkTransferID(rawValue: 0)
    public static let invalid = TeamTalkTransferID(rawValue: -1)
}

public struct TeamTalkErrorCode: RawRepresentable, Hashable, Sendable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public init(cValue: ClientError) {
        self.init(rawValue: Int32(cValue.rawValue))
    }

    public init(integerLiteral value: Int32) {
        self.init(rawValue: value)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isSuccess: Bool {
        rawValue == TeamTalkErrorCode.success.rawValue
    }

    public var isCommandError: Bool {
        (1000..<10000).contains(rawValue)
    }

    public var isInternalError: Bool {
        rawValue >= 10000
    }

    public var description: String {
        String(rawValue)
    }

    public static let success = TeamTalkErrorCode(cValue: CMDERR_SUCCESS)
    public static let syntaxError = TeamTalkErrorCode(cValue: CMDERR_SYNTAX_ERROR)
    public static let unknownCommand = TeamTalkErrorCode(cValue: CMDERR_UNKNOWN_COMMAND)
    public static let missingParameter = TeamTalkErrorCode(cValue: CMDERR_MISSING_PARAMETER)
    public static let incompatibleProtocols = TeamTalkErrorCode(cValue: CMDERR_INCOMPATIBLE_PROTOCOLS)
    public static let unknownAudioCodec = TeamTalkErrorCode(cValue: CMDERR_UNKNOWN_AUDIOCODEC)
    public static let invalidUsername = TeamTalkErrorCode(cValue: CMDERR_INVALID_USERNAME)
    public static let incorrectChannelPassword = TeamTalkErrorCode(cValue: CMDERR_INCORRECT_CHANNEL_PASSWORD)
    public static let invalidAccount = TeamTalkErrorCode(cValue: CMDERR_INVALID_ACCOUNT)
    public static let maxServerUsersExceeded = TeamTalkErrorCode(cValue: CMDERR_MAX_SERVER_USERS_EXCEEDED)
    public static let maxChannelUsersExceeded = TeamTalkErrorCode(cValue: CMDERR_MAX_CHANNEL_USERS_EXCEEDED)
    public static let serverBanned = TeamTalkErrorCode(cValue: CMDERR_SERVER_BANNED)
    public static let notAuthorized = TeamTalkErrorCode(cValue: CMDERR_NOT_AUTHORIZED)
    public static let maxDiskUsageExceeded = TeamTalkErrorCode(cValue: CMDERR_MAX_DISKUSAGE_EXCEEDED)
    public static let incorrectOperatorPassword = TeamTalkErrorCode(cValue: CMDERR_INCORRECT_OP_PASSWORD)
    public static let audioCodecBitrateLimitExceeded = TeamTalkErrorCode(cValue: CMDERR_AUDIOCODEC_BITRATE_LIMIT_EXCEEDED)
    public static let maxLoginsPerIPAddressExceeded = TeamTalkErrorCode(cValue: CMDERR_MAX_LOGINS_PER_IPADDRESS_EXCEEDED)
    public static let maxChannelsExceeded = TeamTalkErrorCode(cValue: CMDERR_MAX_CHANNELS_EXCEEDED)
    public static let commandFlood = TeamTalkErrorCode(cValue: CMDERR_COMMAND_FLOOD)
    public static let channelBanned = TeamTalkErrorCode(cValue: CMDERR_CHANNEL_BANNED)
    public static let maxFileTransfersExceeded = TeamTalkErrorCode(cValue: CMDERR_MAX_FILETRANSFERS_EXCEEDED)
    public static let notLoggedIn = TeamTalkErrorCode(cValue: CMDERR_NOT_LOGGEDIN)
    public static let alreadyLoggedIn = TeamTalkErrorCode(cValue: CMDERR_ALREADY_LOGGEDIN)
    public static let notInChannel = TeamTalkErrorCode(cValue: CMDERR_NOT_IN_CHANNEL)
    public static let alreadyInChannel = TeamTalkErrorCode(cValue: CMDERR_ALREADY_IN_CHANNEL)
    public static let channelAlreadyExists = TeamTalkErrorCode(cValue: CMDERR_CHANNEL_ALREADY_EXISTS)
    public static let channelNotFound = TeamTalkErrorCode(cValue: CMDERR_CHANNEL_NOT_FOUND)
    public static let userNotFound = TeamTalkErrorCode(cValue: CMDERR_USER_NOT_FOUND)
    public static let banNotFound = TeamTalkErrorCode(cValue: CMDERR_BAN_NOT_FOUND)
    public static let fileTransferNotFound = TeamTalkErrorCode(cValue: CMDERR_FILETRANSFER_NOT_FOUND)
    public static let openFileFailed = TeamTalkErrorCode(cValue: CMDERR_OPENFILE_FAILED)
    public static let accountNotFound = TeamTalkErrorCode(cValue: CMDERR_ACCOUNT_NOT_FOUND)
    public static let fileNotFound = TeamTalkErrorCode(cValue: CMDERR_FILE_NOT_FOUND)
    public static let fileAlreadyExists = TeamTalkErrorCode(cValue: CMDERR_FILE_ALREADY_EXISTS)
    public static let fileSharingDisabled = TeamTalkErrorCode(cValue: CMDERR_FILESHARING_DISABLED)
    public static let channelHasUsers = TeamTalkErrorCode(cValue: CMDERR_CHANNEL_HAS_USERS)
    public static let loginServiceUnavailable = TeamTalkErrorCode(cValue: CMDERR_LOGINSERVICE_UNAVAILABLE)
    public static let channelCannotBeHidden = TeamTalkErrorCode(cValue: CMDERR_CHANNEL_CANNOT_BE_HIDDEN)
    public static let soundInputFailure = TeamTalkErrorCode(cValue: INTERR_SNDINPUT_FAILURE)
    public static let soundOutputFailure = TeamTalkErrorCode(cValue: INTERR_SNDOUTPUT_FAILURE)
    public static let audioCodecInitializationFailed = TeamTalkErrorCode(cValue: INTERR_AUDIOCODEC_INIT_FAILED)
    public static let speexDSPInitializationFailed = TeamTalkErrorCode(cValue: INTERR_SPEEXDSP_INIT_FAILED)
    public static let audioPreprocessorInitializationFailed = TeamTalkErrorCode(cValue: INTERR_AUDIOPREPROCESSOR_INIT_FAILED)
    public static let messageQueueOverflow = TeamTalkErrorCode(cValue: INTERR_TTMESSAGE_QUEUE_OVERFLOW)
    public static let soundEffectFailure = TeamTalkErrorCode(cValue: INTERR_SNDEFFECT_FAILURE)
}

public struct TeamTalkUserRights: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(cValue: UserRights) {
        self.init(rawValue: cValue)
    }

    public var cValue: UserRights {
        rawValue
    }

    public static let none = TeamTalkUserRights(rawValue: USERRIGHT_NONE.rawValue)
    public static let multipleLogins = TeamTalkUserRights(rawValue: USERRIGHT_MULTI_LOGIN.rawValue)
    public static let canViewAllUsers = TeamTalkUserRights(rawValue: USERRIGHT_VIEW_ALL_USERS.rawValue)
    public static let canCreateTemporaryChannels = TeamTalkUserRights(rawValue: USERRIGHT_CREATE_TEMPORARY_CHANNEL.rawValue)
    public static let canModifyChannels = TeamTalkUserRights(rawValue: USERRIGHT_MODIFY_CHANNELS.rawValue)
    public static let canBroadcastTextMessages = TeamTalkUserRights(rawValue: USERRIGHT_TEXTMESSAGE_BROADCAST.rawValue)
    public static let canKickUsers = TeamTalkUserRights(rawValue: USERRIGHT_KICK_USERS.rawValue)
    public static let canBanUsers = TeamTalkUserRights(rawValue: USERRIGHT_BAN_USERS.rawValue)
    public static let canMoveUsers = TeamTalkUserRights(rawValue: USERRIGHT_MOVE_USERS.rawValue)
    public static let canEnableOperators = TeamTalkUserRights(rawValue: USERRIGHT_OPERATOR_ENABLE.rawValue)
    public static let canUploadFiles = TeamTalkUserRights(rawValue: USERRIGHT_UPLOAD_FILES.rawValue)
    public static let canDownloadFiles = TeamTalkUserRights(rawValue: USERRIGHT_DOWNLOAD_FILES.rawValue)
    public static let canUpdateServerProperties = TeamTalkUserRights(rawValue: USERRIGHT_UPDATE_SERVERPROPERTIES.rawValue)
    public static let canTransmitVoice = TeamTalkUserRights(rawValue: USERRIGHT_TRANSMIT_VOICE.rawValue)
    public static let canTransmitVideoCapture = TeamTalkUserRights(rawValue: USERRIGHT_TRANSMIT_VIDEOCAPTURE.rawValue)
    public static let canTransmitDesktop = TeamTalkUserRights(rawValue: USERRIGHT_TRANSMIT_DESKTOP.rawValue)
    public static let canTransmitDesktopInput = TeamTalkUserRights(rawValue: USERRIGHT_TRANSMIT_DESKTOPINPUT.rawValue)
    public static let canTransmitMediaFileAudio = TeamTalkUserRights(rawValue: USERRIGHT_TRANSMIT_MEDIAFILE_AUDIO.rawValue)
    public static let canTransmitMediaFileVideo = TeamTalkUserRights(rawValue: USERRIGHT_TRANSMIT_MEDIAFILE_VIDEO.rawValue)
    public static let canTransmitMediaFiles = TeamTalkUserRights(rawValue: USERRIGHT_TRANSMIT_MEDIAFILE.rawValue)
    public static let lockedNickname = TeamTalkUserRights(rawValue: USERRIGHT_LOCKED_NICKNAME.rawValue)
    public static let lockedStatus = TeamTalkUserRights(rawValue: USERRIGHT_LOCKED_STATUS.rawValue)
    public static let canRecordVoice = TeamTalkUserRights(rawValue: USERRIGHT_RECORD_VOICE.rawValue)
    public static let canViewHiddenChannels = TeamTalkUserRights(rawValue: USERRIGHT_VIEW_HIDDEN_CHANNELS.rawValue)
    public static let canSendPrivateTextMessages = TeamTalkUserRights(rawValue: USERRIGHT_TEXTMESSAGE_USER.rawValue)
    public static let canSendChannelTextMessages = TeamTalkUserRights(rawValue: USERRIGHT_TEXTMESSAGE_CHANNEL.rawValue)
}

public struct TeamTalkUserTypes: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(cValue: UserTypes) {
        self.init(rawValue: cValue)
    }

    public var cValue: UserTypes {
        rawValue
    }

    public static let none = TeamTalkUserTypes(rawValue: USERTYPE_NONE.rawValue)
    public static let defaultUser = TeamTalkUserTypes(rawValue: USERTYPE_DEFAULT.rawValue)
    public static let administrator = TeamTalkUserTypes(rawValue: USERTYPE_ADMIN.rawValue)
}

public struct TeamTalkSubscriptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(cValue: Subscriptions) {
        self.init(rawValue: cValue)
    }

    public var cValue: Subscriptions {
        rawValue
    }

    public static let none = TeamTalkSubscriptions(rawValue: SUBSCRIBE_NONE.rawValue)
    public static let userMessages = TeamTalkSubscriptions(rawValue: SUBSCRIBE_USER_MSG.rawValue)
    public static let channelMessages = TeamTalkSubscriptions(rawValue: SUBSCRIBE_CHANNEL_MSG.rawValue)
    public static let broadcastMessages = TeamTalkSubscriptions(rawValue: SUBSCRIBE_BROADCAST_MSG.rawValue)
    public static let customMessages = TeamTalkSubscriptions(rawValue: SUBSCRIBE_CUSTOM_MSG.rawValue)
    public static let voice = TeamTalkSubscriptions(rawValue: SUBSCRIBE_VOICE.rawValue)
    public static let videoCapture = TeamTalkSubscriptions(rawValue: SUBSCRIBE_VIDEOCAPTURE.rawValue)
    public static let desktop = TeamTalkSubscriptions(rawValue: SUBSCRIBE_DESKTOP.rawValue)
    public static let desktopInput = TeamTalkSubscriptions(rawValue: SUBSCRIBE_DESKTOPINPUT.rawValue)
    public static let mediaFile = TeamTalkSubscriptions(rawValue: SUBSCRIBE_MEDIAFILE.rawValue)
    public static let interceptUserMessages = TeamTalkSubscriptions(rawValue: SUBSCRIBE_INTERCEPT_USER_MSG.rawValue)
    public static let interceptChannelMessages = TeamTalkSubscriptions(rawValue: SUBSCRIBE_INTERCEPT_CHANNEL_MSG.rawValue)
    public static let interceptCustomMessages = TeamTalkSubscriptions(rawValue: SUBSCRIBE_INTERCEPT_CUSTOM_MSG.rawValue)
    public static let interceptVoice = TeamTalkSubscriptions(rawValue: SUBSCRIBE_INTERCEPT_VOICE.rawValue)
    public static let interceptVideoCapture = TeamTalkSubscriptions(rawValue: SUBSCRIBE_INTERCEPT_VIDEOCAPTURE.rawValue)
    public static let interceptDesktop = TeamTalkSubscriptions(rawValue: SUBSCRIBE_INTERCEPT_DESKTOP.rawValue)
    public static let interceptMediaFile = TeamTalkSubscriptions(rawValue: SUBSCRIBE_INTERCEPT_MEDIAFILE.rawValue)
}

public struct TeamTalkUserStates: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(cValue: UserStates) {
        self.init(rawValue: cValue)
    }

    public var cValue: UserStates {
        rawValue
    }

    public static let none = TeamTalkUserStates(rawValue: USERSTATE_NONE.rawValue)
    public static let voice = TeamTalkUserStates(rawValue: USERSTATE_VOICE.rawValue)
    public static let voiceMuted = TeamTalkUserStates(rawValue: USERSTATE_MUTE_VOICE.rawValue)
    public static let mediaFileMuted = TeamTalkUserStates(rawValue: USERSTATE_MUTE_MEDIAFILE.rawValue)
    public static let desktop = TeamTalkUserStates(rawValue: USERSTATE_DESKTOP.rawValue)
    public static let videoCapture = TeamTalkUserStates(rawValue: USERSTATE_VIDEOCAPTURE.rawValue)
    public static let mediaFileAudio = TeamTalkUserStates(rawValue: USERSTATE_MEDIAFILE_AUDIO.rawValue)
    public static let mediaFileVideo = TeamTalkUserStates(rawValue: USERSTATE_MEDIAFILE_VIDEO.rawValue)
    public static let mediaFile = TeamTalkUserStates(rawValue: USERSTATE_MEDIAFILE.rawValue)
}

public struct TeamTalkStreamTypes: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(cValue: StreamTypes) {
        self.init(rawValue: cValue)
    }

    public init(cValue: StreamType) {
        self.init(rawValue: cValue.rawValue)
    }

    public var cValue: StreamType {
        StreamType(rawValue: rawValue)
    }

    public var cMask: StreamTypes {
        rawValue
    }

    public static let none = TeamTalkStreamTypes(rawValue: STREAMTYPE_NONE.rawValue)
    public static let voice = TeamTalkStreamTypes(rawValue: STREAMTYPE_VOICE.rawValue)
    public static let videoCapture = TeamTalkStreamTypes(rawValue: STREAMTYPE_VIDEOCAPTURE.rawValue)
    public static let mediaFileAudio = TeamTalkStreamTypes(rawValue: STREAMTYPE_MEDIAFILE_AUDIO.rawValue)
    public static let mediaFileVideo = TeamTalkStreamTypes(rawValue: STREAMTYPE_MEDIAFILE_VIDEO.rawValue)
    public static let desktop = TeamTalkStreamTypes(rawValue: STREAMTYPE_DESKTOP.rawValue)
    public static let desktopInput = TeamTalkStreamTypes(rawValue: STREAMTYPE_DESKTOPINPUT.rawValue)
    public static let mediaFile = TeamTalkStreamTypes(rawValue: STREAMTYPE_MEDIAFILE.rawValue)
    public static let channelMessage = TeamTalkStreamTypes(rawValue: STREAMTYPE_CHANNELMSG.rawValue)
    public static let localMediaPlaybackAudio = TeamTalkStreamTypes(rawValue: STREAMTYPE_LOCALMEDIAPLAYBACK_AUDIO.rawValue)
    public static let classroomAll = TeamTalkStreamTypes(rawValue: STREAMTYPE_CLASSROOM_ALL.rawValue)
}

public struct TeamTalkChannelTypes: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(cValue: ChannelTypes) {
        self.init(rawValue: cValue)
    }

    public var cValue: ChannelTypes {
        rawValue
    }

    public static let `default` = TeamTalkChannelTypes(rawValue: CHANNEL_DEFAULT.rawValue)
    public static let permanent = TeamTalkChannelTypes(rawValue: CHANNEL_PERMANENT.rawValue)
    public static let soloTransmit = TeamTalkChannelTypes(rawValue: CHANNEL_SOLO_TRANSMIT.rawValue)
    public static let classroom = TeamTalkChannelTypes(rawValue: CHANNEL_CLASSROOM.rawValue)
    public static let operatorReceiveOnly = TeamTalkChannelTypes(rawValue: CHANNEL_OPERATOR_RECVONLY.rawValue)
    public static let noVoiceActivation = TeamTalkChannelTypes(rawValue: CHANNEL_NO_VOICEACTIVATION.rawValue)
    public static let noRecording = TeamTalkChannelTypes(rawValue: CHANNEL_NO_RECORDING.rawValue)
    public static let hidden = TeamTalkChannelTypes(rawValue: CHANNEL_HIDDEN.rawValue)
}

public struct TeamTalkServerLogEvents: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(cValue: ServerLogEvents) {
        self.init(rawValue: cValue)
    }

    public var cValue: ServerLogEvents {
        rawValue
    }

    public static let none = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_NONE.rawValue)
    public static let userConnected = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_CONNECTED.rawValue)
    public static let userDisconnected = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_DISCONNECTED.rawValue)
    public static let userLoggedIn = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_LOGGEDIN.rawValue)
    public static let userLoggedOut = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_LOGGEDOUT.rawValue)
    public static let userLoginFailed = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_LOGINFAILED.rawValue)
    public static let userTimedOut = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_TIMEDOUT.rawValue)
    public static let userKicked = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_KICKED.rawValue)
    public static let userBanned = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_BANNED.rawValue)
    public static let userUnbanned = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_UNBANNED.rawValue)
    public static let userUpdated = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_UPDATED.rawValue)
    public static let userJoinedChannel = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_JOINEDCHANNEL.rawValue)
    public static let userLeftChannel = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_LEFTCHANNEL.rawValue)
    public static let userMoved = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_MOVED.rawValue)
    public static let userPrivateTextMessage = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_TEXTMESSAGE_PRIVATE.rawValue)
    public static let userCustomTextMessage = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_TEXTMESSAGE_CUSTOM.rawValue)
    public static let userChannelTextMessage = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_TEXTMESSAGE_CHANNEL.rawValue)
    public static let userBroadcastTextMessage = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_TEXTMESSAGE_BROADCAST.rawValue)
    public static let channelCreated = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_CHANNEL_CREATED.rawValue)
    public static let channelUpdated = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_CHANNEL_UPDATED.rawValue)
    public static let channelRemoved = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_CHANNEL_REMOVED.rawValue)
    public static let fileUploaded = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_FILE_UPLOADED.rawValue)
    public static let fileDownloaded = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_FILE_DOWNLOADED.rawValue)
    public static let fileDeleted = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_FILE_DELETED.rawValue)
    public static let serverUpdated = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_SERVER_UPDATED.rawValue)
    public static let serverSavedConfig = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_SERVER_SAVECONFIG.rawValue)
    public static let userEncryptionError = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_CRYPTERROR.rawValue)
    public static let userNewStream = TeamTalkServerLogEvents(rawValue: SERVERLOGEVENT_USER_NEW_STREAM.rawValue)
}

public struct TeamTalkBanTypes: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(cValue: BanTypes) {
        self.init(rawValue: cValue)
    }

    public var cValue: BanTypes {
        rawValue
    }

    public static let none = TeamTalkBanTypes(rawValue: BANTYPE_NONE.rawValue)
    public static let channel = TeamTalkBanTypes(rawValue: BANTYPE_CHANNEL.rawValue)
    public static let ipAddress = TeamTalkBanTypes(rawValue: BANTYPE_IPADDR.rawValue)
    public static let username = TeamTalkBanTypes(rawValue: BANTYPE_USERNAME.rawValue)
}

public struct TeamTalkStatusMode: OptionSet, Hashable, Sendable {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public static let available: TeamTalkStatusMode = []
    public static let away = TeamTalkStatusMode(rawValue: 0x00000001)
    public static let question = TeamTalkStatusMode(rawValue: 0x00000002)
    public static let modeMask = TeamTalkStatusMode(rawValue: 0x000000FF)
    public static let flagsMask = TeamTalkStatusMode(rawValue: Int32(bitPattern: 0xFFFFFF00))
    public static let female = TeamTalkStatusMode(rawValue: 0x00000100)
    public static let videoTransmit = TeamTalkStatusMode(rawValue: 0x00000200)
    public static let desktop = TeamTalkStatusMode(rawValue: 0x00000400)
    public static let streamMediaFile = TeamTalkStatusMode(rawValue: 0x00000800)
}

public struct TeamTalkCodec: RawRepresentable, Hashable, Sendable {
    public let rawValue: Codec

    public init(rawValue: Codec) {
        self.rawValue = rawValue
    }

    public init(cValue: Codec) {
        self.init(rawValue: cValue)
    }

    public var cValue: Codec {
        rawValue
    }

    public static let none = TeamTalkCodec(rawValue: NO_CODEC)
    public static let speex = TeamTalkCodec(rawValue: SPEEX_CODEC)
    public static let speexVBR = TeamTalkCodec(rawValue: SPEEX_VBR_CODEC)
    public static let opus = TeamTalkCodec(rawValue: OPUS_CODEC)
    public static let webMVP8 = TeamTalkCodec(rawValue: WEBM_VP8_CODEC)
}

public struct TeamTalkAudioPreprocessorType: RawRepresentable, Hashable, Sendable {
    public let rawValue: AudioPreprocessorType

    public init(rawValue: AudioPreprocessorType) {
        self.rawValue = rawValue
    }

    public init(cValue: AudioPreprocessorType) {
        self.init(rawValue: cValue)
    }

    public var cValue: AudioPreprocessorType {
        rawValue
    }

    public static let none = TeamTalkAudioPreprocessorType(rawValue: NO_AUDIOPREPROCESSOR)
    public static let speexDSP = TeamTalkAudioPreprocessorType(rawValue: SPEEXDSP_AUDIOPREPROCESSOR)
    public static let teamTalk = TeamTalkAudioPreprocessorType(rawValue: TEAMTALK_AUDIOPREPROCESSOR)
    public static let obsoleteWebRTC = TeamTalkAudioPreprocessorType(rawValue: WEBRTC_AUDIOPREPROCESSOR_OBSOLETE_R4332)
    public static let webRTC = TeamTalkAudioPreprocessorType(rawValue: WEBRTC_AUDIOPREPROCESSOR)
}

public struct TeamTalkTextMessageType: RawRepresentable, Hashable, Sendable {
    public let rawValue: TextMsgType

    public init(rawValue: TextMsgType) {
        self.rawValue = rawValue
    }

    public init(cValue: TextMsgType) {
        self.init(rawValue: cValue)
    }

    public var cValue: TextMsgType {
        rawValue
    }

    public static let none = TeamTalkTextMessageType(rawValue: MSGTYPE_NONE)
    public static let user = TeamTalkTextMessageType(rawValue: MSGTYPE_USER)
    public static let channel = TeamTalkTextMessageType(rawValue: MSGTYPE_CHANNEL)
    public static let broadcast = TeamTalkTextMessageType(rawValue: MSGTYPE_BROADCAST)
    public static let custom = TeamTalkTextMessageType(rawValue: MSGTYPE_CUSTOM)
}

public struct TeamTalkFileTransferStatus: RawRepresentable, Hashable, Sendable {
    public let rawValue: FileTransferStatus

    public init(rawValue: FileTransferStatus) {
        self.rawValue = rawValue
    }

    public init(cValue: FileTransferStatus) {
        self.init(rawValue: cValue)
    }

    public var cValue: FileTransferStatus {
        rawValue
    }

    public static let closed = TeamTalkFileTransferStatus(rawValue: FILETRANSFER_CLOSED)
    public static let error = TeamTalkFileTransferStatus(rawValue: FILETRANSFER_ERROR)
    public static let active = TeamTalkFileTransferStatus(rawValue: FILETRANSFER_ACTIVE)
    public static let finished = TeamTalkFileTransferStatus(rawValue: FILETRANSFER_FINISHED)
}

public struct TeamTalkClientEvent: RawRepresentable, Hashable, Sendable {
    public let rawValue: ClientEvent

    public init(rawValue: ClientEvent) {
        self.rawValue = rawValue
    }

    public init(cValue: ClientEvent) {
        self.init(rawValue: cValue)
    }

    public var cValue: ClientEvent {
        rawValue
    }

    public static let none = TeamTalkClientEvent(rawValue: CLIENTEVENT_NONE)
    public static let connectionSucceeded = TeamTalkClientEvent(rawValue: CLIENTEVENT_CON_SUCCESS)
    public static let connectionEncryptionError = TeamTalkClientEvent(rawValue: CLIENTEVENT_CON_CRYPT_ERROR)
    public static let connectionFailed = TeamTalkClientEvent(rawValue: CLIENTEVENT_CON_FAILED)
    public static let connectionLost = TeamTalkClientEvent(rawValue: CLIENTEVENT_CON_LOST)
    public static let connectionMaxPayloadUpdated = TeamTalkClientEvent(rawValue: CLIENTEVENT_CON_MAX_PAYLOAD_UPDATED)
    public static let commandProcessing = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_PROCESSING)
    public static let commandError = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_ERROR)
    public static let commandSucceeded = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_SUCCESS)
    public static let myselfLoggedIn = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_MYSELF_LOGGEDIN)
    public static let myselfLoggedOut = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_MYSELF_LOGGEDOUT)
    public static let myselfKicked = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_MYSELF_KICKED)
    public static let userLoggedIn = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_USER_LOGGEDIN)
    public static let userLoggedOut = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_USER_LOGGEDOUT)
    public static let userUpdated = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_USER_UPDATE)
    public static let userJoined = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_USER_JOINED)
    public static let userLeft = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_USER_LEFT)
    public static let userTextMessage = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_USER_TEXTMSG)
    public static let channelCreated = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_CHANNEL_NEW)
    public static let channelUpdated = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_CHANNEL_UPDATE)
    public static let channelRemoved = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_CHANNEL_REMOVE)
    public static let serverUpdated = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_SERVER_UPDATE)
    public static let serverStatistics = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_SERVERSTATISTICS)
    public static let fileCreated = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_FILE_NEW)
    public static let fileRemoved = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_FILE_REMOVE)
    public static let userAccount = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_USERACCOUNT)
    public static let bannedUser = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_BANNEDUSER)
    public static let userAccountCreated = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_USERACCOUNT_NEW)
    public static let userAccountRemoved = TeamTalkClientEvent(rawValue: CLIENTEVENT_CMD_USERACCOUNT_REMOVE)
    public static let userStateChanged = TeamTalkClientEvent(rawValue: CLIENTEVENT_USER_STATECHANGE)
    public static let userVideoCapture = TeamTalkClientEvent(rawValue: CLIENTEVENT_USER_VIDEOCAPTURE)
    public static let userMediaFileVideo = TeamTalkClientEvent(rawValue: CLIENTEVENT_USER_MEDIAFILE_VIDEO)
    public static let userDesktopWindow = TeamTalkClientEvent(rawValue: CLIENTEVENT_USER_DESKTOPWINDOW)
    public static let userDesktopCursor = TeamTalkClientEvent(rawValue: CLIENTEVENT_USER_DESKTOPCURSOR)
    public static let userDesktopInput = TeamTalkClientEvent(rawValue: CLIENTEVENT_USER_DESKTOPINPUT)
    public static let userRecordMediaFile = TeamTalkClientEvent(rawValue: CLIENTEVENT_USER_RECORD_MEDIAFILE)
    public static let userAudioBlock = TeamTalkClientEvent(rawValue: CLIENTEVENT_USER_AUDIOBLOCK)
    public static let internalError = TeamTalkClientEvent(rawValue: CLIENTEVENT_INTERNAL_ERROR)
    public static let voiceActivation = TeamTalkClientEvent(rawValue: CLIENTEVENT_VOICE_ACTIVATION)
    public static let hotkey = TeamTalkClientEvent(rawValue: CLIENTEVENT_HOTKEY)
    public static let hotkeyTest = TeamTalkClientEvent(rawValue: CLIENTEVENT_HOTKEY_TEST)
    public static let fileTransfer = TeamTalkClientEvent(rawValue: CLIENTEVENT_FILETRANSFER)
    public static let desktopWindowTransfer = TeamTalkClientEvent(rawValue: CLIENTEVENT_DESKTOPWINDOW_TRANSFER)
    public static let streamMediaFile = TeamTalkClientEvent(rawValue: CLIENTEVENT_STREAM_MEDIAFILE)
    public static let localMediaFile = TeamTalkClientEvent(rawValue: CLIENTEVENT_LOCAL_MEDIAFILE)
    public static let audioInput = TeamTalkClientEvent(rawValue: CLIENTEVENT_AUDIOINPUT)
    public static let userFirstVoiceStreamPacket = TeamTalkClientEvent(rawValue: CLIENTEVENT_USER_FIRSTVOICESTREAMPACKET)
    public static let soundDeviceAdded = TeamTalkClientEvent(rawValue: CLIENTEVENT_SOUNDDEVICE_ADDED)
    public static let soundDeviceRemoved = TeamTalkClientEvent(rawValue: CLIENTEVENT_SOUNDDEVICE_REMOVED)
    public static let soundDeviceUnplugged = TeamTalkClientEvent(rawValue: CLIENTEVENT_SOUNDDEVICE_UNPLUGGED)
    public static let soundDeviceNewDefaultInput = TeamTalkClientEvent(rawValue: CLIENTEVENT_SOUNDDEVICE_NEW_DEFAULT_INPUT)
    public static let soundDeviceNewDefaultOutput = TeamTalkClientEvent(rawValue: CLIENTEVENT_SOUNDDEVICE_NEW_DEFAULT_OUTPUT)
    public static let soundDeviceNewDefaultInputCommunicationDevice = TeamTalkClientEvent(rawValue: CLIENTEVENT_SOUNDDEVICE_NEW_DEFAULT_INPUT_COMDEVICE)
    public static let soundDeviceNewDefaultOutputCommunicationDevice = TeamTalkClientEvent(rawValue: CLIENTEVENT_SOUNDDEVICE_NEW_DEFAULT_OUTPUT_COMDEVICE)
}

public struct TeamTalkPayloadType: RawRepresentable, Hashable, Sendable {
    public let rawValue: TTType

    public init(rawValue: TTType) {
        self.rawValue = rawValue
    }

    public init(cValue: TTType) {
        self.init(rawValue: cValue)
    }

    public var cValue: TTType {
        rawValue
    }

    public static let none = TeamTalkPayloadType(rawValue: __NONE)
    public static let audioCodec = TeamTalkPayloadType(rawValue: __AUDIOCODEC)
    public static let bannedUser = TeamTalkPayloadType(rawValue: __BANNEDUSER)
    public static let videoFormat = TeamTalkPayloadType(rawValue: __VIDEOFORMAT)
    public static let opusCodec = TeamTalkPayloadType(rawValue: __OPUSCODEC)
    public static let channel = TeamTalkPayloadType(rawValue: __CHANNEL)
    public static let clientStatistics = TeamTalkPayloadType(rawValue: __CLIENTSTATISTICS)
    public static let clientError = TeamTalkPayloadType(rawValue: __CLIENTERRORMSG)
    public static let fileTransfer = TeamTalkPayloadType(rawValue: __FILETRANSFER)
    public static let mediaFileStatus = TeamTalkPayloadType(rawValue: __MEDIAFILESTATUS)
    public static let remoteFile = TeamTalkPayloadType(rawValue: __REMOTEFILE)
    public static let serverProperties = TeamTalkPayloadType(rawValue: __SERVERPROPERTIES)
    public static let serverStatistics = TeamTalkPayloadType(rawValue: __SERVERSTATISTICS)
    public static let soundDevice = TeamTalkPayloadType(rawValue: __SOUNDDEVICE)
    public static let speexCodec = TeamTalkPayloadType(rawValue: __SPEEXCODEC)
    public static let textMessage = TeamTalkPayloadType(rawValue: __TEXTMESSAGE)
    public static let webMVP8Codec = TeamTalkPayloadType(rawValue: __WEBMVP8CODEC)
    public static let teamTalkMessage = TeamTalkPayloadType(rawValue: __TTMESSAGE)
    public static let user = TeamTalkPayloadType(rawValue: __USER)
    public static let userAccount = TeamTalkPayloadType(rawValue: __USERACCOUNT)
    public static let userStatistics = TeamTalkPayloadType(rawValue: __USERSTATISTICS)
    public static let videoCaptureDevice = TeamTalkPayloadType(rawValue: __VIDEOCAPTUREDEVICE)
    public static let videoCodec = TeamTalkPayloadType(rawValue: __VIDEOCODEC)
    public static let audioConfig = TeamTalkPayloadType(rawValue: __AUDIOCONFIG)
    public static let speexVBRCodec = TeamTalkPayloadType(rawValue: __SPEEXVBRCODEC)
    public static let videoFrame = TeamTalkPayloadType(rawValue: __VIDEOFRAME)
    public static let audioBlock = TeamTalkPayloadType(rawValue: __AUDIOBLOCK)
    public static let audioFormat = TeamTalkPayloadType(rawValue: __AUDIOFORMAT)
    public static let mediaFileInfo = TeamTalkPayloadType(rawValue: __MEDIAFILEINFO)
    public static let boolean = TeamTalkPayloadType(rawValue: __TTBOOL)
    public static let integer = TeamTalkPayloadType(rawValue: __INT32)
    public static let desktopInput = TeamTalkPayloadType(rawValue: __DESKTOPINPUT)
    public static let speexDSP = TeamTalkPayloadType(rawValue: __SPEEXDSP)
    public static let streamType = TeamTalkPayloadType(rawValue: __STREAMTYPE)
    public static let audioPreprocessorType = TeamTalkPayloadType(rawValue: __AUDIOPREPROCESSORTYPE)
    public static let audioPreprocessor = TeamTalkPayloadType(rawValue: __AUDIOPREPROCESSOR)
    public static let teamTalkAudioPreprocessor = TeamTalkPayloadType(rawValue: __TTAUDIOPREPROCESSOR)
    public static let mediaFilePlayback = TeamTalkPayloadType(rawValue: __MEDIAFILEPLAYBACK)
    public static let clientKeepAlive = TeamTalkPayloadType(rawValue: __CLIENTKEEPALIVE)
    public static let unsignedInteger = TeamTalkPayloadType(rawValue: __UINT32)
    public static let audioInputProgress = TeamTalkPayloadType(rawValue: __AUDIOINPUTPROGRESS)
    public static let jitterConfig = TeamTalkPayloadType(rawValue: __JITTERCONFIG)
    public static let webRTCAudioPreprocessor = TeamTalkPayloadType(rawValue: __WEBRTCAUDIOPREPROCESSOR)
    public static let encryptionContext = TeamTalkPayloadType(rawValue: __ENCRYPTIONCONTEXT)
    public static let soundDeviceEffects = TeamTalkPayloadType(rawValue: __SOUNDDEVICEEFFECTS)
    public static let desktopWindow = TeamTalkPayloadType(rawValue: __DESKTOPWINDOW)
    public static let abusePrevention = TeamTalkPayloadType(rawValue: __ABUSEPREVENTION)
}

public extension TeamTalkClientFlags {
    init(cValue: ClientFlags) {
        self.init(rawValue: cValue)
    }

    var cValue: ClientFlags {
        rawValue
    }

    static let closed = TeamTalkClientFlags(rawValue: CLIENT_CLOSED.rawValue)
    static let soundOutputReady = TeamTalkClientFlags(rawValue: CLIENT_SNDOUTPUT_READY.rawValue)
    static let soundInputOutputDuplex = TeamTalkClientFlags(rawValue: CLIENT_SNDINOUTPUT_DUPLEX.rawValue)
    static let soundOutputMuted = TeamTalkClientFlags(rawValue: CLIENT_SNDOUTPUT_MUTE.rawValue)
    static let soundOutputAuto3DPosition = TeamTalkClientFlags(rawValue: CLIENT_SNDOUTPUT_AUTO3DPOSITION.rawValue)
    static let videoCaptureReady = TeamTalkClientFlags(rawValue: CLIENT_VIDEOCAPTURE_READY.rawValue)
    static let transmittingVideoCapture = TeamTalkClientFlags(rawValue: CLIENT_TX_VIDEOCAPTURE.rawValue)
    static let transmittingDesktop = TeamTalkClientFlags(rawValue: CLIENT_TX_DESKTOP.rawValue)
    static let desktopActive = TeamTalkClientFlags(rawValue: CLIENT_DESKTOP_ACTIVE.rawValue)
    static let muxingAudioFile = TeamTalkClientFlags(rawValue: CLIENT_MUX_AUDIOFILE.rawValue)
    static let connecting = TeamTalkClientFlags(rawValue: CLIENT_CONNECTING.rawValue)
    static let connection = TeamTalkClientFlags(rawValue: CLIENT_CONNECTION.rawValue)
    static let streamingAudio = TeamTalkClientFlags(rawValue: CLIENT_STREAM_AUDIO.rawValue)
    static let streamingVideo = TeamTalkClientFlags(rawValue: CLIENT_STREAM_VIDEO.rawValue)
}

public extension TeamTalkAudioCodec {
    static func makeAudioCodec(_ codec: TeamTalkCodec) -> AudioCodec {
        makeAudioCodec(codec.cValue)
    }
}

public extension TeamTalkAudioPreprocessor {
    static func makeAudioPreprocessor(_ preprocessor: TeamTalkAudioPreprocessorType) -> AudioPreprocessor {
        makeAudioPreprocessor(preprocessor.cValue)
    }
}

public extension TeamTalkClient {
    var myUserIdentifier: TeamTalkUserID {
        TeamTalkUserID(myUserID)
    }

    var myChannelIdentifier: TeamTalkChannelID {
        TeamTalkChannelID(myChannelID)
    }

    var rootChannelIdentifier: TeamTalkChannelID {
        TeamTalkChannelID(rootChannelID)
    }

    var myRights: TeamTalkUserRights {
        TeamTalkUserRights(cValue: myUserRights)
    }

    func getUserRight(_ right: TeamTalkUserRights) -> Bool {
        myRights.contains(right)
    }

    func hasUserRight(_ right: TeamTalkUserRights) -> Bool {
        getUserRight(right)
    }

    @discardableResult
    func changeStatus(mode: TeamTalkStatusMode, message: String = "") -> Int32 {
        changeStatus(mode: mode.rawValue, message: message)
    }

    func isTransmitting(_ stream: TeamTalkStreamTypes) -> Bool {
        isTransmitting(stream.cValue)
    }

    func setUserMute(userID: Int32, stream: TeamTalkStreamTypes, muted: Bool) {
        setUserMute(userID: userID, stream: stream.cValue, muted: muted)
    }

    func setUserMute(userID: TeamTalkUserID, stream: TeamTalkStreamTypes, muted: Bool) {
        setUserMute(userID: userID.cValue, stream: stream, muted: muted)
    }

    func setUserVolume(userID: Int32, stream: TeamTalkStreamTypes, volume: Int32) {
        setUserVolume(userID: userID, stream: stream.cValue, volume: volume)
    }

    func setUserVolume(userID: TeamTalkUserID, stream: TeamTalkStreamTypes, volume: Int32) {
        setUserVolume(userID: userID.cValue, stream: stream, volume: volume)
    }

    func setUserStereo(userID: Int32, stream: TeamTalkStreamTypes, leftSpeaker: Bool, rightSpeaker: Bool) {
        setUserStereo(
            userID: userID,
            stream: stream.cValue,
            leftSpeaker: leftSpeaker ? 1 : 0,
            rightSpeaker: rightSpeaker ? 1 : 0
        )
    }

    func setUserStereo(userID: TeamTalkUserID, stream: TeamTalkStreamTypes, leftSpeaker: Bool, rightSpeaker: Bool) {
        setUserStereo(userID: userID.cValue, stream: stream, leftSpeaker: leftSpeaker, rightSpeaker: rightSpeaker)
    }

    @discardableResult
    func subscribe(userID: Int32, subscriptions: TeamTalkSubscriptions) -> Int32 {
        subscribe(userID: userID, subscriptions: subscriptions.cValue)
    }

    @discardableResult
    func subscribe(userID: TeamTalkUserID, subscriptions: TeamTalkSubscriptions) -> Int32 {
        subscribe(userID: userID.cValue, subscriptions: subscriptions)
    }

    @discardableResult
    func unsubscribe(userID: Int32, subscriptions: TeamTalkSubscriptions) -> Int32 {
        unsubscribe(userID: userID, subscriptions: subscriptions.cValue)
    }

    @discardableResult
    func unsubscribe(userID: TeamTalkUserID, subscriptions: TeamTalkSubscriptions) -> Int32 {
        unsubscribe(userID: userID.cValue, subscriptions: subscriptions)
    }

    func pump(_ event: TeamTalkClientEvent, source: Int32) {
        pump(event.cValue, source: source)
    }
}

public extension AudioCodec {
    var type: TeamTalkCodec {
        get { TeamTalkCodec(cValue: nCodec) }
        set { nCodec = newValue.cValue }
    }
}

public extension AudioPreprocessor {
    var type: TeamTalkAudioPreprocessorType {
        get { TeamTalkAudioPreprocessorType(cValue: nPreprocessor) }
        set { nPreprocessor = newValue.cValue }
    }
}

public extension User {
    var id: Int32 {
        nUserID
    }

    var userID: TeamTalkUserID {
        TeamTalkUserID(id)
    }

    var channelID: Int32 {
        nChannelID
    }

    var channelIdentifier: TeamTalkChannelID {
        TeamTalkChannelID(channelID)
    }

    var username: String {
        TeamTalkString.user(.username, from: self)
    }

    var nickname: String {
        TeamTalkString.user(.nickname, from: self)
    }

    var statusMessage: String {
        TeamTalkString.user(.statusMessage, from: self)
    }

    var ipAddress: String {
        TeamTalkString.user(.ipAddress, from: self)
    }

    var clientName: String {
        TeamTalkString.user(.clientName, from: self)
    }

    var types: TeamTalkUserTypes {
        get { TeamTalkUserTypes(cValue: uUserType) }
        set { uUserType = newValue.cValue }
    }

    var localSubscriptions: TeamTalkSubscriptions {
        get { TeamTalkSubscriptions(cValue: uLocalSubscriptions) }
        set { uLocalSubscriptions = newValue.cValue }
    }

    var peerSubscriptions: TeamTalkSubscriptions {
        get { TeamTalkSubscriptions(cValue: uPeerSubscriptions) }
        set { uPeerSubscriptions = newValue.cValue }
    }

    var statusMode: TeamTalkStatusMode {
        get { TeamTalkStatusMode(rawValue: nStatusMode) }
        set { nStatusMode = newValue.rawValue }
    }

    var states: TeamTalkUserStates {
        get { TeamTalkUserStates(cValue: uUserState) }
        set { uUserState = newValue.cValue }
    }

    var isAdministrator: Bool {
        types.contains(.administrator)
    }

    var isInChannel: Bool {
        nChannelID > 0
    }

    func hasUserType(_ type: TeamTalkUserTypes) -> Bool {
        types.contains(type)
    }

    func hasSubscription(_ subscription: TeamTalkSubscriptions) -> Bool {
        localSubscriptions.contains(subscription)
    }

    func hasPeerSubscription(_ subscription: TeamTalkSubscriptions) -> Bool {
        peerSubscriptions.contains(subscription)
    }

    func hasState(_ state: TeamTalkUserStates) -> Bool {
        states.contains(state)
    }
}

public extension UserAccount {
    var username: String {
        TeamTalkString.userAccount(.username, from: self)
    }

    var password: String {
        TeamTalkString.userAccount(.password, from: self)
    }

    var initialChannel: String {
        TeamTalkString.userAccount(.initialChannel, from: self)
    }

    var note: String {
        TeamTalkString.userAccount(.note, from: self)
    }

    var lastModified: String {
        TeamTalkString.userAccount(.lastModified, from: self)
    }

    var lastLoginTime: String {
        TeamTalkString.userAccount(.lastLoginTime, from: self)
    }

    var types: TeamTalkUserTypes {
        get { TeamTalkUserTypes(cValue: uUserType) }
        set { uUserType = newValue.cValue }
    }

    var rights: TeamTalkUserRights {
        get { TeamTalkUserRights(cValue: uUserRights) }
        set { uUserRights = newValue.cValue }
    }

    var isAdministrator: Bool {
        types.contains(.administrator)
    }

    var autoOperatorChannelIDs: [Int32] {
        (0..<Int(TT_CHANNELS_OPERATOR_MAX)).compactMap { index in
            var account = self
            let channelID = TTKitGetUserAccountAutoOperatorChannel(&account, Int32(index))
            return channelID > 0 ? channelID : nil
        }
    }

    var autoOperatorChannelIdentifiers: [TeamTalkChannelID] {
        autoOperatorChannelIDs.map { TeamTalkChannelID($0) }
    }

    var commandLimit: Int32 {
        get { abusePrevent.nCommandsLimit }
        set { abusePrevent.nCommandsLimit = newValue }
    }

    var commandIntervalMilliseconds: Int32 {
        get { abusePrevent.nCommandsIntervalMSec }
        set { abusePrevent.nCommandsIntervalMSec = newValue }
    }

    func getUserRight(_ right: TeamTalkUserRights) -> Bool {
        rights.contains(right)
    }

    func hasUserRight(_ right: TeamTalkUserRights) -> Bool {
        getUserRight(right)
    }
}

public extension BannedUser {
    var ipAddress: String {
        TeamTalkString.bannedUser(.ipAddress, from: self)
    }

    var channelPath: String {
        TeamTalkString.bannedUser(.channelPath, from: self)
    }

    var banTime: String {
        TeamTalkString.bannedUser(.banTime, from: self)
    }

    var nickname: String {
        TeamTalkString.bannedUser(.nickname, from: self)
    }

    var username: String {
        TeamTalkString.bannedUser(.username, from: self)
    }

    var owner: String {
        TeamTalkString.bannedUser(.owner, from: self)
    }

    var types: TeamTalkBanTypes {
        get { TeamTalkBanTypes(cValue: uBanTypes) }
        set { uBanTypes = newValue.cValue }
    }

    func hasBanType(_ type: TeamTalkBanTypes) -> Bool {
        types.contains(type)
    }
}

public extension ServerProperties {
    var name: String {
        TeamTalkString.serverProperties(.name, from: self)
    }

    var messageOfTheDay: String {
        TeamTalkString.serverProperties(.messageOfTheDay, from: self)
    }

    var rawMessageOfTheDay: String {
        TeamTalkString.serverProperties(.rawMessageOfTheDay, from: self)
    }

    var version: String {
        TeamTalkString.serverProperties(.version, from: self)
    }

    var protocolVersion: String {
        TeamTalkString.serverProperties(.protocolVersion, from: self)
    }

    var accessToken: String {
        TeamTalkString.serverProperties(.accessToken, from: self)
    }

    var logEvents: TeamTalkServerLogEvents {
        get { TeamTalkServerLogEvents(cValue: uServerLogEvents) }
        set { uServerLogEvents = newValue.cValue }
    }

    var autoSave: Bool {
        get { bAutoSave != 0 }
        set { bAutoSave = newValue ? 1 : 0 }
    }
}

public extension UserStatistics {
    var voicePacketsReceived: Int64 {
        nVoicePacketsRecv
    }

    var voicePacketsLost: Int64 {
        nVoicePacketsLost
    }

    var videoCapturePacketsReceived: Int64 {
        nVideoCapturePacketsRecv
    }

    var videoCaptureFramesReceived: Int64 {
        nVideoCaptureFramesRecv
    }

    var videoCaptureFramesLost: Int64 {
        nVideoCaptureFramesLost
    }

    var videoCaptureFramesDropped: Int64 {
        nVideoCaptureFramesDropped
    }

    var mediaFileAudioPacketsReceived: Int64 {
        nMediaFileAudioPacketsRecv
    }

    var mediaFileAudioPacketsLost: Int64 {
        nMediaFileAudioPacketsLost
    }

    var mediaFileVideoPacketsReceived: Int64 {
        nMediaFileVideoPacketsRecv
    }

    var mediaFileVideoFramesReceived: Int64 {
        nMediaFileVideoFramesRecv
    }

    var mediaFileVideoFramesLost: Int64 {
        nMediaFileVideoFramesLost
    }

    var mediaFileVideoFramesDropped: Int64 {
        nMediaFileVideoFramesDropped
    }
}

public extension ClientStatistics {
    var udpBytesSent: Int64 {
        nUdpBytesSent
    }

    var udpBytesReceived: Int64 {
        nUdpBytesRecv
    }

    var voiceBytesSent: Int64 {
        nVoiceBytesSent
    }

    var voiceBytesReceived: Int64 {
        nVoiceBytesRecv
    }

    var videoCaptureBytesSent: Int64 {
        nVideoCaptureBytesSent
    }

    var videoCaptureBytesReceived: Int64 {
        nVideoCaptureBytesRecv
    }

    var mediaFileAudioBytesSent: Int64 {
        nMediaFileAudioBytesSent
    }

    var mediaFileAudioBytesReceived: Int64 {
        nMediaFileAudioBytesRecv
    }

    var mediaFileVideoBytesSent: Int64 {
        nMediaFileVideoBytesSent
    }

    var mediaFileVideoBytesReceived: Int64 {
        nMediaFileVideoBytesRecv
    }

    var desktopBytesSent: Int64 {
        nDesktopBytesSent
    }

    var desktopBytesReceived: Int64 {
        nDesktopBytesRecv
    }

    var udpPingTimeMilliseconds: Int32? {
        nUdpPingTimeMs >= 0 ? nUdpPingTimeMs : nil
    }

    var tcpPingTimeMilliseconds: Int32? {
        nTcpPingTimeMs >= 0 ? nTcpPingTimeMs : nil
    }

    var tcpServerSilenceSeconds: Int32 {
        nTcpServerSilenceSec
    }

    var udpServerSilenceSeconds: Int32 {
        nUdpServerSilenceSec
    }

    var soundInputDeviceDelayMilliseconds: Int32 {
        nSoundInputDeviceDelayMSec
    }
}

public extension ClientKeepAlive {
    var connectionLostMilliseconds: Int32 {
        get { nConnectionLostMSec }
        set { nConnectionLostMSec = newValue }
    }

    var tcpKeepAliveIntervalMilliseconds: Int32 {
        get { nTcpKeepAliveIntervalMSec }
        set { nTcpKeepAliveIntervalMSec = newValue }
    }

    var udpKeepAliveIntervalMilliseconds: Int32 {
        get { nUdpKeepAliveIntervalMSec }
        set { nUdpKeepAliveIntervalMSec = newValue }
    }

    var udpKeepAliveRetransmitMilliseconds: Int32 {
        get { nUdpKeepAliveRTXMSec }
        set { nUdpKeepAliveRTXMSec = newValue }
    }

    var udpConnectRetransmitMilliseconds: Int32 {
        get { nUdpConnectRTXMSec }
        set { nUdpConnectRTXMSec = newValue }
    }

    var udpConnectTimeoutMilliseconds: Int32 {
        get { nUdpConnectTimeoutMSec }
        set { nUdpConnectTimeoutMSec = newValue }
    }
}

public extension Channel {
    var id: Int32 {
        nChannelID
    }

    var channelID: TeamTalkChannelID {
        TeamTalkChannelID(id)
    }

    var parentID: Int32 {
        nParentID
    }

    var parentChannelID: TeamTalkChannelID {
        TeamTalkChannelID(parentID)
    }

    var name: String {
        TeamTalkString.channel(.name, from: self)
    }

    var topic: String {
        TeamTalkString.channel(.topic, from: self)
    }

    var password: String {
        TeamTalkString.channel(.password, from: self)
    }

    var operatorPassword: String {
        TeamTalkString.channel(.operatorPassword, from: self)
    }

    var types: TeamTalkChannelTypes {
        get { TeamTalkChannelTypes(cValue: uChannelType) }
        set { uChannelType = newValue.cValue }
    }

    var isPasswordProtected: Bool {
        bPassword != 0
    }

    var audioCodecType: TeamTalkCodec {
        get { TeamTalkCodec(cValue: audiocodec.nCodec) }
        set { audiocodec.nCodec = newValue.cValue }
    }

    var isRoot: Bool {
        nParentID == 0
    }

    func hasChannelType(_ type: TeamTalkChannelTypes) -> Bool {
        types.contains(type)
    }
}

public extension RemoteFile {
    var channelID: Int32 {
        nChannelID
    }

    var channelIdentifier: TeamTalkChannelID {
        TeamTalkChannelID(channelID)
    }

    var id: Int32 {
        nFileID
    }

    var fileID: TeamTalkFileID {
        TeamTalkFileID(id)
    }

    var name: String {
        TeamTalkString.remoteFile(.fileName, from: self)
    }

    var username: String {
        TeamTalkString.remoteFile(.username, from: self)
    }

    var uploadTime: String {
        TeamTalkString.remoteFile(.uploadTime, from: self)
    }

    var size: Int64 {
        nFileSize
    }
}

public extension FileTransfer {
    var status: TeamTalkFileTransferStatus {
        get { TeamTalkFileTransferStatus(cValue: nStatus) }
        set { nStatus = newValue.cValue }
    }

    var id: Int32 {
        nTransferID
    }

    var transferID: TeamTalkTransferID {
        TeamTalkTransferID(id)
    }

    var channelID: Int32 {
        nChannelID
    }

    var channelIdentifier: TeamTalkChannelID {
        TeamTalkChannelID(channelID)
    }

    var localFilePath: String {
        TeamTalkString.fileTransfer(.localFilePath, from: self)
    }

    var remoteFileName: String {
        TeamTalkString.fileTransfer(.remoteFileName, from: self)
    }

    var isDownload: Bool {
        bInbound != 0
    }

    var progress: Double {
        guard nFileSize > 0 else { return 0 }
        return min(1, max(0, Double(nTransferred) / Double(nFileSize)))
    }
}

public extension TextMessage {
    var type: TeamTalkTextMessageType {
        get { TeamTalkTextMessageType(cValue: nMsgType) }
        set { nMsgType = newValue.cValue }
    }

    var content: String {
        TeamTalkString.textMessage(self)
    }
}

public extension TTMessage {
    var source: Int32 {
        nSource
    }

    var event: TeamTalkClientEvent {
        get { TeamTalkClientEvent(cValue: nClientEvent) }
        set { nClientEvent = newValue.cValue }
    }

    var payloadType: TeamTalkPayloadType {
        get { TeamTalkPayloadType(cValue: ttType) }
        set { ttType = newValue.cValue }
    }

    var streamType: TeamTalkStreamTypes {
        get { TeamTalkStreamTypes(cValue: nStreamType) }
        set { nStreamType = newValue.cValue }
    }

    var isActive: Bool {
        TeamTalkMessagePayload.isActive(self)
    }
}
