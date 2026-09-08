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

enum AudioCodecAction {
    case useNoAudio
    case useOPUS
    case useSpeex
    case useSpeexVBR
}

@Observable
final class AudioCodecModel {

    struct Section: Identifiable {
        let codec: TeamTalkCodec

        var id: String {
            switch codec {
            case .opus:
                return "opus"
            case .speex:
                return "speex"
            case .speexVBR:
                return "speex-vbr"
            case .none:
                return "no-audio"
            default:
                return "unknown"
            }
        }
    }

    let activeCodec: TeamTalkCodec
    let sections: [Section]

    private let opusApplications: [Int32] = [TeamTalkOpusCodecConfiguration.applicationVOIP, TeamTalkOpusCodecConfiguration.applicationAudio]
    private let opusSampleRates: [Int32] = [8000, 12000, 16000, 24000, 48000]
    private let speexBandmodes: [Int32] = [0, 1, 2]

    var opusApplicationIndex: Int
    var opusSampleRateIndex: Int
    var opusChannelsIndex: Int
    var opusBitrate: Double
    var opusVBR: Bool
    var opusDTX: Bool
    var opusFrameSize: Double
    var opusTransmitInterval: Double {
        didSet {
            if opusFrameSize == 0 && Int32(opusTransmitInterval) > TeamTalkOpusCodecConfiguration.maxFrameSizeMilliseconds {
                opusFrameSize = Double(TeamTalkOpusCodecConfiguration.maxFrameSizeMilliseconds)
            } else if opusFrameSize >= opusTransmitInterval {
                opusFrameSize = 0
            }
        }
    }

    var speexSampleRateIndex: Int
    var speexQuality: Double
    var speexTransmitInterval: Double

    var speexVBRSampleRateIndex: Int
    var speexVBRQuality: Double
    var speexVBRBitrate: Double
    var speexVBRDTX: Bool
    var speexVBRTransmitInterval: Double

    init(
        activeCodec: TeamTalkCodec,
        opuscodec: TeamTalkOpusCodecConfiguration,
        speexcodec: TeamTalkSpeexCodecConfiguration,
        speexvbrcodec: TeamTalkSpeexVBRCodecConfiguration
    ) {
        self.activeCodec = activeCodec

        switch activeCodec {
        case .opus:
            sections = [.opus, .speex, .speexVBR, .none].map(Section.init)
        case .speex:
            sections = [.speex, .opus, .speexVBR, .none].map(Section.init)
        case .speexVBR:
            sections = [.speexVBR, .opus, .speex, .none].map(Section.init)
        case .none:
            fallthrough
        default:
            sections = [.none, .opus, .speex, .speexVBR].map(Section.init)
        }

        opusApplicationIndex = opusApplications.firstIndex(of: opuscodec.application) ?? 0
        opusSampleRateIndex = opusSampleRates.firstIndex(of: opuscodec.sampleRate) ?? 4
        opusChannelsIndex = opuscodec.channels == 2 ? 1 : 0
        let bitrate = within(TeamTalkOpusCodecConfiguration.bitrateRange.lowerBound, max_v: TeamTalkOpusCodecConfiguration.bitrateRange.upperBound, value: opuscodec.bitrate)
        opusBitrate = Double(bitrate) / 1000.0
        opusVBR = opuscodec.variableBitrateEnabled
        opusDTX = opuscodec.discontinuousTransmissionEnabled
        opusFrameSize = Double(opuscodec.frameSizeMilliseconds)
        opusTransmitInterval = Double(opuscodec.transmitIntervalMilliseconds)

        speexSampleRateIndex = Int(speexcodec.bandmode)
        speexQuality = Double(speexcodec.quality)
        speexTransmitInterval = Double(speexcodec.transmitIntervalMilliseconds)

        speexVBRSampleRateIndex = Int(speexvbrcodec.bandmode)
        speexVBRQuality = Double(speexvbrcodec.quality)
        speexVBRBitrate = Double(speexvbrcodec.maxBitrate) / 1000.0
        speexVBRDTX = speexvbrcodec.discontinuousTransmissionEnabled
        speexVBRTransmitInterval = Double(speexvbrcodec.transmitIntervalMilliseconds)
    }

    func saveOPUSCodec() -> TeamTalkOpusCodecConfiguration {
        var opuscodec = TeamTalkOpusCodecConfiguration()
        opuscodec.application = opusApplications[opusApplicationIndex]
        opuscodec.bitrate = Int32(opusBitrate) * 1000
        opuscodec.sampleRate = opusSampleRates[opusSampleRateIndex]
        opuscodec.channels = Int32(opusChannelsIndex + 1)
        opuscodec.transmitIntervalMilliseconds = Int32(opusTransmitInterval)
        opuscodec.discontinuousTransmissionEnabled = opusDTX
        opuscodec.variableBitrateEnabled = opusVBR
        opuscodec.frameSizeMilliseconds = Int32(opusFrameSize)
        return opuscodec
    }

    func saveSpeexCodec() -> TeamTalkSpeexCodecConfiguration {
        var speexcodec = TeamTalkSpeexCodecConfiguration()
        speexcodec.bandmode = speexBandmodes[speexSampleRateIndex]
        speexcodec.quality = Int32(speexQuality)
        speexcodec.transmitIntervalMilliseconds = Int32(speexTransmitInterval)
        return speexcodec
    }

    func saveSpeexVBRCodec() -> TeamTalkSpeexVBRCodecConfiguration {
        var speexvbrcodec = TeamTalkSpeexVBRCodecConfiguration()
        speexvbrcodec.bandmode = speexBandmodes[speexVBRSampleRateIndex]
        speexvbrcodec.quality = Int32(speexVBRQuality)
        speexvbrcodec.maxBitrate = Int32(speexVBRBitrate * 1000)
        speexvbrcodec.discontinuousTransmissionEnabled = speexVBRDTX
        speexvbrcodec.transmitIntervalMilliseconds = Int32(speexVBRTransmitInterval)
        return speexvbrcodec
    }

    func title(for codec: TeamTalkCodec) -> String {
        let title: String
        switch codec {
        case .opus:
            title = String(localized: "OPUS Codec", comment: "codec detail")
        case .speex:
            title = String(localized: "Speex Codec", comment: "codec detail")
        case .speexVBR:
            title = String(localized: "Speex Variable Bitrate Codec", comment: "codec detail")
        case .none:
            title = String(localized: "No Audio", comment: "codec detail")
        default:
            title = ""
        }

        if codec == activeCodec {
            return title + " " + String(localized: "(Active)", comment: "codec detail")
        }
        return title
    }
}
