import Foundation
import TeamTalkC

public protocol TeamTalkMessageObserver: AnyObject {
    func handleTeamTalkMessage(_ message: TTMessage)
}

public protocol TeamTalkEventObserver: AnyObject {
    func handleTeamTalkEvent(_ event: TeamTalkEvent)
}

final class TeamTalkMessageHandler {
    weak var value: TeamTalkMessageObserver?

    init(value: TeamTalkMessageObserver) {
        self.value = value
    }
}

final class TeamTalkEventHandler {
    weak var value: TeamTalkEventObserver?

    init(value: TeamTalkEventObserver) {
        self.value = value
    }
}

final class TeamTalkAsyncEventObserver: TeamTalkEventObserver {
    private let handler: (TeamTalkEvent) -> Void

    init(handler: @escaping (TeamTalkEvent) -> Void) {
        self.handler = handler
    }

    func handleTeamTalkEvent(_ event: TeamTalkEvent) {
        handler(event)
    }
}

func withOptionalVideoCodecPointer<Result>(
    _ videoCodec: VideoCodec?,
    _ body: (UnsafePointer<VideoCodec>?) -> Result
) -> Result {
    guard var videoCodec else {
        return body(nil)
    }

    return withUnsafePointer(to: &videoCodec) { pointer in
        body(pointer)
    }
}

func withOptionalAudioFormatPointer<Result>(
    _ audioFormat: AudioFormat?,
    _ body: (UnsafePointer<AudioFormat>?) -> Result
) -> Result {
    guard var audioFormat else {
        return body(nil)
    }

    return withUnsafePointer(to: &audioFormat) { pointer in
        body(pointer)
    }
}

public struct TeamTalkClientFlags: OptionSet {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let connected = TeamTalkClientFlags(rawValue: CLIENT_CONNECTED.rawValue)
    public static let authorized = TeamTalkClientFlags(rawValue: CLIENT_AUTHORIZED.rawValue)
    public static let soundInputReady = TeamTalkClientFlags(rawValue: CLIENT_SNDINPUT_READY.rawValue)
    public static let transmittingVoice = TeamTalkClientFlags(rawValue: CLIENT_TX_VOICE.rawValue)
    public static let voiceActivated = TeamTalkClientFlags(rawValue: CLIENT_SNDINPUT_VOICEACTIVATED.rawValue)
    public static let voiceActive = TeamTalkClientFlags(rawValue: CLIENT_SNDINPUT_VOICEACTIVE.rawValue)
}

public struct TeamTalkEncryptionConfiguration {
    public var caCertificate: String
    public var certificate: String
    public var privateKey: String
    public var verifyPeer: Bool

    public init(
        caCertificate: String = "",
        certificate: String = "",
        privateKey: String = "",
        verifyPeer: Bool = false
    ) {
        self.caCertificate = caCertificate
        self.certificate = certificate
        self.privateKey = privateKey
        self.verifyPeer = verifyPeer
    }
}

public final class TeamTalkClient {
    public static let shared = TeamTalkClient()

    var instance: UnsafeMutableRawPointer?
    var observers = [TeamTalkMessageHandler]()
    var eventObservers = [TeamTalkEventHandler]()

    private init() {}

    public static func touchLinkerSymbolsForTests() {
        if TT_GetRootChannelID(nil) == 1 {
            TT_CloseSoundOutputDevice(nil)
            TT_StartSoundLoopbackTest(0, 0, 0, 0, 0, nil)
            TT_CloseSoundLoopbackTest(nil)
            TT_CloseSoundInputDevice(nil)
            TT_GetSoundDevices(nil, nil)
            var defaultInputDeviceID: Int32 = 0
            var defaultOutputDeviceID: Int32 = 0
            TT_GetDefaultSoundDevices(&defaultInputDeviceID, &defaultOutputDeviceID)
            TT_GetDefaultSoundDevicesEx(SOUNDSYSTEM_NONE, &defaultInputDeviceID, &defaultOutputDeviceID)
            TT_InitSoundInputSharedDevice(0, 0, 0)
            TT_InitSoundOutputSharedDevice(0, 0, 0)
            TT_InitSoundDuplexDevices(nil, 0, 0)
            TT_CloseSoundDuplexDevices(nil)
            var soundDeviceEffects = SoundDeviceEffects()
            TT_GetSoundDeviceEffects(nil, &soundDeviceEffects)
            TT_SetSoundDeviceEffects(nil, &soundDeviceEffects)
            var speexDSP = SpeexDSP()
            TT_GetSoundInputPreprocess(nil, &speexDSP)
            TT_SetSoundInputPreprocess(nil, &speexDSP)
            var audioPreprocessor = AudioPreprocessor()
            TT_GetSoundInputPreprocessEx(nil, &audioPreprocessor)
            TT_SetSoundInputPreprocessEx(nil, &audioPreprocessor)
            TT_StartStreamingMediaFileToChannel(nil, "", nil)
            var mediaPlayback = MediaFilePlayback()
            TT_StartStreamingMediaFileToChannelEx(nil, "", &mediaPlayback, nil)
            TT_UpdateStreamingMediaFileToChannel(nil, &mediaPlayback, nil)
            TT_StopStreamingMediaFileToChannel(nil)
            let playbackSessionID = TT_InitLocalPlayback(nil, "", &mediaPlayback)
            TT_UpdateLocalPlayback(nil, playbackSessionID, &mediaPlayback)
            TT_StopLocalPlayback(nil, playbackSessionID)
            var mediaFileInfo = MediaFileInfo()
            TT_GetMediaFileInfo("", &mediaFileInfo)
            var desktopWindow = DesktopWindow()
            TT_SendDesktopWindow(nil, &desktopWindow, BMP_NONE)
            TT_CloseDesktopWindow(nil)
            TT_SendDesktopCursorPosition(nil, 0, 0)
            var desktopInput = DesktopInput()
            TT_SendDesktopInput(nil, 0, &desktopInput, 1)
            let acquiredDesktopWindow = TT_AcquireUserDesktopWindow(nil, 0)
            let acquiredDesktopWindowEx = TT_AcquireUserDesktopWindowEx(nil, 0, BMP_NONE)
            TT_ReleaseUserDesktopWindow(nil, acquiredDesktopWindow)
            TT_ReleaseUserDesktopWindow(nil, acquiredDesktopWindowEx)
            var videoCaptureDeviceCount: Int32 = 0
            TT_GetVideoCaptureDevices(nil, &videoCaptureDeviceCount)
            var videoFormat = VideoFormat()
            TT_InitVideoCaptureDevice(nil, "", &videoFormat)
            TT_CloseVideoCaptureDevice(nil)
            TT_SetUserMediaStorageDir(nil, 0, "", "", AFF_NONE)
            TT_SetUserMediaStorageDirEx(nil, 0, "", "", AFF_NONE, 0)
            var audioCodec = AudioCodec()
            TT_StartRecordingMuxedAudioFile(nil, &audioCodec, "", AFF_NONE)
            TT_StartRecordingMuxedAudioFileEx(nil, 0, "", AFF_NONE)
            TT_StartRecordingMuxedStreams(nil, STREAMTYPE_NONE.rawValue, &audioCodec, "", AFF_NONE)
            TT_StopRecordingMuxedAudioFile(nil)
            TT_StopRecordingMuxedAudioFileEx(nil, 0)
            var audioFormat = AudioFormat()
            TT_EnableAudioBlockEventEx(nil, 0, STREAMTYPE_NONE.rawValue, &audioFormat, 0)
            var audioBlock = AudioBlock()
            TT_InsertAudioBlock(nil, &audioBlock)
            let acquiredAudioBlock = TT_AcquireUserAudioBlock(nil, STREAMTYPE_NONE.rawValue, 0)
            TT_ReleaseUserAudioBlock(nil, acquiredAudioBlock)
            TT_DoLeaveChannel(nil)
            TT_GetRootChannelID(nil)
            TT_DBG_SetSoundInputTone(nil, 0, 0)
            TT_DoLogin(nil, "", "", "")
            TT_RestartSoundSystem()
            TT_DoSendFile(nil, 0, "")
            TT_DoRecvFile(nil, 0, 0, "")
            TT_DoDeleteFile(nil, 0, 0)
            var count: Int32 = 0
            TT_GetChannelFiles(nil, 0, nil, &count)
            var remoteFile = RemoteFile()
            TT_GetChannelFile(nil, 0, 0, &remoteFile)
            var fileTransfer = FileTransfer()
            TT_GetFileTransferInfo(nil, 0, &fileTransfer)
            TT_CancelFileTransfer(nil, 0)
            var clientStatistics = ClientStatistics()
            TT_GetClientStatistics(nil, &clientStatistics)
            var clientKeepAlive = ClientKeepAlive()
            TT_GetClientKeepAlive(nil, &clientKeepAlive)
            TT_SetClientKeepAlive(nil, &clientKeepAlive)
            var userStatistics = UserStatistics()
            TT_GetUserStatistics(nil, 0, &userStatistics)
        }
    }

    public var flags: TeamTalkClientFlags {
        TeamTalkClientFlags(rawValue: TT_GetFlags(instance))
    }

    public var isConnected: Bool {
        flags.contains(.connected)
    }

    public var isSoundInputReady: Bool {
        flags.contains(.soundInputReady)
    }

    public var isAuthorized: Bool {
        flags.contains(.authorized)
    }

    public var isVoiceTransmitting: Bool {
        isTransmitting(STREAMTYPE_VOICE)
    }

    public var myUserID: Int32 {
        TT_GetMyUserID(instance)
    }

    public var myChannelID: Int32 {
        TT_GetMyChannelID(instance)
    }

    public var myUserRights: UInt32 {
        TT_GetMyUserRights(instance)
    }

    public var myTypes: TeamTalkUserTypes {
        TeamTalkUserTypes(cValue: TT_GetMyUserType(instance))
    }

    public var myUserData: Int32 {
        TT_GetMyUserData(instance)
    }

    public var rootChannelID: Int32 {
        TT_GetRootChannelID(instance)
    }

    public var soundOutputVolume: Int32 {
        TT_GetSoundOutputVolume(instance)
    }

    public var soundInputGainLevel: Int32 {
        TT_GetSoundInputGainLevel(instance)
    }

    public var version: String {
        String(cString: TT_GetVersion())
    }

}
