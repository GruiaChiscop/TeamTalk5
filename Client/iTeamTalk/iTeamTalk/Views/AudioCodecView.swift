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

struct AudioCodecView: View {
    @Bindable var model: AudioCodecModel
    let performAction: (AudioCodecAction) -> Void

    var body: some View {
        Form {
            ForEach(model.sections) { section in
                Section(model.title(for: section.codec)) {
                    rows(for: section.codec)
                }
            }
        }
        .navigationTitle("Audio Codec")
    }

    @ViewBuilder
    private func rows(for codec: TeamTalkCodec) -> some View {
        switch codec {
        case .opus:
            opusRows
        case .speex:
            speexRows
        case .speexVBR:
            speexVBRRows
        case .none:
            Button {
                performAction(.useNoAudio)
            } label: {
                Text("Use No Audio")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        default:
            EmptyView()
        }
    }

    private var opusRows: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text("Application")
                Picker("Application", selection: $model.opusApplicationIndex) {
                    Text("VoIP").tag(0)
                    Text("Music").tag(1)
                }
                .pickerStyle(.segmented)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample Rate")
                Picker("Sample Rate", selection: $model.opusSampleRateIndex) {
                    Text("8 KHz").tag(0)
                    Text("12 KHz").tag(1)
                    Text("16 KHz").tag(2)
                    Text("24 KHz").tag(3)
                    Text("48 KHz").tag(4)
                }
                .pickerStyle(.segmented)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Audio Channels")
                Picker("Audio Channels", selection: $model.opusChannelsIndex) {
                    Text("Mono").tag(0)
                    Text("Stereo").tag(1)
                }
                .pickerStyle(.segmented)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text("Bitrate")
                    Spacer(minLength: 16)
                    Text("\(Int(model.opusBitrate.rounded())) KB/s")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                Slider(value: $model.opusBitrate,
                       in: Double(TeamTalkOpusCodecConfiguration.bitrateRange.lowerBound) / 1000.0...Double(TeamTalkOpusCodecConfiguration.bitrateRange.upperBound) / 1000.0,
                       step: 1) {
                    Text("Bitrate")
                }
            }
            Toggle("Variable Bitrate", isOn: $model.opusVBR)
            Toggle("DTX", isOn: $model.opusDTX)
            Stepper(value: $model.opusFrameSize, in: 0...Double(TeamTalkOpusCodecConfiguration.maxFrameSizeMilliseconds), step: 5) {
                HStack(spacing: 12) {
                    Text("Frame Size")
                    Spacer(minLength: 16)
                    Text("\(Int(model.opusFrameSize.rounded())) ms")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Stepper(value: $model.opusTransmitInterval, in: 20...500, step: 20) {
                HStack(spacing: 12) {
                    Text("Transmit Interval")
                    Spacer(minLength: 16)
                    Text("\(Int(model.opusTransmitInterval.rounded())) ms")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                performAction(.useOPUS)
            } label: {
                Text("Use OPUS Codec")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var speexRows: some View {
        Group {
            speexSampleRatePicker(selectedIndex: $model.speexSampleRateIndex)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text("Quality")
                    Spacer(minLength: 16)
                    Text("\(Int(model.speexQuality.rounded()))")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                Slider(value: $model.speexQuality, in: 0...10, step: 1) {
                    Text("Quality")
                }
            }
            Stepper(value: $model.speexTransmitInterval, in: 20...500, step: 20) {
                HStack(spacing: 12) {
                    Text("Transmit Interval")
                    Spacer(minLength: 16)
                    Text("\(Int(model.speexTransmitInterval.rounded())) ms")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                performAction(.useSpeex)
            } label: {
                Text("Use Speex Codec")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var speexVBRRows: some View {
        Group {
            speexSampleRatePicker(selectedIndex: $model.speexVBRSampleRateIndex)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text("Quality")
                    Spacer(minLength: 16)
                    Text("\(Int(model.speexVBRQuality.rounded()))")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                Slider(value: $model.speexVBRQuality, in: 0...10, step: 1) {
                    Text("Quality")
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text("Bitrate")
                    Spacer(minLength: 16)
                    Text("\(Int(model.speexVBRBitrate.rounded())) KB/s")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                Slider(value: $model.speexVBRBitrate,
                       in: 0...Double(TeamTalkSpeexVBRCodecConfiguration.maxBitrateUpperBound) / 1000.0,
                       step: 1) {
                    Text("Bitrate")
                }
            }
            Toggle("DTX", isOn: $model.speexVBRDTX)
            Stepper(value: $model.speexVBRTransmitInterval, in: 20...500, step: 20) {
                HStack(spacing: 12) {
                    Text("Transmit Interval")
                    Spacer(minLength: 16)
                    Text("\(Int(model.speexVBRTransmitInterval.rounded())) ms")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                performAction(.useSpeexVBR)
            } label: {
                Text("Use Speex VBR Codec")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func speexSampleRatePicker(selectedIndex: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample Rate")
            Picker("Sample Rate", selection: selectedIndex) {
                Text("8 KHz").tag(0)
                Text("16 KHz").tag(1)
                Text("32 KHz").tag(2)
            }
            .pickerStyle(.segmented)
        }
    }
}
