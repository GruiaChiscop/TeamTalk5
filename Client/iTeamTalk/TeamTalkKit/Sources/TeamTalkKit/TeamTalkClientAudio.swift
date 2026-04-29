import Foundation
import TeamTalkC

extension TeamTalkClient {
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

public func soundInputPreprocessorInfo() -> AudioPreprocessor? {
    guard let instance else {
        return nil
    }

    var preprocessor = AudioPreprocessor()
    guard TT_GetSoundInputPreprocessEx(instance, &preprocessor) != 0 else {
        return nil
    }
    return preprocessor
}

public func soundInputPreprocessor() -> TeamTalkAudioPreprocessorConfiguration? {
    soundInputPreprocessorInfo().map(TeamTalkAudioPreprocessorConfiguration.init)
}

@discardableResult
public func setSoundInputPreprocessor(_ preprocessor: inout AudioPreprocessor) -> Bool {
    guard let instance else {
        return false
    }

    return TT_SetSoundInputPreprocessEx(instance, &preprocessor) != 0
}

@discardableResult
public func setSoundInputPreprocessor(_ configuration: TeamTalkAudioPreprocessorConfiguration) -> Bool {
    var preprocessor = configuration.cValue
    return setSoundInputPreprocessor(&preprocessor)
}

@discardableResult
public func setSoundInputPreprocessor(_ type: TeamTalkAudioPreprocessorType) -> Bool {
    setSoundInputPreprocessor(TeamTalkAudioPreprocessorConfiguration(type: type))
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

}
