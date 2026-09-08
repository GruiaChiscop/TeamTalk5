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

import Observation
import SwiftUI
import TeamTalkKit

@Observable
final class ChannelDetailModel {
    let session: TeamTalkSession
    private var configuration: TeamTalkChannelConfiguration
    private let isPasswordProtected: Bool
    let isExistingChannel: Bool

    var nameText: String
    var passwordText: String
    var topicText: String
    var isPermanent: Bool
    var hasNoInterruptions: Bool
    var hasNoVoiceActivation: Bool
    var hasNoAudioRecording: Bool
    var isHidden: Bool
    var codecDescription: String
    var errorMessage: String?
    var shouldDismiss = false
    var showingJoinAlert = false
    var joinPassword = ""
    var audioCodecModel: AudioCodecModel?

    var isPresentingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    var isShowingAudioCodec: Bool {
        get { audioCodecModel != nil }
        set { if !newValue { audioCodecModel = nil } }
    }

    init(channel: TeamTalkChannel, session: TeamTalkSession) {
        self.session = session
        var configuration = TeamTalkChannelConfiguration(channel)

        if !channel.channelID.isValid {
            configuration.audioCodec = .opus(TeamTalkOpusCodecConfiguration())
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
        codecDescription = Self.codecDescription(for: configuration.audioCodec)
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

    func refreshCodecDescription(_ codec: TeamTalkAudioCodecConfiguration) {
        codecDescription = Self.codecDescription(for: codec)
    }

    func createOrUpdate() {
        applyToConfiguration()

        Task { [weak self] in
            guard let self else { return }

            do {
                if configuration.id == 0 {
                    try await self.session.joinChannel(configuration)
                } else {
                    try await self.session.updateChannel(configuration)
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
            guard let channel = session.channel(id: TeamTalkChannelID(configuration.id)) else {
                self.errorMessage = "Channel not found"
                return
            }

            Task { [weak self] in
                guard let self else { return }

                do {
                    try await self.session.joinChannel(channel)
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
        guard let channel = session.channel(id: TeamTalkChannelID(configuration.id)) else {
            self.errorMessage = "Channel not found"
            return
        }
        let password = joinPassword

        Task { [weak self] in
            guard let self else { return }

            do {
                try await self.session.joinChannel(channel, password: password)
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
        guard let channel = session.channel(id: TeamTalkChannelID(configuration.id)) else {
            self.errorMessage = "Channel not found"
            return
        }

        Task { [weak self] in
            guard let self else { return }

            do {
                try await self.session.removeChannel(channel)
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
        var opuscodec = TeamTalkOpusCodecConfiguration()
        var speexcodec = TeamTalkSpeexCodecConfiguration()
        var speexvbrcodec = TeamTalkSpeexVBRCodecConfiguration()
        var activeCodec = configuration.audioCodec.codec

        switch configuration.audioCodec {
        case .speex(let speexConfiguration):
            speexcodec = speexConfiguration
        case .speexVBR(let speexVBRConfiguration):
            speexvbrcodec = speexVBRConfiguration
        case .opus(let opusConfiguration):
            opuscodec = opusConfiguration
        case .none:
            if configuration.id == 0 {
                activeCodec = .opus
            }
        }

        return AudioCodecModel(
            activeCodec: activeCodec,
            opuscodec: opuscodec,
            speexcodec: speexcodec,
            speexvbrcodec: speexvbrcodec
        )
    }

    func applyCodecAction(_ action: AudioCodecAction, codecModel: AudioCodecModel) {
        switch action {
        case .useNoAudio:
            configuration.audioCodec = .none
        case .useOPUS:
            configuration.audioCodec = .opus(codecModel.saveOPUSCodec())
        case .useSpeex:
            configuration.audioCodec = .speex(codecModel.saveSpeexCodec())
        case .useSpeexVBR:
            configuration.audioCodec = .speexVBR(codecModel.saveSpeexVBRCodec())
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

    private static func codecDescription(for codec: TeamTalkAudioCodecConfiguration) -> String {
        switch codec {
        case .opus(let opus):
            let chans = opus.channels > 1 ? String(localized: "Stereo", comment: "create channel") : String(localized: "Mono", comment: "create channel")
            return "OPUS \(opus.sampleRate / 1000) KHz \(opus.bitrate / 1000) KB/s " + chans
        case .speex(let speex):
            return "Speex " + bandmodeString(speex.bandmode)
        case .speexVBR(let speexvbr):
            return "Speex VBR " + bandmodeString(speexvbr.bandmode)
        case .none:
            return String(localized: "No Audio", comment: "create channel")
        }
    }

    private static func bandmodeString(_ bandmode: Int32) -> String {
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
