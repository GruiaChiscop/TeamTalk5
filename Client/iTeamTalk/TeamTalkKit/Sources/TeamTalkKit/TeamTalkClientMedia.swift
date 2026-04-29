import Foundation
import TeamTalkC

extension TeamTalkClient {
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
public func setUserMediaStorage(
    user: User,
    configuration: TeamTalkUserMediaStorageConfiguration
) -> Bool {
    setUserMediaStorage(userID: user.userID, configuration: configuration)
}

@discardableResult
public func setUserMediaStorage(
    user: TeamTalkUser,
    configuration: TeamTalkUserMediaStorageConfiguration
) -> Bool {
    setUserMediaStorage(userID: user.userID, configuration: configuration)
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
public func disableUserMediaStorage(user: User) -> Bool {
    disableUserMediaStorage(userID: user.userID)
}

@discardableResult
public func disableUserMediaStorage(user: TeamTalkUser) -> Bool {
    disableUserMediaStorage(userID: user.userID)
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
public func startRecordingMuxedAudioFile(
    in channel: Channel,
    to fileURL: URL,
    audioFileFormat: TeamTalkAudioFileFormat
) -> Bool {
    startRecordingMuxedAudioFile(channelID: channel.channelID, to: fileURL, audioFileFormat: audioFileFormat)
}

@discardableResult
public func startRecordingMuxedAudioFile(
    in channel: TeamTalkChannel,
    to fileURL: URL,
    audioFileFormat: TeamTalkAudioFileFormat
) -> Bool {
    startRecordingMuxedAudioFile(channelID: channel.channelID, to: fileURL, audioFileFormat: audioFileFormat)
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
public func stopRecordingMuxedAudioFile(in channel: Channel) -> Bool {
    stopRecordingMuxedAudioFile(channelID: channel.channelID)
}

@discardableResult
public func stopRecordingMuxedAudioFile(in channel: TeamTalkChannel) -> Bool {
    stopRecordingMuxedAudioFile(channelID: channel.channelID)
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
    playback: MediaFilePlayback
) -> Bool {
    updateLocalPlayback(sessionID: sessionID.cValue, playback: playback)
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

}
