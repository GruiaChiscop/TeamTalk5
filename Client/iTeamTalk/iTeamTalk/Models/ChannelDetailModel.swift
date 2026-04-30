/*
 * Copyright (c) 2005-2018, BearWare.dk
 *
 * Contact Information:
 *
 * Bjoern D. Rasmussen
 * Kirketoften 5
 * DK-8260 Viby J
 * Denmark
 * Email: contact@bearware.dk
 * Phone: +45 20 20 54 59
 * Web: http://www.bearware.dk
 *
 * This source code is part of the TeamTalk SDK owned by
 * BearWare.dk. Use of this file, or its compiled unit, requires a
 * TeamTalk SDK License Key issued by BearWare.dk.
 *
 * The TeamTalk SDK License Agreement along with its Terms and
 * Conditions are outlined in the file License.txt included with the
 * TeamTalk SDK distribution.
 *
 */

import SwiftUI
import TeamTalkKit

final class ChannelDetailModel: ObservableObject {
    private var configuration: TeamTalkChannelConfiguration
    private let isPasswordProtected: Bool
    let isExistingChannel: Bool

    @Published var nameText: String
    @Published var passwordText: String
    @Published var topicText: String
    @Published var isPermanent: Bool
    @Published var hasNoInterruptions: Bool
    @Published var hasNoVoiceActivation: Bool
    @Published var hasNoAudioRecording: Bool
    @Published var isHidden: Bool
    @Published var codecDescription: String
    @Published var errorMessage: String?
    @Published var shouldDismiss = false
    @Published var showingJoinAlert = false
    @Published var joinPassword = ""
    @Published var audioCodecModel: AudioCodecModel?

    convenience init(channel: Channel) {
        self.init(channel: TeamTalkChannel(channel))
    }

    init(channel: TeamTalkChannel) {
        var rawChannel = channel.cValue
        var configuration = TeamTalkChannelConfiguration(channel)

        if !channel.channelID.isValid {
            rawChannel.audiocodec = newAudioCodec(DEFAULT_AUDIOCODEC)
            configuration.audioCodec = rawChannel.audiocodec
        }
        self.configuration = configuration
        isPasswordProtected = channel.isPasswordProtected
        isExistingChannel = channel.channelID.isValid
        nameText = channel.name
        passwordText = channel.password
        topicText = channel.topic
        isPermanent = channel.types.contains(.permanent)
        hasNoInterruptions = channel.types.contains(.soloTransmit)
        hasNoVoiceActivation = channel.types.contains(.noVoiceActivation)
        hasNoAudioRecording = channel.types.contains(.noRecording)
        isHidden = channel.types.contains(.hidden)
        codecDescription = Self.codecDescription(for: rawChannel.audiocodec)
    }

    var navigationTitle: String {
        if !nameText.isEmpty {
            return nameText
        }
        if isExistingChannel {
            return String(localized: "Channel Detail", comment: "View Title")
        }
        return String(localized: "Create Channel", comment: "View Title")
    }

    func refreshCodecDescription(_ codec: AudioCodec) {
        codecDescription = Self.codecDescription(for: codec)
    }

    func createOrUpdate() {
        applyToConfiguration()

        Task { [weak self] in
            guard let self else { return }

            do {
                if configuration.id == 0 {
                    try await TeamTalkClient.shared.joinChannel(configuration)
                } else {
                    try await TeamTalkClient.shared.updateChannel(configuration)
                }

                await MainActor.run {
                    self.shouldDismiss = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func joinChannelPressed() {
        if isPasswordProtected || !configuration.password.isEmpty {
            //joinPassword = passwordText
            showingJoinAlert = true
        } else {
            guard let channel = TeamTalkClient.shared.channel(id: TeamTalkChannelID(configuration.id)) else {
                self.errorMessage = "Channel not found"
                return
            }

            Task { [weak self] in
                guard let self else { return }

                do {
                    try await TeamTalkClient.shared.joinChannel(channel)
                    await MainActor.run {
                        self.shouldDismiss = true
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    func joinWithPassword() {
        guard let channel = TeamTalkClient.shared.channel(id: TeamTalkChannelID(configuration.id)) else {
            self.errorMessage = "Channel not found"
            return
        }
        let password = joinPassword

        Task { [weak self] in
            guard let self else { return }

            do {
                try await TeamTalkClient.shared.joinChannel(channel, password: password)
                await MainActor.run {
                    self.shouldDismiss = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func deleteChannel() {
        guard let channel = TeamTalkClient.shared.channel(id: TeamTalkChannelID(configuration.id)) else {
            self.errorMessage = "Channel not found"
            return
        }

        Task { [weak self] in
            guard let self else { return }

            do {
                try await TeamTalkClient.shared.removeChannel(channel)
                await MainActor.run {
                    self.shouldDismiss = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func makeAudioCodecModel() -> AudioCodecModel {
        var opuscodec = newOpusCodec()
        var speexcodec = newSpeexCodec()
        var speexvbrcodec = newSpeexVBRCodec()
        var activeCodec = configuration.audioCodec

        switch configuration.audioCodec.nCodec {
        case SPEEX_CODEC:
            speexcodec = TeamTalkAudioCodec.speexCodec(from: configuration.audioCodec)
        case SPEEX_VBR_CODEC:
            speexvbrcodec = TeamTalkAudioCodec.speexVBRCodec(from: configuration.audioCodec)
        case OPUS_CODEC:
            opuscodec = TeamTalkAudioCodec.opusCodec(from: configuration.audioCodec)
        case NO_CODEC:
            if configuration.id == 0 {
                activeCodec.nCodec = OPUS_CODEC
            }
        default:
            activeCodec.nCodec = NO_CODEC
        }

        return AudioCodecModel(
            activeCodec: activeCodec.nCodec,
            opuscodec: opuscodec,
            speexcodec: speexcodec,
            speexvbrcodec: speexvbrcodec
        )
    }

    func applyCodecAction(_ action: AudioCodecAction, codecModel: AudioCodecModel) {
        switch action {
        case .useNoAudio:
            configuration.audioCodec.nCodec = NO_CODEC
        case .useOPUS:
            var opuscodec = newOpusCodec()
            codecModel.saveOPUSCodec(to: &opuscodec)
            TeamTalkAudioCodec.setOpusCodec(opuscodec, on: &configuration.audioCodec)
        case .useSpeex:
            var speexcodec = newSpeexCodec()
            codecModel.saveSpeexCodec(to: &speexcodec)
            TeamTalkAudioCodec.setSpeexCodec(speexcodec, on: &configuration.audioCodec)
        case .useSpeexVBR:
            var speexvbrcodec = newSpeexVBRCodec()
            codecModel.saveSpeexVBRCodec(to: &speexvbrcodec)
            TeamTalkAudioCodec.setSpeexVBRCodec(speexvbrcodec, on: &configuration.audioCodec)
        }
        refreshCodecDescription(configuration.audioCodec)
    }

    private func applyToConfiguration() {
        configuration.name = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        configuration.password = passwordText
        configuration.topic = topicText
        configuration.types = makeChannelTypes()
    }

    private func updateChannelType(_ types: inout TeamTalkChannelTypes, flag: TeamTalkChannelTypes, enabled: Bool) {
        if enabled {
            types.insert(flag)
        } else {
            types.remove(flag)
        }
    }

    private func makeChannelTypes() -> TeamTalkChannelTypes {
        var types: TeamTalkChannelTypes = .default
        updateChannelType(&types, flag: .permanent, enabled: isPermanent)
        updateChannelType(&types, flag: .soloTransmit, enabled: hasNoInterruptions)
        updateChannelType(&types, flag: .noVoiceActivation, enabled: hasNoVoiceActivation)
        updateChannelType(&types, flag: .noRecording, enabled: hasNoAudioRecording)
        updateChannelType(&types, flag: .hidden, enabled: isHidden)
        return types
    }

    private static func codecDescription(for codec: AudioCodec) -> String {
        switch codec.nCodec {
        case OPUS_CODEC:
            let opus = TeamTalkAudioCodec.opusCodec(from: codec)
            let chans = opus.nChannels > 1 ? String(localized: "Stereo", comment: "create channel") : String(localized: "Mono", comment: "create channel")
            return "OPUS \(opus.nSampleRate / 1000) KHz \(opus.nBitRate / 1000) KB/s " + chans
        case SPEEX_CODEC:
            let speex = TeamTalkAudioCodec.speexCodec(from: codec)
            return "Speex " + bandmodeString(speex.nBandmode)
        case SPEEX_VBR_CODEC:
            let speexvbr = TeamTalkAudioCodec.speexVBRCodec(from: codec)
            return "Speex VBR " + bandmodeString(speexvbr.nBandmode)
        case NO_CODEC:
            fallthrough
        default:
            return String(localized: "No Audio", comment: "create channel")
        }
    }

    private static func bandmodeString(_ bandmode: INT32) -> String {
        switch bandmode {
        case 2:
            return String(localized: "32 KHz", comment: "create channel")
        case 1:
            return String(localized: "16 KHz", comment: "create channel")
        default:
            return String(localized: "8 KHz", comment: "create channel")
        }
    }
}

extension ChannelDetailModel: Identifiable {
    var id: ObjectIdentifier { ObjectIdentifier(self) }
}
