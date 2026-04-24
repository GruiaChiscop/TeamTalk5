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

private final class TeamTalkAsyncEventObserver: TeamTalkEventObserver {
    private let handler: (TeamTalkEvent) -> Void

    init(handler: @escaping (TeamTalkEvent) -> Void) {
        self.handler = handler
    }

    func handleTeamTalkEvent(_ event: TeamTalkEvent) {
        handler(event)
    }
}

private func withOptionalVideoCodecPointer<Result>(
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

private func withOptionalAudioFormatPointer<Result>(
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

    private var instance: UnsafeMutableRawPointer?
    private var observers = [TeamTalkMessageHandler]()
    private var eventObservers = [TeamTalkEventHandler]()

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

    public func soundDevicesInfo() -> [SoundDevice] {
        var count: Int32 = 0
        guard TT_GetSoundDevices(nil, &count) != 0, count > 0 else {
            return []
        }

        var devices = Array(repeating: SoundDevice(), count: Int(count))
        var deviceCount = count
        let didRead = devices.withUnsafeMutableBufferPointer { buffer in
            TT_GetSoundDevices(buffer.baseAddress, &deviceCount) != 0
        }
        guard didRead else {
            return []
        }

        let returnedCount = max(0, min(Int(deviceCount), devices.count))
        if returnedCount < devices.count {
            devices.removeLast(devices.count - returnedCount)
        }
        return devices
    }

    public func soundDevices() -> [TeamTalkSoundDevice] {
        soundDevicesInfo().map(TeamTalkSoundDevice.init)
    }

    public func defaultSoundDevices() -> (input: TeamTalkSoundDeviceID, output: TeamTalkSoundDeviceID)? {
        var inputDeviceID: Int32 = 0
        var outputDeviceID: Int32 = 0
        guard TT_GetDefaultSoundDevices(&inputDeviceID, &outputDeviceID) != 0 else {
            return nil
        }
        return (TeamTalkSoundDeviceID(inputDeviceID), TeamTalkSoundDeviceID(outputDeviceID))
    }

    public func defaultSoundDevices(for soundSystem: TeamTalkSoundSystem) -> (input: TeamTalkSoundDeviceID, output: TeamTalkSoundDeviceID)? {
        var inputDeviceID: Int32 = 0
        var outputDeviceID: Int32 = 0
        guard TT_GetDefaultSoundDevicesEx(soundSystem.cValue, &inputDeviceID, &outputDeviceID) != 0 else {
            return nil
        }
        return (TeamTalkSoundDeviceID(inputDeviceID), TeamTalkSoundDeviceID(outputDeviceID))
    }

    @discardableResult
    public func restartSoundSystem() -> Bool {
        TT_RestartSoundSystem() != 0
    }

    public func soundDeviceEffectsInfo() -> SoundDeviceEffects? {
        guard let instance else {
            return nil
        }

        var effects = SoundDeviceEffects()
        guard TT_GetSoundDeviceEffects(instance, &effects) != 0 else {
            return nil
        }
        return effects
    }

    public func soundDeviceEffects() -> TeamTalkSoundDeviceEffects? {
        soundDeviceEffectsInfo().map(TeamTalkSoundDeviceEffects.init)
    }

    @discardableResult
    public func setSoundDeviceEffects(_ effects: inout SoundDeviceEffects) -> Bool {
        guard let instance else {
            return false
        }

        return TT_SetSoundDeviceEffects(instance, &effects) != 0
    }

    @discardableResult
    public func setSoundDeviceEffects(_ configuration: TeamTalkSoundDeviceEffectsConfiguration) -> Bool {
        var effects = configuration.cValue
        return setSoundDeviceEffects(&effects)
    }

    @discardableResult
    public func setSoundDeviceEffects(_ effects: TeamTalkSoundDeviceEffects) -> Bool {
        var rawEffects = effects.cValue
        return setSoundDeviceEffects(&rawEffects)
    }

    @discardableResult
    public func initSoundInputSharedDevice(sampleRate: Int32, channels: Int32, frameSize: Int32) -> Bool {
        TT_InitSoundInputSharedDevice(sampleRate, channels, frameSize) != 0
    }

    @discardableResult
    public func initSoundInputSharedDevice(_ configuration: TeamTalkSharedSoundDeviceConfiguration) -> Bool {
        initSoundInputSharedDevice(
            sampleRate: configuration.sampleRate,
            channels: configuration.channels,
            frameSize: configuration.frameSize
        )
    }

    @discardableResult
    public func initSoundOutputSharedDevice(sampleRate: Int32, channels: Int32, frameSize: Int32) -> Bool {
        TT_InitSoundOutputSharedDevice(sampleRate, channels, frameSize) != 0
    }

    @discardableResult
    public func initSoundOutputSharedDevice(_ configuration: TeamTalkSharedSoundDeviceConfiguration) -> Bool {
        initSoundOutputSharedDevice(
            sampleRate: configuration.sampleRate,
            channels: configuration.channels,
            frameSize: configuration.frameSize
        )
    }

    @discardableResult
    public func initSoundDuplexDevices(inputDeviceID: Int32, outputDeviceID: Int32) -> Bool {
        guard let instance else {
            return false
        }

        return TT_InitSoundDuplexDevices(instance, inputDeviceID, outputDeviceID) != 0
    }

    @discardableResult
    public func initSoundDuplexDevices(inputDeviceID: TeamTalkSoundDeviceID, outputDeviceID: TeamTalkSoundDeviceID) -> Bool {
        initSoundDuplexDevices(inputDeviceID: inputDeviceID.cValue, outputDeviceID: outputDeviceID.cValue)
    }

    @discardableResult
    public func initSoundDuplexDevices(_ configuration: TeamTalkSoundDuplexConfiguration) -> Bool {
        initSoundDuplexDevices(
            inputDeviceID: configuration.inputDeviceRawID,
            outputDeviceID: configuration.outputDeviceRawID
        )
    }

    @discardableResult
    public func closeSoundDuplexDevices() -> Bool {
        guard let instance else {
            return false
        }

        return TT_CloseSoundDuplexDevices(instance) != 0
    }

    public func start(licenseName: String, licenseKey: String) {
        guard instance == nil else {
            return
        }

        TT_SetLicenseInformation(licenseName, licenseKey)
        instance = TT_InitTeamTalkPoll()
    }

    public func close() {
        guard let instance else {
            return
        }

        TT_CloseTeamTalk(instance)
        self.instance = nil
        observers.removeAll()
        eventObservers.removeAll()
    }

    @discardableResult
    public func connect(toHost host: String, tcpPort: Int32, udpPort: Int32, encrypted: Bool) -> Bool {
        TT_Connect(instance, host, tcpPort, udpPort, 0, 0, encrypted ? 1 : 0) != 0
    }

    public func disconnect() {
        TT_Disconnect(instance)
    }

    @discardableResult
    public func login(nickname: String, username: String, password: String, clientName: String) -> Int32 {
        TT_DoLoginEx(instance, nickname, username, password, clientName)
    }

    public func channelID(fromPath path: String) -> Int32 {
        TT_GetChannelIDFromPath(instance, path)
    }

    public func channelIdentifier(fromPath path: String) -> TeamTalkChannelID {
        TeamTalkChannelID(channelID(fromPath: path))
    }

    public func isChannelOperator(userID: Int32? = nil, channelID: Int32) -> Bool {
        TT_IsChannelOperator(instance, userID ?? myUserID, channelID) != 0
    }

    public func isChannelOperator(userID: TeamTalkUserID? = nil, channelID: TeamTalkChannelID) -> Bool {
        isChannelOperator(userID: userID?.cValue, channelID: channelID.cValue)
    }

    public func withServerProperties<T>(_ body: (inout ServerProperties) -> T) -> T {
        var properties = ServerProperties()
        TT_GetServerProperties(instance, &properties)
        return body(&properties)
    }

    public func withChannel<T>(id channelID: Int32, _ body: (inout Channel) -> T) -> T {
        var channel = Channel()
        TT_GetChannel(instance, channelID, &channel)
        return body(&channel)
    }

    public func withChannel<T>(id channelID: TeamTalkChannelID, _ body: (inout Channel) -> T) -> T {
        withChannel(id: channelID.cValue, body)
    }

    public func withUser<T>(id userID: Int32, _ body: (inout User) -> T) -> T {
        var user = User()
        TT_GetUser(instance, userID, &user)
        return body(&user)
    }

    public func withUser<T>(id userID: TeamTalkUserID, _ body: (inout User) -> T) -> T {
        withUser(id: userID.cValue, body)
    }

    public func serverProperties() -> TeamTalkServerProperties? {
        guard let instance else {
            return nil
        }

        var properties = ServerProperties()
        guard TT_GetServerProperties(instance, &properties) != 0 else {
            return nil
        }
        return TeamTalkServerProperties(properties)
    }

    public func currentUserAccount() -> TeamTalkUserAccount? {
        guard let instance else {
            return nil
        }

        var account = UserAccount()
        guard TT_GetMyUserAccount(instance, &account) != 0 else {
            return nil
        }
        return TeamTalkUserAccount(account)
    }

    public func clientStatisticsInfo() -> ClientStatistics? {
        guard let instance else {
            return nil
        }

        var statistics = ClientStatistics()
        guard TT_GetClientStatistics(instance, &statistics) != 0 else {
            return nil
        }
        return statistics
    }

    public func clientStatistics() -> TeamTalkClientStatistics? {
        clientStatisticsInfo().map(TeamTalkClientStatistics.init)
    }

    public func clientKeepAliveInfo() -> ClientKeepAlive? {
        guard let instance else {
            return nil
        }

        var keepAlive = ClientKeepAlive()
        guard TT_GetClientKeepAlive(instance, &keepAlive) != 0 else {
            return nil
        }
        return keepAlive
    }

    public func clientKeepAlive() -> TeamTalkClientKeepAlive? {
        clientKeepAliveInfo().map(TeamTalkClientKeepAlive.init)
    }

    @discardableResult
    public func setClientKeepAlive(_ keepAlive: inout ClientKeepAlive) -> Bool {
        guard let instance else {
            return false
        }

        return TT_SetClientKeepAlive(instance, &keepAlive) != 0
    }

    @discardableResult
    public func setClientKeepAlive(_ configuration: TeamTalkClientKeepAliveConfiguration) -> Bool {
        var keepAlive = configuration.cValue
        return setClientKeepAlive(&keepAlive)
    }

    @discardableResult
    public func setClientKeepAlive(_ keepAlive: TeamTalkClientKeepAlive) -> Bool {
        var rawKeepAlive = keepAlive.cValue
        return setClientKeepAlive(&rawKeepAlive)
    }

    public func userStatisticsInfo(id userID: Int32) -> UserStatistics? {
        guard let instance else {
            return nil
        }

        var statistics = UserStatistics()
        guard TT_GetUserStatistics(instance, userID, &statistics) != 0 else {
            return nil
        }
        return statistics
    }

    public func userStatisticsInfo(id userID: TeamTalkUserID) -> UserStatistics? {
        userStatisticsInfo(id: userID.cValue)
    }

    public func userStatistics(id userID: Int32) -> TeamTalkUserStatistics? {
        userStatisticsInfo(id: userID).map(TeamTalkUserStatistics.init)
    }

    public func userStatistics(id userID: TeamTalkUserID) -> TeamTalkUserStatistics? {
        userStatistics(id: userID.cValue)
    }

    public func serverUsers() -> [TeamTalkUser] {
        guard let instance else {
            return []
        }

        var count: Int32 = 0
        guard TT_GetServerUsers(instance, nil, &count) != 0, count > 0 else {
            return []
        }

        var users = Array(repeating: User(), count: Int(count))
        var userCount = count
        let didRead = users.withUnsafeMutableBufferPointer { buffer in
            TT_GetServerUsers(instance, buffer.baseAddress, &userCount) != 0
        }
        guard didRead else {
            return []
        }

        return users.prefix(Int(max(0, min(userCount, count)))).map(TeamTalkUser.init)
    }

    public func channels() -> [TeamTalkChannel] {
        guard let instance else {
            return []
        }

        var count: Int32 = 0
        guard TT_GetServerChannels(instance, nil, &count) != 0, count > 0 else {
            return []
        }

        var channels = Array(repeating: Channel(), count: Int(count))
        var channelCount = count
        let didRead = channels.withUnsafeMutableBufferPointer { buffer in
            TT_GetServerChannels(instance, buffer.baseAddress, &channelCount) != 0
        }
        guard didRead else {
            return []
        }

        return channels.prefix(Int(max(0, min(channelCount, count)))).map(TeamTalkChannel.init)
    }

    public func users(inChannelID channelID: Int32) -> [TeamTalkUser] {
        guard let instance else {
            return []
        }

        var count: Int32 = 0
        guard TT_GetChannelUsers(instance, channelID, nil, &count) != 0, count > 0 else {
            return []
        }

        var users = Array(repeating: User(), count: Int(count))
        var userCount = count
        let didRead = users.withUnsafeMutableBufferPointer { buffer in
            TT_GetChannelUsers(instance, channelID, buffer.baseAddress, &userCount) != 0
        }
        guard didRead else {
            return []
        }

        return users.prefix(Int(max(0, min(userCount, count)))).map(TeamTalkUser.init)
    }

    public func users(inChannelID channelID: TeamTalkChannelID) -> [TeamTalkUser] {
        users(inChannelID: channelID.cValue)
    }

    public func channel(id channelID: Int32) -> TeamTalkChannel? {
        guard let instance else {
            return nil
        }

        var channel = Channel()
        guard TT_GetChannel(instance, channelID, &channel) != 0 else {
            return nil
        }
        return TeamTalkChannel(channel)
    }

    public func channel(id channelID: TeamTalkChannelID) -> TeamTalkChannel? {
        channel(id: channelID.cValue)
    }

    public func user(id userID: Int32) -> TeamTalkUser? {
        guard let instance else {
            return nil
        }

        var user = User()
        guard TT_GetUser(instance, userID, &user) != 0 else {
            return nil
        }
        return TeamTalkUser(user)
    }

    public func user(id userID: TeamTalkUserID) -> TeamTalkUser? {
        user(id: userID.cValue)
    }

    public func user(username: String) -> TeamTalkUser? {
        guard let instance else {
            return nil
        }

        var user = User()
        guard TT_GetUserByUsername(instance, username, &user) != 0 else {
            return nil
        }
        return TeamTalkUser(user)
    }

    public func channelFiles(in channelID: Int32) -> [RemoteFile] {
        guard let instance else {
            return []
        }

        var count: Int32 = 0
        guard TT_GetChannelFiles(instance, channelID, nil, &count) != 0, count > 0 else {
            return []
        }

        var files = Array(repeating: RemoteFile(), count: Int(count))
        var fileCount = count
        let didRead = files.withUnsafeMutableBufferPointer { buffer in
            TT_GetChannelFiles(instance, channelID, buffer.baseAddress, &fileCount) != 0
        }
        guard didRead else {
            return []
        }

        let returnedCount = max(0, min(Int(fileCount), files.count))
        if returnedCount < files.count {
            files.removeLast(files.count - returnedCount)
        }
        return files
    }

    public func channelFiles(in channelID: TeamTalkChannelID) -> [RemoteFile] {
        channelFiles(in: channelID.cValue)
    }

    public func channelFile(channelID: Int32, fileID: Int32) -> RemoteFile? {
        guard let instance else {
            return nil
        }

        var file = RemoteFile()
        guard TT_GetChannelFile(instance, channelID, fileID, &file) != 0 else {
            return nil
        }
        return file
    }

    public func channelFile(channelID: TeamTalkChannelID, fileID: TeamTalkFileID) -> RemoteFile? {
        channelFile(channelID: channelID.cValue, fileID: fileID.cValue)
    }

    public func remoteFiles(in channelID: Int32) -> [TeamTalkRemoteFile] {
        channelFiles(in: channelID).map(TeamTalkRemoteFile.init)
    }

    public func remoteFiles(in channelID: TeamTalkChannelID) -> [TeamTalkRemoteFile] {
        remoteFiles(in: channelID.cValue)
    }

    public func remoteFile(channelID: Int32, fileID: Int32) -> TeamTalkRemoteFile? {
        channelFile(channelID: channelID, fileID: fileID).map(TeamTalkRemoteFile.init)
    }

    public func remoteFile(channelID: TeamTalkChannelID, fileID: TeamTalkFileID) -> TeamTalkRemoteFile? {
        remoteFile(channelID: channelID.cValue, fileID: fileID.cValue)
    }

    @discardableResult
    public func ping() -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoPing(instance))
    }

    @discardableResult
    public func logIn(nickname: String, username: String, password: String, clientName: String = "") -> TeamTalkCommandID {
        TeamTalkCommandID(login(nickname: nickname, username: username, password: password, clientName: clientName))
    }

    @discardableResult
    public func logOut() -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoLogout(instance))
    }

    @discardableResult
    public func join(_ channel: TeamTalkChannel) -> TeamTalkCommandID {
        var channel = channel.cValue
        return TeamTalkCommandID(TT_DoJoinChannel(instance, &channel))
    }

    @discardableResult
    public func join(_ configuration: TeamTalkChannelConfiguration) -> TeamTalkCommandID {
        var channel = configuration.cValue
        return TeamTalkCommandID(TT_DoJoinChannel(instance, &channel))
    }

    @discardableResult
    public func joinChannel(withID channelID: Int32, password: String = "") -> TeamTalkCommandID {
        TeamTalkCommandID(joinChannel(id: channelID, password: password))
    }

    @discardableResult
    public func joinChannel(withID channelID: TeamTalkChannelID, password: String = "") -> TeamTalkCommandID {
        joinChannel(withID: channelID.cValue, password: password)
    }

    @discardableResult
    public func leaveChannel() -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoLeaveChannel(instance))
    }

    @discardableResult
    public func createChannel(_ configuration: TeamTalkChannelConfiguration) -> TeamTalkCommandID {
        var channel = configuration.cValue
        return TeamTalkCommandID(TT_DoMakeChannel(instance, &channel))
    }

    @discardableResult
    public func updateChannel(_ channel: TeamTalkChannel) -> TeamTalkCommandID {
        var channel = channel.cValue
        return TeamTalkCommandID(TT_DoUpdateChannel(instance, &channel))
    }

    @discardableResult
    public func updateChannel(_ configuration: TeamTalkChannelConfiguration) -> TeamTalkCommandID {
        var channel = configuration.cValue
        return TeamTalkCommandID(TT_DoUpdateChannel(instance, &channel))
    }

    @discardableResult
    public func removeChannel(withID channelID: Int32) -> TeamTalkCommandID {
        TeamTalkCommandID(removeChannel(id: channelID))
    }

    @discardableResult
    public func removeChannel(withID channelID: TeamTalkChannelID) -> TeamTalkCommandID {
        removeChannel(withID: channelID.cValue)
    }

    @discardableResult
    public func setNickname(_ nickname: String) -> TeamTalkCommandID {
        TeamTalkCommandID(changeNickname(nickname))
    }

    @discardableResult
    public func setStatus(mode: TeamTalkStatusMode, message: String = "") -> TeamTalkCommandID {
        TeamTalkCommandID(changeStatus(mode: mode.rawValue, message: message))
    }

    @discardableResult
    public func sendTextMessage(_ message: TeamTalkOutgoingTextMessage) -> [TeamTalkCommandID] {
        TeamTalkTextMessageFactory.messages(from: message.cValue, content: message.content).map { textMessage in
            var textMessage = textMessage
            return TeamTalkCommandID(TT_DoTextMessage(instance, &textMessage))
        }
    }

    @discardableResult
    public func setChannelOperator(userID: Int32, channelID: Int32, enabled: Bool) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoChannelOp(instance, userID, channelID, enabled ? 1 : 0))
    }

    @discardableResult
    public func setChannelOperator(userID: TeamTalkUserID, channelID: TeamTalkChannelID, enabled: Bool) -> TeamTalkCommandID {
        setChannelOperator(userID: userID.cValue, channelID: channelID.cValue, enabled: enabled)
    }

    @discardableResult
    public func setChannelOperator(userID: Int32, channelID: Int32, operatorPassword: String, enabled: Bool) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoChannelOpEx(instance, userID, channelID, operatorPassword, enabled ? 1 : 0))
    }

    @discardableResult
    public func setChannelOperator(
        userID: TeamTalkUserID,
        channelID: TeamTalkChannelID,
        operatorPassword: String,
        enabled: Bool
    ) -> TeamTalkCommandID {
        setChannelOperator(
            userID: userID.cValue,
            channelID: channelID.cValue,
            operatorPassword: operatorPassword,
            enabled: enabled
        )
    }

    @discardableResult
    public func kickUser(withID userID: Int32, fromChannelID channelID: Int32 = 0) -> TeamTalkCommandID {
        TeamTalkCommandID(kickUser(id: userID, fromChannelID: channelID))
    }

    @discardableResult
    public func kickUser(withID userID: TeamTalkUserID, fromChannelID channelID: TeamTalkChannelID = .none) -> TeamTalkCommandID {
        kickUser(withID: userID.cValue, fromChannelID: channelID.cValue)
    }

    @discardableResult
    public func banUser(withID userID: Int32, fromChannelID channelID: Int32 = 0) -> TeamTalkCommandID {
        TeamTalkCommandID(banUser(id: userID, fromChannelID: channelID))
    }

    @discardableResult
    public func banUser(withID userID: TeamTalkUserID, fromChannelID channelID: TeamTalkChannelID = .none) -> TeamTalkCommandID {
        banUser(withID: userID.cValue, fromChannelID: channelID.cValue)
    }

    @discardableResult
    public func banUser(withID userID: Int32, types: TeamTalkBanTypes) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoBanUserEx(instance, userID, types.cValue))
    }

    @discardableResult
    public func banUser(withID userID: TeamTalkUserID, types: TeamTalkBanTypes) -> TeamTalkCommandID {
        banUser(withID: userID.cValue, types: types)
    }

    @discardableResult
    public func ban(_ configuration: TeamTalkBanConfiguration) -> TeamTalkCommandID {
        var bannedUser = configuration.cValue
        return TeamTalkCommandID(TT_DoBan(instance, &bannedUser))
    }

    @discardableResult
    public func banIPAddress(_ ipAddress: String, channelID: Int32 = 0) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoBanIPAddress(instance, ipAddress, channelID))
    }

    @discardableResult
    public func banIPAddress(_ ipAddress: String, channelID: TeamTalkChannelID = .none) -> TeamTalkCommandID {
        banIPAddress(ipAddress, channelID: channelID.cValue)
    }

    @discardableResult
    public func unbanIPAddress(_ ipAddress: String, channelID: Int32 = 0) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoUnBanUser(instance, ipAddress, channelID))
    }

    @discardableResult
    public func unbanIPAddress(_ ipAddress: String, channelID: TeamTalkChannelID = .none) -> TeamTalkCommandID {
        unbanIPAddress(ipAddress, channelID: channelID.cValue)
    }

    @discardableResult
    public func unban(_ configuration: TeamTalkBanConfiguration) -> TeamTalkCommandID {
        var bannedUser = configuration.cValue
        return TeamTalkCommandID(TT_DoUnBanUserEx(instance, &bannedUser))
    }

    @discardableResult
    public func listBans(channelID: Int32 = 0, startingAt index: Int32 = 0, count: Int32 = 100) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoListBans(instance, channelID, index, count))
    }

    @discardableResult
    public func listBans(channelID: TeamTalkChannelID = .none, startingAt index: Int32 = 0, count: Int32 = 100) -> TeamTalkCommandID {
        listBans(channelID: channelID.cValue, startingAt: index, count: count)
    }

    @discardableResult
    public func moveUser(withID userID: Int32, toChannelID channelID: Int32) -> TeamTalkCommandID {
        TeamTalkCommandID(moveUser(id: userID, toChannelID: channelID))
    }

    @discardableResult
    public func moveUser(withID userID: TeamTalkUserID, toChannelID channelID: TeamTalkChannelID) -> TeamTalkCommandID {
        moveUser(withID: userID.cValue, toChannelID: channelID.cValue)
    }

    @discardableResult
    public func uploadFileCommand(at localURL: URL, toChannelID channelID: Int32) -> TeamTalkCommandID {
        TeamTalkCommandID(uploadFile(at: localURL, toChannelID: channelID))
    }

    @discardableResult
    public func uploadFileCommand(at localURL: URL, toChannelID channelID: TeamTalkChannelID) -> TeamTalkCommandID {
        uploadFileCommand(at: localURL, toChannelID: channelID.cValue)
    }

    @discardableResult
    public func uploadFile(at localURL: URL, to channel: TeamTalkChannel) -> TeamTalkCommandID {
        uploadFileCommand(at: localURL, toChannelID: channel.id)
    }

    @discardableResult
    public func downloadFileCommand(channelID: Int32, fileID: Int32, to localURL: URL) -> TeamTalkCommandID {
        TeamTalkCommandID(downloadFile(channelID: channelID, fileID: fileID, to: localURL))
    }

    @discardableResult
    public func downloadFileCommand(channelID: TeamTalkChannelID, fileID: TeamTalkFileID, to localURL: URL) -> TeamTalkCommandID {
        downloadFileCommand(channelID: channelID.cValue, fileID: fileID.cValue, to: localURL)
    }

    @discardableResult
    public func downloadFile(_ file: TeamTalkRemoteFile, to localURL: URL) -> TeamTalkCommandID {
        downloadFileCommand(channelID: file.channelID, fileID: file.id, to: localURL)
    }

    @discardableResult
    public func deleteFileCommand(channelID: Int32, fileID: Int32) -> TeamTalkCommandID {
        TeamTalkCommandID(deleteFile(channelID: channelID, fileID: fileID))
    }

    @discardableResult
    public func deleteFileCommand(channelID: TeamTalkChannelID, fileID: TeamTalkFileID) -> TeamTalkCommandID {
        deleteFileCommand(channelID: channelID.cValue, fileID: fileID.cValue)
    }

    @discardableResult
    public func deleteFile(_ file: TeamTalkRemoteFile) -> TeamTalkCommandID {
        deleteFileCommand(channelID: file.channelID, fileID: file.id)
    }

    @discardableResult
    public func subscribeCommand(userID: Int32, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoSubscribe(instance, userID, subscriptions.cValue))
    }

    @discardableResult
    public func subscribeCommand(userID: TeamTalkUserID, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
        subscribeCommand(userID: userID.cValue, subscriptions: subscriptions)
    }

    @discardableResult
    public func unsubscribeCommand(userID: Int32, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoUnsubscribe(instance, userID, subscriptions.cValue))
    }

    @discardableResult
    public func unsubscribeCommand(userID: TeamTalkUserID, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
        unsubscribeCommand(userID: userID.cValue, subscriptions: subscriptions)
    }

    @discardableResult
    public func updateServer(_ configuration: TeamTalkServerPropertiesConfiguration) -> TeamTalkCommandID {
        var properties = configuration.cValue
        return TeamTalkCommandID(TT_DoUpdateServer(instance, &properties))
    }

    @discardableResult
    public func updateServer(_ properties: TeamTalkServerProperties) -> TeamTalkCommandID {
        var properties = properties.cValue
        return TeamTalkCommandID(TT_DoUpdateServer(instance, &properties))
    }

    @discardableResult
    public func listUserAccounts(startingAt index: Int32 = 0, count: Int32 = 100) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoListUserAccounts(instance, index, count))
    }

    @discardableResult
    public func createUserAccount(_ configuration: TeamTalkUserAccountConfiguration) -> TeamTalkCommandID {
        var account = configuration.cValue
        return TeamTalkCommandID(TT_DoNewUserAccount(instance, &account))
    }

    @discardableResult
    public func createUserAccount(_ account: TeamTalkUserAccount) -> TeamTalkCommandID {
        var account = account.cValue
        return TeamTalkCommandID(TT_DoNewUserAccount(instance, &account))
    }

    @discardableResult
    public func deleteUserAccount(username: String) -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoDeleteUserAccount(instance, username))
    }

    @discardableResult
    public func saveServerConfiguration() -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoSaveConfig(instance))
    }

    @discardableResult
    public func queryServerStatistics() -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoQueryServerStats(instance))
    }

    @discardableResult
    public func quitServer() -> TeamTalkCommandID {
        TeamTalkCommandID(TT_DoQuit(instance))
    }

    @discardableResult
    public func join(channel: inout Channel) -> Int32 {
        TT_DoJoinChannel(instance, &channel)
    }

    @discardableResult
    public func joinChannel(id channelID: Int32, password: String = "") -> Int32 {
        TT_DoJoinChannelByID(instance, channelID, password)
    }

    @discardableResult
    public func joinChannel(id channelID: TeamTalkChannelID, password: String = "") -> Int32 {
        joinChannel(id: channelID.cValue, password: password)
    }

    @discardableResult
    public func update(channel: inout Channel) -> Int32 {
        TT_DoUpdateChannel(instance, &channel)
    }

    @discardableResult
    public func removeChannel(id channelID: Int32) -> Int32 {
        TT_DoRemoveChannel(instance, channelID)
    }

    @discardableResult
    public func removeChannel(id channelID: TeamTalkChannelID) -> Int32 {
        removeChannel(id: channelID.cValue)
    }

    @discardableResult
    public func changeNickname(_ nickname: String) -> Int32 {
        TT_DoChangeNickname(instance, nickname)
    }

    @discardableResult
    public func changeStatus(mode: Int32, message: String = "") -> Int32 {
        TT_DoChangeStatus(instance, mode, message)
    }

    @discardableResult
    public func kickUser(id userID: Int32, fromChannelID channelID: Int32) -> Int32 {
        TT_DoKickUser(instance, userID, channelID)
    }

    @discardableResult
    public func kickUser(id userID: TeamTalkUserID, fromChannelID channelID: TeamTalkChannelID) -> Int32 {
        kickUser(id: userID.cValue, fromChannelID: channelID.cValue)
    }

    @discardableResult
    public func banUser(id userID: Int32, fromChannelID channelID: Int32) -> Int32 {
        TT_DoBanUser(instance, userID, channelID)
    }

    @discardableResult
    public func banUser(id userID: TeamTalkUserID, fromChannelID channelID: TeamTalkChannelID) -> Int32 {
        banUser(id: userID.cValue, fromChannelID: channelID.cValue)
    }

    @discardableResult
    public func moveUser(id userID: Int32, toChannelID channelID: Int32) -> Int32 {
        TT_DoMoveUser(instance, userID, channelID)
    }

    @discardableResult
    public func moveUser(id userID: TeamTalkUserID, toChannelID channelID: TeamTalkChannelID) -> Int32 {
        moveUser(id: userID.cValue, toChannelID: channelID.cValue)
    }

    @discardableResult
    public func sendTextMessage(_ message: inout TextMessage) -> Int32 {
        TT_DoTextMessage(instance, &message)
    }

    @discardableResult
    public func sendTextMessage(_ message: TextMessage, content: String) -> Bool {
        TeamTalkTextMessageFactory.messages(from: message, content: content).reduce(true) { sent, textMessage in
            var textMessage = textMessage
            return sent && sendTextMessage(&textMessage) > 0
        }
    }

    @discardableResult
    public func uploadFile(at localURL: URL, toChannelID channelID: Int32) -> Int32 {
        guard let instance else {
            return -1
        }

        return TT_DoSendFile(instance, channelID, localURL.path)
    }

    @discardableResult
    public func uploadFile(at localURL: URL, toChannelID channelID: TeamTalkChannelID) -> Int32 {
        uploadFile(at: localURL, toChannelID: channelID.cValue)
    }

    @discardableResult
    public func downloadFile(channelID: Int32, fileID: Int32, to localURL: URL) -> Int32 {
        guard let instance else {
            return -1
        }

        return TT_DoRecvFile(instance, channelID, fileID, localURL.path)
    }

    @discardableResult
    public func downloadFile(channelID: TeamTalkChannelID, fileID: TeamTalkFileID, to localURL: URL) -> Int32 {
        downloadFile(channelID: channelID.cValue, fileID: fileID.cValue, to: localURL)
    }

    @discardableResult
    public func deleteFile(channelID: Int32, fileID: Int32) -> Int32 {
        guard let instance else {
            return -1
        }

        return TT_DoDeleteFile(instance, channelID, fileID)
    }

    @discardableResult
    public func deleteFile(channelID: TeamTalkChannelID, fileID: TeamTalkFileID) -> Int32 {
        deleteFile(channelID: channelID.cValue, fileID: fileID.cValue)
    }

    public func fileTransferInfo(id transferID: Int32) -> FileTransfer? {
        guard let instance else {
            return nil
        }

        var transfer = FileTransfer()
        guard TT_GetFileTransferInfo(instance, transferID, &transfer) != 0 else {
            return nil
        }
        return transfer
    }

    public func fileTransferInfo(id transferID: TeamTalkTransferID) -> FileTransfer? {
        fileTransferInfo(id: transferID.cValue)
    }

    public func fileTransfer(id transferID: Int32) -> TeamTalkFileTransfer? {
        fileTransferInfo(id: transferID).map(TeamTalkFileTransfer.init)
    }

    public func fileTransfer(id transferID: TeamTalkTransferID) -> TeamTalkFileTransfer? {
        fileTransfer(id: transferID.cValue)
    }

    @discardableResult
    public func cancelFileTransfer(id transferID: Int32) -> Bool {
        guard let instance else {
            return false
        }

        return TT_CancelFileTransfer(instance, transferID) != 0
    }

    @discardableResult
    public func cancelFileTransfer(id transferID: TeamTalkTransferID) -> Bool {
        cancelFileTransfer(id: transferID.cValue)
    }

    @discardableResult
    public func sendDesktopWindow(
        _ desktopWindow: DesktopWindow,
        convertTo bitmapFormat: TeamTalkBitmapFormat = .none
    ) -> Int32 {
        guard let instance else {
            return -1
        }

        var desktopWindow = desktopWindow
        return TT_SendDesktopWindow(instance, &desktopWindow, bitmapFormat.cValue)
    }

    @discardableResult
    public func sendDesktopWindow(
        _ desktopWindow: TeamTalkDesktopWindow,
        convertTo bitmapFormat: TeamTalkBitmapFormat = .none
    ) -> Int32 {
        guard let instance else {
            return -1
        }

        return desktopWindow.withUnsafeCValue { rawValue in
            var rawValue = rawValue
            return TT_SendDesktopWindow(instance, &rawValue, bitmapFormat.cValue)
        }
    }

    @discardableResult
    public func closeDesktopWindow() -> Bool {
        guard let instance else {
            return false
        }

        return TT_CloseDesktopWindow(instance) != 0
    }

    @discardableResult
    public func sendDesktopCursorPosition(x: UInt16, y: UInt16) -> Bool {
        guard let instance else {
            return false
        }

        return TT_SendDesktopCursorPosition(instance, x, y) != 0
    }

    @discardableResult
    public func sendDesktopInput(userID: Int32, inputs: [DesktopInput]) -> Bool {
        guard let instance, !inputs.isEmpty, inputs.count <= Int(TT_DESKTOPINPUT_MAX) else {
            return false
        }

        return inputs.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return false
            }
            return TT_SendDesktopInput(instance, userID, baseAddress, Int32(buffer.count)) != 0
        }
    }

    @discardableResult
    public func sendDesktopInput(userID: TeamTalkUserID, inputs: [DesktopInput]) -> Bool {
        sendDesktopInput(userID: userID.cValue, inputs: inputs)
    }

    @discardableResult
    public func sendDesktopInput(userID: Int32, inputs: [TeamTalkDesktopInput]) -> Bool {
        sendDesktopInput(userID: userID, inputs: inputs.map(\.cValue))
    }

    @discardableResult
    public func sendDesktopInput(userID: TeamTalkUserID, inputs: [TeamTalkDesktopInput]) -> Bool {
        sendDesktopInput(userID: userID.cValue, inputs: inputs)
    }

    public func withAcquiredDesktopWindow<Result>(
        userID: Int32,
        _ body: (DesktopWindow) throws -> Result
    ) rethrows -> Result? {
        guard let instance, let desktopWindow = TT_AcquireUserDesktopWindow(instance, userID) else {
            return nil
        }

        defer {
            _ = TT_ReleaseUserDesktopWindow(instance, desktopWindow)
        }
        return try body(desktopWindow.pointee)
    }

    public func withAcquiredDesktopWindow<Result>(
        userID: TeamTalkUserID,
        _ body: (DesktopWindow) throws -> Result
    ) rethrows -> Result? {
        try withAcquiredDesktopWindow(userID: userID.cValue, body)
    }

    public func withAcquiredDesktopWindow<Result>(
        userID: Int32,
        convertTo bitmapFormat: TeamTalkBitmapFormat,
        _ body: (DesktopWindow) throws -> Result
    ) rethrows -> Result? {
        guard let instance, let desktopWindow = TT_AcquireUserDesktopWindowEx(instance, userID, bitmapFormat.cValue) else {
            return nil
        }

        defer {
            _ = TT_ReleaseUserDesktopWindow(instance, desktopWindow)
        }
        return try body(desktopWindow.pointee)
    }

    public func withAcquiredDesktopWindow<Result>(
        userID: TeamTalkUserID,
        convertTo bitmapFormat: TeamTalkBitmapFormat,
        _ body: (DesktopWindow) throws -> Result
    ) rethrows -> Result? {
        try withAcquiredDesktopWindow(userID: userID.cValue, convertTo: bitmapFormat, body)
    }

    public func acquireDesktopWindow(userID: Int32) -> TeamTalkDesktopWindow? {
        withAcquiredDesktopWindow(userID: userID) { TeamTalkDesktopWindow($0) }
    }

    public func acquireDesktopWindow(userID: TeamTalkUserID) -> TeamTalkDesktopWindow? {
        acquireDesktopWindow(userID: userID.cValue)
    }

    public func acquireDesktopWindow(
        userID: Int32,
        convertTo bitmapFormat: TeamTalkBitmapFormat
    ) -> TeamTalkDesktopWindow? {
        withAcquiredDesktopWindow(userID: userID, convertTo: bitmapFormat) { TeamTalkDesktopWindow($0) }
    }

    public func acquireDesktopWindow(
        userID: TeamTalkUserID,
        convertTo bitmapFormat: TeamTalkBitmapFormat
    ) -> TeamTalkDesktopWindow? {
        acquireDesktopWindow(userID: userID.cValue, convertTo: bitmapFormat)
    }

    public func videoCaptureDevicesInfo() -> [VideoCaptureDevice] {
        var count: Int32 = 0
        guard TT_GetVideoCaptureDevices(nil, &count) != 0, count > 0 else {
            return []
        }

        var devices = Array(repeating: VideoCaptureDevice(), count: Int(count))
        var deviceCount = count
        let didRead = devices.withUnsafeMutableBufferPointer { buffer in
            TT_GetVideoCaptureDevices(buffer.baseAddress, &deviceCount) != 0
        }
        guard didRead else {
            return []
        }

        let returnedCount = max(0, min(Int(deviceCount), devices.count))
        if returnedCount < devices.count {
            devices.removeLast(devices.count - returnedCount)
        }
        return devices
    }

    public func videoCaptureDevices() -> [TeamTalkVideoCaptureDevice] {
        videoCaptureDevicesInfo().map(TeamTalkVideoCaptureDevice.init)
    }

    @discardableResult
    public func initVideoCaptureDevice(deviceID: String, format: VideoFormat) -> Bool {
        guard let instance else {
            return false
        }

        var format = format
        return TT_InitVideoCaptureDevice(instance, deviceID, &format) != 0
    }

    @discardableResult
    public func initVideoCaptureDevice(deviceID: String, format: TeamTalkVideoFormat) -> Bool {
        initVideoCaptureDevice(deviceID: deviceID, format: format.cValue)
    }

    @discardableResult
    public func initVideoCaptureDevice(_ device: TeamTalkVideoCaptureDevice, format: VideoFormat) -> Bool {
        initVideoCaptureDevice(deviceID: device.deviceIdentifier, format: format)
    }

    @discardableResult
    public func initVideoCaptureDevice(_ device: TeamTalkVideoCaptureDevice, format: TeamTalkVideoFormat) -> Bool {
        initVideoCaptureDevice(deviceID: device.deviceIdentifier, format: format)
    }

    @discardableResult
    public func closeVideoCaptureDevice() -> Bool {
        guard let instance else {
            return false
        }

        return TT_CloseVideoCaptureDevice(instance) != 0
    }

    @discardableResult
    public func setUserMediaStorage(
        userID: Int32,
        directoryURL: URL?,
        fileNamePattern: String = "",
        audioFileFormat: TeamTalkAudioFileFormat,
        stopRecordingExtraDelayMilliseconds: Int32? = nil
    ) -> Bool {
        guard let instance else {
            return false
        }

        let directoryPath = directoryURL?.path ?? ""
        if let stopRecordingExtraDelayMilliseconds {
            return TT_SetUserMediaStorageDirEx(
                instance,
                userID,
                directoryPath,
                fileNamePattern,
                audioFileFormat.cValue,
                stopRecordingExtraDelayMilliseconds
            ) != 0
        }

        return TT_SetUserMediaStorageDir(
            instance,
            userID,
            directoryPath,
            fileNamePattern,
            audioFileFormat.cValue
        ) != 0
    }

    @discardableResult
    public func setUserMediaStorage(
        userID: TeamTalkUserID,
        directoryURL: URL?,
        fileNamePattern: String = "",
        audioFileFormat: TeamTalkAudioFileFormat,
        stopRecordingExtraDelayMilliseconds: Int32? = nil
    ) -> Bool {
        setUserMediaStorage(
            userID: userID.cValue,
            directoryURL: directoryURL,
            fileNamePattern: fileNamePattern,
            audioFileFormat: audioFileFormat,
            stopRecordingExtraDelayMilliseconds: stopRecordingExtraDelayMilliseconds
        )
    }

    @discardableResult
    public func setUserMediaStorage(
        userID: Int32,
        configuration: TeamTalkUserMediaStorageConfiguration
    ) -> Bool {
        setUserMediaStorage(
            userID: userID,
            directoryURL: configuration.directoryURL,
            fileNamePattern: configuration.fileNamePattern,
            audioFileFormat: configuration.audioFileFormat,
            stopRecordingExtraDelayMilliseconds: configuration.stopRecordingExtraDelayMilliseconds
        )
    }

    @discardableResult
    public func setUserMediaStorage(
        userID: TeamTalkUserID,
        configuration: TeamTalkUserMediaStorageConfiguration
    ) -> Bool {
        setUserMediaStorage(userID: userID.cValue, configuration: configuration)
    }

    @discardableResult
    public func disableUserMediaStorage(userID: Int32) -> Bool {
        setUserMediaStorage(userID: userID, directoryURL: nil, audioFileFormat: .none)
    }

    @discardableResult
    public func disableUserMediaStorage(userID: TeamTalkUserID) -> Bool {
        disableUserMediaStorage(userID: userID.cValue)
    }

    @discardableResult
    public func startRecordingMuxedAudioFile(
        codec: AudioCodec,
        to fileURL: URL,
        audioFileFormat: TeamTalkAudioFileFormat
    ) -> Bool {
        guard let instance else {
            return false
        }

        var codec = codec
        return TT_StartRecordingMuxedAudioFile(instance, &codec, fileURL.path, audioFileFormat.cValue) != 0
    }

    @discardableResult
    public func startRecordingMuxedAudioFile(
        channelID: Int32,
        to fileURL: URL,
        audioFileFormat: TeamTalkAudioFileFormat
    ) -> Bool {
        guard let instance else {
            return false
        }

        return TT_StartRecordingMuxedAudioFileEx(instance, channelID, fileURL.path, audioFileFormat.cValue) != 0
    }

    @discardableResult
    public func startRecordingMuxedAudioFile(
        channelID: TeamTalkChannelID,
        to fileURL: URL,
        audioFileFormat: TeamTalkAudioFileFormat
    ) -> Bool {
        startRecordingMuxedAudioFile(channelID: channelID.cValue, to: fileURL, audioFileFormat: audioFileFormat)
    }

    @discardableResult
    public func startRecordingMuxedStreams(
        _ streamTypes: TeamTalkStreamTypes,
        codec: AudioCodec,
        to fileURL: URL,
        audioFileFormat: TeamTalkAudioFileFormat
    ) -> Bool {
        guard let instance else {
            return false
        }

        var codec = codec
        return TT_StartRecordingMuxedStreams(
            instance,
            streamTypes.cMask,
            &codec,
            fileURL.path,
            audioFileFormat.cValue
        ) != 0
    }

    @discardableResult
    public func stopRecordingMuxedAudioFile() -> Bool {
        guard let instance else {
            return false
        }

        return TT_StopRecordingMuxedAudioFile(instance) != 0
    }

    @discardableResult
    public func stopRecordingMuxedAudioFile(channelID: Int32) -> Bool {
        guard let instance else {
            return false
        }

        return TT_StopRecordingMuxedAudioFileEx(instance, channelID) != 0
    }

    @discardableResult
    public func stopRecordingMuxedAudioFile(channelID: TeamTalkChannelID) -> Bool {
        stopRecordingMuxedAudioFile(channelID: channelID.cValue)
    }

    @discardableResult
    public func enableAudioBlockEvent(
        sourceID: Int32,
        streamTypes: TeamTalkStreamTypes,
        audioFormat: AudioFormat? = nil,
        enabled: Bool
    ) -> Bool {
        guard let instance else {
            return false
        }

        return withOptionalAudioFormatPointer(audioFormat) { formatPointer in
            TT_EnableAudioBlockEventEx(
                instance,
                sourceID,
                streamTypes.cMask,
                formatPointer,
                enabled ? 1 : 0
            ) != 0
        }
    }

    @discardableResult
    public func enableAudioBlockEvent(
        sourceID: TeamTalkAudioBlockSourceID,
        streamTypes: TeamTalkStreamTypes,
        audioFormat: AudioFormat? = nil,
        enabled: Bool
    ) -> Bool {
        enableAudioBlockEvent(
            sourceID: sourceID.cValue,
            streamTypes: streamTypes,
            audioFormat: audioFormat,
            enabled: enabled
        )
    }

    @discardableResult
    public func enableAudioBlockEvent(
        sourceID: Int32,
        streamTypes: TeamTalkStreamTypes,
        audioFormat: TeamTalkAudioFormatConfiguration,
        enabled: Bool
    ) -> Bool {
        enableAudioBlockEvent(
            sourceID: sourceID,
            streamTypes: streamTypes,
            audioFormat: audioFormat.cValue,
            enabled: enabled
        )
    }

    @discardableResult
    public func enableAudioBlockEvent(
        sourceID: TeamTalkAudioBlockSourceID,
        streamTypes: TeamTalkStreamTypes,
        audioFormat: TeamTalkAudioFormatConfiguration,
        enabled: Bool
    ) -> Bool {
        enableAudioBlockEvent(
            sourceID: sourceID.cValue,
            streamTypes: streamTypes,
            audioFormat: audioFormat,
            enabled: enabled
        )
    }

    @discardableResult
    public func disableAudioBlockEvent(
        sourceID: Int32,
        streamTypes: TeamTalkStreamTypes
    ) -> Bool {
        enableAudioBlockEvent(sourceID: sourceID, streamTypes: streamTypes, enabled: false)
    }

    @discardableResult
    public func disableAudioBlockEvent(
        sourceID: TeamTalkAudioBlockSourceID,
        streamTypes: TeamTalkStreamTypes
    ) -> Bool {
        disableAudioBlockEvent(sourceID: sourceID.cValue, streamTypes: streamTypes)
    }

    public func withAcquiredAudioBlock<Result>(
        sourceID: Int32,
        streamTypes: TeamTalkStreamTypes,
        _ body: (AudioBlock) throws -> Result
    ) rethrows -> Result? {
        guard let instance, let audioBlock = TT_AcquireUserAudioBlock(instance, streamTypes.cMask, sourceID) else {
            return nil
        }

        defer {
            _ = TT_ReleaseUserAudioBlock(instance, audioBlock)
        }
        return try body(audioBlock.pointee)
    }

    public func withAcquiredAudioBlock<Result>(
        sourceID: TeamTalkAudioBlockSourceID,
        streamTypes: TeamTalkStreamTypes,
        _ body: (AudioBlock) throws -> Result
    ) rethrows -> Result? {
        try withAcquiredAudioBlock(sourceID: sourceID.cValue, streamTypes: streamTypes, body)
    }

    public func acquireAudioBlock(
        sourceID: Int32,
        streamTypes: TeamTalkStreamTypes
    ) -> TeamTalkAudioBlock? {
        withAcquiredAudioBlock(sourceID: sourceID, streamTypes: streamTypes) { TeamTalkAudioBlock($0) }
    }

    public func acquireAudioBlock(
        sourceID: TeamTalkAudioBlockSourceID,
        streamTypes: TeamTalkStreamTypes
    ) -> TeamTalkAudioBlock? {
        acquireAudioBlock(sourceID: sourceID.cValue, streamTypes: streamTypes)
    }

    @discardableResult
    public func insertAudioBlock(_ audioBlock: AudioBlock?) -> Bool {
        guard let instance else {
            return false
        }

        if var audioBlock {
            return TT_InsertAudioBlock(instance, &audioBlock) != 0
        }
        return TT_InsertAudioBlock(instance, nil) != 0
    }

    @discardableResult
    public func insertAudioBlock(_ audioBlock: TeamTalkAudioBlock?) -> Bool {
        guard let instance else {
            return false
        }

        guard let audioBlock else {
            return TT_InsertAudioBlock(instance, nil) != 0
        }

        return audioBlock.withUnsafeCValue { rawValue in
            var rawValue = rawValue
            return TT_InsertAudioBlock(instance, &rawValue) != 0
        }
    }

    public func mediaFileInfo(at localURL: URL) -> MediaFileInfo? {
        var mediaFileInfo = MediaFileInfo()
        guard TT_GetMediaFileInfo(localURL.path, &mediaFileInfo) != 0 else {
            return nil
        }
        return mediaFileInfo
    }

    public func mediaFile(at localURL: URL) -> TeamTalkMediaFileInfo? {
        mediaFileInfo(at: localURL).map(TeamTalkMediaFileInfo.init)
    }

    @discardableResult
    public func startStreamingMediaFileToChannel(from localURL: URL, videoCodec: VideoCodec? = nil) -> Bool {
        guard let instance else {
            return false
        }

        return withOptionalVideoCodecPointer(videoCodec) { codecPointer in
            TT_StartStreamingMediaFileToChannel(instance, localURL.path, codecPointer) != 0
        }
    }

    @discardableResult
    public func startStreamingMediaFileToChannel(
        from localURL: URL,
        playback: MediaFilePlayback,
        videoCodec: VideoCodec? = nil
    ) -> Bool {
        guard let instance else {
            return false
        }

        var playback = playback
        return withOptionalVideoCodecPointer(videoCodec) { codecPointer in
            TT_StartStreamingMediaFileToChannelEx(instance, localURL.path, &playback, codecPointer) != 0
        }
    }

    @discardableResult
    public func startStreamingMediaFileToChannel(
        from localURL: URL,
        playback: TeamTalkMediaFilePlaybackConfiguration,
        videoCodec: VideoCodec? = nil
    ) -> Bool {
        startStreamingMediaFileToChannel(from: localURL, playback: playback.cValue, videoCodec: videoCodec)
    }

    @discardableResult
    public func startStreamingMediaFileToChannel(
        from localURL: URL,
        playback: TeamTalkMediaFilePlayback,
        videoCodec: VideoCodec? = nil
    ) -> Bool {
        startStreamingMediaFileToChannel(from: localURL, playback: playback.cValue, videoCodec: videoCodec)
    }

    @discardableResult
    public func updateStreamingMediaFileToChannel(
        playback: MediaFilePlayback,
        videoCodec: VideoCodec? = nil
    ) -> Bool {
        guard let instance else {
            return false
        }

        var playback = playback
        return withOptionalVideoCodecPointer(videoCodec) { codecPointer in
            TT_UpdateStreamingMediaFileToChannel(instance, &playback, codecPointer) != 0
        }
    }

    @discardableResult
    public func updateStreamingMediaFileToChannel(
        playback: TeamTalkMediaFilePlaybackConfiguration,
        videoCodec: VideoCodec? = nil
    ) -> Bool {
        updateStreamingMediaFileToChannel(playback: playback.cValue, videoCodec: videoCodec)
    }

    @discardableResult
    public func updateStreamingMediaFileToChannel(
        playback: TeamTalkMediaFilePlayback,
        videoCodec: VideoCodec? = nil
    ) -> Bool {
        updateStreamingMediaFileToChannel(playback: playback.cValue, videoCodec: videoCodec)
    }

    @discardableResult
    public func stopStreamingMediaFileToChannel() -> Bool {
        guard let instance else {
            return false
        }

        return TT_StopStreamingMediaFileToChannel(instance) != 0
    }

    @discardableResult
    public func initLocalPlayback(from localURL: URL, playback: MediaFilePlayback) -> Int32 {
        guard let instance else {
            return -1
        }

        var playback = playback
        return TT_InitLocalPlayback(instance, localURL.path, &playback)
    }

    public func initLocalPlayback(
        from localURL: URL,
        playback: TeamTalkMediaFilePlaybackConfiguration
    ) -> TeamTalkPlaybackSessionID? {
        let sessionID = initLocalPlayback(from: localURL, playback: playback.cValue)
        guard sessionID > 0 else {
            return nil
        }
        return TeamTalkPlaybackSessionID(sessionID)
    }

    public func initLocalPlayback(
        from localURL: URL,
        playback: TeamTalkMediaFilePlayback
    ) -> TeamTalkPlaybackSessionID? {
        initLocalPlayback(from: localURL, playback: TeamTalkMediaFilePlaybackConfiguration(playback))
    }

    @discardableResult
    public func updateLocalPlayback(sessionID: Int32, playback: MediaFilePlayback) -> Bool {
        guard let instance else {
            return false
        }

        var playback = playback
        return TT_UpdateLocalPlayback(instance, sessionID, &playback) != 0
    }

    @discardableResult
    public func updateLocalPlayback(
        sessionID: TeamTalkPlaybackSessionID,
        playback: TeamTalkMediaFilePlaybackConfiguration
    ) -> Bool {
        updateLocalPlayback(sessionID: sessionID.cValue, playback: playback.cValue)
    }

    @discardableResult
    public func updateLocalPlayback(
        sessionID: TeamTalkPlaybackSessionID,
        playback: TeamTalkMediaFilePlayback
    ) -> Bool {
        updateLocalPlayback(sessionID: sessionID, playback: TeamTalkMediaFilePlaybackConfiguration(playback))
    }

    @discardableResult
    public func stopLocalPlayback(sessionID: Int32) -> Bool {
        guard let instance else {
            return false
        }

        return TT_StopLocalPlayback(instance, sessionID) != 0
    }

    @discardableResult
    public func stopLocalPlayback(sessionID: TeamTalkPlaybackSessionID) -> Bool {
        stopLocalPlayback(sessionID: sessionID.cValue)
    }

    @discardableResult
    public func setEncryptionContext(_ encryption: inout EncryptionContext) -> Bool {
        TT_SetEncryptionContext(instance, &encryption) != 0
    }

    @discardableResult
    public func configureEncryption(
        _ configuration: TeamTalkEncryptionConfiguration,
        temporaryDirectory: URL? = nil
    ) throws -> Bool {
        var encryption = EncryptionContext()
        let directory: URL
        if let temporaryDirectory {
            directory = temporaryDirectory
        } else {
            directory = try FileManager.default.url(
                for: .autosavedInformationDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }

        let caCertificateURL = directory.appendingPathComponent("ca_cert.pem")
        let certificateURL = directory.appendingPathComponent("cert.pem")
        let privateKeyURL = directory.appendingPathComponent("key.pem")
        let temporaryFiles = [
            (configuration.caCertificate, caCertificateURL, TeamTalkEncryptionStringProperty.caFile),
            (configuration.certificate, certificateURL, TeamTalkEncryptionStringProperty.certificateFile),
            (configuration.privateKey, privateKeyURL, TeamTalkEncryptionStringProperty.privateKeyFile)
        ]

        defer {
            for (_, url, _) in temporaryFiles {
                try? FileManager.default.removeItem(at: url)
            }
        }

        for (contents, url, property) in temporaryFiles where contents.isEmpty == false {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            TeamTalkString.setEncryption(property, on: &encryption, to: url.path)
        }

        encryption.bVerifyPeer = configuration.verifyPeer ? 1 : 0
        encryption.nVerifyDepth = configuration.verifyPeer ? 0 : -1

        return setEncryptionContext(&encryption)
    }

    public func addObserver(_ observer: TeamTalkMessageObserver) {
        if observers.contains(where: { $0.value === observer }) {
            return
        }

        observers.append(TeamTalkMessageHandler(value: observer))
    }

    public func addEventObserver(_ observer: TeamTalkEventObserver) {
        if eventObservers.contains(where: { $0.value === observer }) {
            return
        }

        eventObservers.append(TeamTalkEventHandler(value: observer))
    }

    public func removeObserver(_ observer: TeamTalkMessageObserver) {
        observers.removeAll { $0.value === observer || $0.value == nil }
    }

    public func removeEventObserver(_ observer: TeamTalkEventObserver) {
        eventObservers.removeAll { $0.value === observer || $0.value == nil }
    }

    public func removeAllObservers() {
        observers.removeAll()
    }

    public func removeAllEventObservers() {
        eventObservers.removeAll()
    }

    public var events: AsyncStream<TeamTalkEvent> {
        AsyncStream { continuation in
            let observer = TeamTalkAsyncEventObserver { event in
                continuation.yield(event)
            }

            addEventObserver(observer)

            continuation.onTermination = { [weak self, observer] _ in
                self?.removeEventObserver(observer)
            }
        }
    }

    public func pollMessages() {
        var message = TTMessage()
        var waitMSec: Int32 = 0

        while TT_GetMessage(instance, &message, &waitMSec) != 0 {
            observers.removeAll { $0.value == nil }
            eventObservers.removeAll { $0.value == nil }

            let event = TeamTalkEvent(message)

            for observer in observers {
                observer.value?.handleTeamTalkMessage(message)
            }

            for observer in eventObservers {
                observer.value?.handleTeamTalkEvent(event)
            }
        }
    }

    public func isTransmitting(_ stream: StreamType) -> Bool {
        switch stream {
        case STREAMTYPE_VOICE:
            let currentFlags = flags
            return currentFlags.contains(.transmittingVoice) ||
                (currentFlags.contains(.voiceActivated) && currentFlags.contains(.voiceActive))
        default:
            return false
        }
    }

    @discardableResult
    public func enableVoiceTransmission(_ enabled: Bool) -> Bool {
        TT_EnableVoiceTransmission(instance, enabled ? 1 : 0) != 0
    }

    @discardableResult
    public func enableVoiceActivation(_ enabled: Bool) -> Bool {
        TT_EnableVoiceActivation(instance, enabled ? 1 : 0) != 0
    }

    public func setVoiceActivationLevel(_ level: Int32) {
        TT_SetVoiceActivationLevel(instance, level)
    }

    public func setSoundInputGainLevel(_ level: Int32) {
        TT_SetSoundInputGainLevel(instance, level)
    }

    public func setSoundOutputVolume(_ volume: Int32) {
        TT_SetSoundOutputVolume(instance, volume)
    }

    public func closeSoundDevices() {
        TT_CloseSoundInputDevice(instance)
        TT_CloseSoundOutputDevice(instance)
    }

    @discardableResult
    public func initSoundInputDevice(id soundDeviceID: Int32) -> Bool {
        TT_InitSoundInputDevice(instance, soundDeviceID) != 0
    }

    @discardableResult
    public func initSoundInputDevice(id soundDeviceID: TeamTalkSoundDeviceID) -> Bool {
        initSoundInputDevice(id: soundDeviceID.cValue)
    }

    @discardableResult
    public func initSoundOutputDevice(id soundDeviceID: Int32) -> Bool {
        TT_InitSoundOutputDevice(instance, soundDeviceID) != 0
    }

    @discardableResult
    public func initSoundOutputDevice(id soundDeviceID: TeamTalkSoundDeviceID) -> Bool {
        initSoundOutputDevice(id: soundDeviceID.cValue)
    }

    @discardableResult
    public func setSoundInputPreprocess(_ preprocessor: inout AudioPreprocessor) -> Bool {
        TT_SetSoundInputPreprocessEx(instance, &preprocessor) != 0
    }

    public func setUserMute(userID: Int32, stream: StreamType, muted: Bool) {
        TT_SetUserMute(instance, userID, stream, muted ? 1 : 0)
    }

    public func setUserVolume(userID: Int32, stream: StreamType, volume: Int32) {
        TT_SetUserVolume(instance, userID, stream, volume)
    }

    public func setUserStereo(userID: Int32, stream: StreamType, leftSpeaker: TTBOOL, rightSpeaker: TTBOOL) {
        TT_SetUserStereo(instance, userID, stream, leftSpeaker, rightSpeaker)
    }

    @discardableResult
    public func subscribe(userID: Int32, subscriptions: UInt32) -> Int32 {
        TT_DoSubscribe(instance, userID, subscriptions)
    }

    @discardableResult
    public func unsubscribe(userID: Int32, subscriptions: UInt32) -> Int32 {
        TT_DoUnsubscribe(instance, userID, subscriptions)
    }

    public func pump(_ event: ClientEvent, source: Int32) {
        TT_PumpMessage(instance, event, source)
    }
}
