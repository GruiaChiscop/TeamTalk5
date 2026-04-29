import Foundation
import TeamTalkC

public struct TeamTalkSoundDevice: Identifiable {
    public let rawValue: SoundDevice

    public init(_ rawValue: SoundDevice) {
        self.rawValue = rawValue
    }

    public var cValue: SoundDevice {
        rawValue
    }

    public var id: Int32 {
        rawValue.id
    }

    public var soundDeviceID: TeamTalkSoundDeviceID {
        rawValue.soundDeviceID
    }

    public var physicalDeviceID: TeamTalkSoundDeviceID {
        rawValue.physicalDeviceID
    }

    public var name: String {
        rawValue.name
    }

    public var deviceIdentifier: String {
        rawValue.deviceIdentifier
    }

    public var soundSystem: TeamTalkSoundSystem {
        rawValue.soundSystem
    }

    public var waveDeviceID: Int32 {
        rawValue.waveDeviceID
    }

    public var maxInputChannels: Int32 {
        rawValue.maxInputChannels
    }

    public var maxOutputChannels: Int32 {
        rawValue.maxOutputChannels
    }

    public var inputSampleRates: [Int32] {
        rawValue.supportedInputSampleRates
    }

    public var outputSampleRates: [Int32] {
        rawValue.supportedOutputSampleRates
    }

    public var defaultSampleRate: Int32 {
        rawValue.defaultSampleRate
    }

    public var features: TeamTalkSoundDeviceFeatures {
        rawValue.features
    }

    public var isShared: Bool {
        rawValue.isShared
    }

    public var supportsEchoCancellation: Bool {
        rawValue.supportsEchoCancellation
    }

    public var supportsAutomaticGainControl: Bool {
        rawValue.supportsAutomaticGainControl
    }

    public var supportsDenoise: Bool {
        rawValue.supportsDenoise
    }

    public var supportsDuplexMode: Bool {
        rawValue.supportsDuplexMode
    }

    public var isDefaultCommunicationDevice: Bool {
        rawValue.isDefaultCommunicationDevice
    }
}

public struct TeamTalkSoundDeviceEffects {
    public let rawValue: SoundDeviceEffects

    public init(_ rawValue: SoundDeviceEffects) {
        self.rawValue = rawValue
    }

    public var cValue: SoundDeviceEffects {
        rawValue
    }

    public var automaticGainControlEnabled: Bool {
        rawValue.automaticGainControlEnabled
    }

    public var denoiseEnabled: Bool {
        rawValue.denoiseEnabled
    }

    public var echoCancellationEnabled: Bool {
        rawValue.echoCancellationEnabled
    }

    public var enabledEffects: TeamTalkSoundDeviceFeatures {
        rawValue.enabledEffects
    }
}

public struct TeamTalkSoundDeviceEffectsConfiguration {
    public var automaticGainControlEnabled: Bool
    public var denoiseEnabled: Bool
    public var echoCancellationEnabled: Bool

    public init(
        automaticGainControlEnabled: Bool = false,
        denoiseEnabled: Bool = false,
        echoCancellationEnabled: Bool = false
    ) {
        self.automaticGainControlEnabled = automaticGainControlEnabled
        self.denoiseEnabled = denoiseEnabled
        self.echoCancellationEnabled = echoCancellationEnabled
    }

    public init(_ effects: TeamTalkSoundDeviceEffects) {
        self.init(
            automaticGainControlEnabled: effects.automaticGainControlEnabled,
            denoiseEnabled: effects.denoiseEnabled,
            echoCancellationEnabled: effects.echoCancellationEnabled
        )
    }

    public var enabledEffects: TeamTalkSoundDeviceFeatures {
        get {
            var effects: TeamTalkSoundDeviceFeatures = []
            if automaticGainControlEnabled {
                effects.insert(.automaticGainControl)
            }
            if denoiseEnabled {
                effects.insert(.denoise)
            }
            if echoCancellationEnabled {
                effects.insert(.echoCancellation)
            }
            return effects
        }
        set {
            automaticGainControlEnabled = newValue.contains(.automaticGainControl)
            denoiseEnabled = newValue.contains(.denoise)
            echoCancellationEnabled = newValue.contains(.echoCancellation)
        }
    }

    public var cValue: SoundDeviceEffects {
        var effects = SoundDeviceEffects()
        effects.automaticGainControlEnabled = automaticGainControlEnabled
        effects.denoiseEnabled = denoiseEnabled
        effects.echoCancellationEnabled = echoCancellationEnabled
        return effects
    }
}

public struct TeamTalkSharedSoundDeviceConfiguration {
    public var sampleRate: Int32
    public var channels: Int32
    public var frameSize: Int32

    public init(
        sampleRate: Int32 = 0,
        channels: Int32 = 0,
        frameSize: Int32 = 0
    ) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.frameSize = frameSize
    }

    public var usesDefaultSampleRate: Bool {
        sampleRate == 0
    }

    public var usesDefaultChannels: Bool {
        channels == 0
    }

    public var usesDefaultFrameSize: Bool {
        frameSize == 0
    }

    public var usesDefaultValues: Bool {
        usesDefaultSampleRate && usesDefaultChannels && usesDefaultFrameSize
    }
}

public struct TeamTalkSoundDuplexConfiguration {
    public var inputDeviceID: TeamTalkSoundDeviceID
    public var outputDeviceID: TeamTalkSoundDeviceID

    public init(
        inputDeviceID: TeamTalkSoundDeviceID,
        outputDeviceID: TeamTalkSoundDeviceID
    ) {
        self.inputDeviceID = inputDeviceID
        self.outputDeviceID = outputDeviceID
    }

    public init(
        inputDevice: TeamTalkSoundDevice,
        outputDevice: TeamTalkSoundDevice
    ) {
        self.init(
            inputDeviceID: inputDevice.soundDeviceID,
            outputDeviceID: outputDevice.soundDeviceID
        )
    }

    public var inputDeviceRawID: Int32 {
        inputDeviceID.cValue
    }

    public var outputDeviceRawID: Int32 {
        outputDeviceID.cValue
    }
}
