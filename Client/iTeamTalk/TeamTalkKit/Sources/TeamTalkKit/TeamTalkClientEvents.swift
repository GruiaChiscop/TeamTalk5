import Foundation
#if canImport(Combine)
import Combine
#endif
import TeamTalkC

extension TeamTalkClient {
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

@available(*, deprecated, message: "Prefer addEventObserver(_:) for typed TeamTalkEvent delivery.")
public func addObserver(_ observer: TeamTalkMessageObserver) {
    if observers.contains(where: { $0.value === observer }) {
        return
    }

    observers.append(TeamTalkMessageHandler(value: observer))
    ensureEventDispatching()
}

public func addEventObserver(_ observer: TeamTalkEventObserver) {
    if eventObservers.contains(where: { $0.value === observer }) {
        return
    }

    eventObservers.append(TeamTalkEventHandler(value: observer))
    ensureEventDispatching()
}

@available(*, deprecated, message: "Prefer removeEventObserver(_:) for typed TeamTalkEvent delivery.")
public func removeObserver(_ observer: TeamTalkMessageObserver) {
    observers.removeAll { $0.value === observer || $0.value == nil }
}

public func removeEventObserver(_ observer: TeamTalkEventObserver) {
    eventObservers.removeAll { $0.value === observer || $0.value == nil }
}

@available(*, deprecated, message: "Prefer removeAllEventObservers() for typed TeamTalkEvent delivery.")
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

#if canImport(Combine)
@available(*, deprecated, message: "Prefer eventPublisher for typed TeamTalkEvent delivery.")
public var messagePublisher: AnyPublisher<TTMessage, Never> {
    ensureEventDispatching()
    return messageSubject.eraseToAnyPublisher()
}

public var eventPublisher: AnyPublisher<TeamTalkEvent, Never> {
    ensureEventDispatching()
    return eventSubject.eraseToAnyPublisher()
}
#endif

public func pollMessages() {
    guard let instance else {
        return
    }

    messagePollingLock.lock()
    defer { messagePollingLock.unlock() }

    var message = TTMessage()
    var waitMSec: Int32 = 0

    while TT_GetMessage(instance, &message, &waitMSec) != 0 {
        let dispatchedMessage = message
        dispatchPolledMessage(dispatchedMessage)
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

public func isTransmitting(_ stream: TeamTalkStreamTypes) -> Bool {
    isTransmitting(stream.cValue)
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
    emitUserStateChanged(for: userID)
}

public func setUserMute(userID: Int32, stream: TeamTalkStreamTypes, muted: Bool) {
    setUserMute(userID: userID, stream: stream.cValue, muted: muted)
}

public func setUserMute(userID: TeamTalkUserID, stream: TeamTalkStreamTypes, muted: Bool) {
    setUserMute(userID: userID.cValue, stream: stream, muted: muted)
}

public func setUserMute(user: User, stream: TeamTalkStreamTypes, muted: Bool) {
    setUserMute(userID: user.userID, stream: stream, muted: muted)
}

public func setUserMute(user: TeamTalkUser, stream: TeamTalkStreamTypes, muted: Bool) {
    setUserMute(userID: user.userID, stream: stream, muted: muted)
}

public func setUserVolume(userID: Int32, stream: StreamType, volume: Int32) {
    TT_SetUserVolume(instance, userID, stream, volume)
    emitUserStateChanged(for: userID)
}

public func setUserVolume(userID: Int32, stream: TeamTalkStreamTypes, volume: Int32) {
    setUserVolume(userID: userID, stream: stream.cValue, volume: volume)
}

public func setUserVolume(userID: TeamTalkUserID, stream: TeamTalkStreamTypes, volume: Int32) {
    setUserVolume(userID: userID.cValue, stream: stream, volume: volume)
}

public func setUserVolume(user: User, stream: TeamTalkStreamTypes, volume: Int32) {
    setUserVolume(userID: user.userID, stream: stream, volume: volume)
}

public func setUserVolume(user: TeamTalkUser, stream: TeamTalkStreamTypes, volume: Int32) {
    setUserVolume(userID: user.userID, stream: stream, volume: volume)
}

public func setUserStereo(userID: Int32, stream: StreamType, leftSpeaker: TTBOOL, rightSpeaker: TTBOOL) {
    TT_SetUserStereo(instance, userID, stream, leftSpeaker, rightSpeaker)
    emitUserStateChanged(for: userID)
}

public func setUserStereo(
    userID: Int32,
    stream: TeamTalkStreamTypes,
    leftSpeaker: Bool,
    rightSpeaker: Bool
) {
    setUserStereo(
        userID: userID,
        stream: stream.cValue,
        leftSpeaker: leftSpeaker ? 1 : 0,
        rightSpeaker: rightSpeaker ? 1 : 0
    )
}

public func setUserStereo(
    userID: TeamTalkUserID,
    stream: TeamTalkStreamTypes,
    leftSpeaker: Bool,
    rightSpeaker: Bool
) {
    setUserStereo(
        userID: userID.cValue,
        stream: stream,
        leftSpeaker: leftSpeaker,
        rightSpeaker: rightSpeaker
    )
}

public func setUserStereo(
    user: User,
    stream: TeamTalkStreamTypes,
    leftSpeaker: Bool,
    rightSpeaker: Bool
) {
    setUserStereo(
        userID: user.userID,
        stream: stream,
        leftSpeaker: leftSpeaker,
        rightSpeaker: rightSpeaker
    )
}

public func setUserStereo(
    user: TeamTalkUser,
    stream: TeamTalkStreamTypes,
    leftSpeaker: Bool,
    rightSpeaker: Bool
) {
    setUserStereo(
        userID: user.userID,
        stream: stream,
        leftSpeaker: leftSpeaker,
        rightSpeaker: rightSpeaker
    )
}

@discardableResult
public func subscribe(userID: Int32, subscriptions: UInt32) -> Int32 {
    let commandID = TT_DoSubscribe(instance, userID, subscriptions)
    emitUserStateChanged(for: userID)
    return commandID
}

@discardableResult
public func subscribe(userID: Int32, subscriptions: TeamTalkSubscriptions) -> Int32 {
    subscribe(userID: userID, subscriptions: subscriptions.cValue)
}

@discardableResult
public func subscribe(userID: TeamTalkUserID, subscriptions: TeamTalkSubscriptions) -> Int32 {
    subscribe(userID: userID.cValue, subscriptions: subscriptions)
}

@discardableResult
public func subscribe(user: User, subscriptions: TeamTalkSubscriptions) -> Int32 {
    subscribe(userID: user.userID, subscriptions: subscriptions)
}

@discardableResult
public func subscribe(user: TeamTalkUser, subscriptions: TeamTalkSubscriptions) -> Int32 {
    subscribe(userID: user.userID, subscriptions: subscriptions)
}

@discardableResult
public func unsubscribe(userID: Int32, subscriptions: UInt32) -> Int32 {
    let commandID = TT_DoUnsubscribe(instance, userID, subscriptions)
    emitUserStateChanged(for: userID)
    return commandID
}

@discardableResult
public func unsubscribe(userID: Int32, subscriptions: TeamTalkSubscriptions) -> Int32 {
    unsubscribe(userID: userID, subscriptions: subscriptions.cValue)
}

@discardableResult
public func unsubscribe(userID: TeamTalkUserID, subscriptions: TeamTalkSubscriptions) -> Int32 {
    unsubscribe(userID: userID.cValue, subscriptions: subscriptions)
}

@discardableResult
public func unsubscribe(user: User, subscriptions: TeamTalkSubscriptions) -> Int32 {
    unsubscribe(userID: user.userID, subscriptions: subscriptions)
}

@discardableResult
public func unsubscribe(user: TeamTalkUser, subscriptions: TeamTalkSubscriptions) -> Int32 {
    unsubscribe(userID: user.userID, subscriptions: subscriptions)
}

@available(*, deprecated, message: "Prefer typed TeamTalkClient APIs that emit updates automatically.")
public func pump(_ event: ClientEvent, source: Int32) {
    TT_PumpMessage(instance, event, source)
}

@available(*, deprecated, message: "Prefer typed TeamTalkClient APIs that emit updates automatically.")
public func pump(_ event: TeamTalkClientEvent, source: Int32) {
    pump(event.cValue, source: source)
}

@available(*, deprecated, message: "Prefer typed TeamTalkClient APIs that emit updates automatically.")
public func pump(_ event: TeamTalkClientEvent, source: TeamTalkUserID) {
    pump(event, source: source.cValue)
}

@available(*, deprecated, message: "Prefer typed TeamTalkClient APIs that emit updates automatically.")
public func pump(_ event: TeamTalkClientEvent, source: TeamTalkChannelID) {
    pump(event, source: source.cValue)
}

@available(*, deprecated, message: "Prefer typed TeamTalkClient APIs that emit updates automatically.")
public func pump(_ event: TeamTalkClientEvent, source user: TeamTalkUser) {
    pump(event, source: user.userID)
}

@available(*, deprecated, message: "Prefer typed TeamTalkClient APIs that emit updates automatically.")
public func pump(_ event: TeamTalkClientEvent, source channel: TeamTalkChannel) {
    pump(event, source: channel.channelID)
}
}

private extension TeamTalkClient {
func dispatchPolledMessage(_ message: TTMessage) {
    DispatchQueue.main.async { [weak self] in
        self?.deliverPolledMessage(message)
    }
}

func deliverPolledMessage(_ message: TTMessage) {
    observers.removeAll { $0.value == nil }
    eventObservers.removeAll { $0.value == nil }

    let event = TeamTalkEvent(message)

#if canImport(Combine)
    messageSubject.send(message)
    eventSubject.send(event)
#endif

    for observer in observers {
        observer.value?.handleTeamTalkMessage(message)
    }

    for observer in eventObservers {
        observer.value?.handleTeamTalkEvent(event)
    }
}

func emitUserStateChanged(for userID: Int32) {
    TT_PumpMessage(instance, CLIENTEVENT_USER_STATECHANGE, userID)
}
}
