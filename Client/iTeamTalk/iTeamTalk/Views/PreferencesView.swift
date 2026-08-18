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

import AVFoundation
import SwiftUI
import TeamTalkKit

struct PreferencesView: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Form {
            generalSection
            displaySection
            soundSection
            soundEventsSection
            ttsSection
            connectionSection
            subscriptionsSection
            versionSection
        }
        .navigationTitle("Preferences")
    }

    private var generalSection: some View {
        Section("General") {
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent {
                    TextField("", text: $model.nickname)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .accessibilityLabel(Text("Nickname"))
                } label: {
                    Text("Nickname")
                        .accessibilityHidden(true)
                }
                PreferenceSubtitle("Name displayed in channel list")
            }

            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                    Picker("Gender", selection: $model.genderIndex) {
                        Text("Male").tag(0)
                        Text("Female").tag(1)
                    }
                    .pickerStyle(.segmented)
                }
                PreferenceSubtitle("Show male or female icon")
            }

            NavigationLink {
                WebLoginView()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BearWare.dk Web Login")
                    Text("Login ID from BearWare.dk")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: $model.pushToTalkLock) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Push To Talk Lock")
                    Text("Double tap to lock TX button")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: $model.headsetTXToggle) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Headset TX Toggle")
                    Text("Toggle voice transmission using headset")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: $model.sendOnReturn) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Return Sends Message")
                    Text("Pressing Return-key sends text message")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var displaySection: some View {
        Section("Display") {
            Toggle(isOn: $model.proximitySensor) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Proximity Sensor")
                    Text("Turn off screen when holding phone near ear")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: $model.popupTextMessages) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show Text Messages Instantly")
                    Text("Pop up text message when new messages are received")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Stepper(value: $model.limitText, in: 1...Double(TT_STRLEN - 1), step: 1) {
                    HStack(spacing: 12) {
                        Text("Maximum Text Length")
                        Spacer(minLength: 16)
                        Text("\(Int(model.limitText.rounded()))")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            NavigationLink {
                PublicServerView()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Filter Server List")
                    Text("Limit types of servers to show")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: $model.showUsername) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show Usernames")
                    Text("Show usernames instead of nicknames")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sort Channels")
                    Picker("Sort Channels", selection: $model.channelSortIndex) {
                        Text("Ascending").tag(0)
                        Text("Popularity").tag(1)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var soundSection: some View {
        Section("Sound System") {
            PreferenceSlider(
                title: "Master Volume",
                value: $model.masterVolumePercent,
                range: 0...100,
                step: 10,
                valueText: { model.percentText($0) }
            )
            PreferenceSlider(
                title: "Media File Volume",
                value: $model.mediaFileVolumePercent,
                range: 0...100,
                step: 1,
                valueText: { "\(Int($0.rounded())) %" }
            )
            PreferenceSlider(
                title: "Microphone Gain",
                value: $model.microphoneGainPercent,
                range: 0...100,
                step: 10,
                valueText: { model.percentText($0) }
            )
            PreferenceSlider(
                title: "Voice Activation Level",
                value: $model.voiceActivationLevel,
                range: 0...Double(VOICEACT_DISABLED),
                step: 1,
                valueText: { model.voiceActivationValueText($0) }
            )
            NavigationLink {
                SoundDevicesView(session: model.session)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Setup Sound Devices")
                    Text("Choose input and output devices")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var soundEventsSection: some View {
        Section("Sound Events") {
            NavigationLink {
                SoundEventsView()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Setup Sound Events")
                    Text("Choose sounds events to play")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var ttsSection: some View {
        Section("Text To Speech Events") {
            NavigationLink {
                SpeechListView()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Speech")
                    Text("Select the text-to-speech voice to use")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            PreferenceSlider(
                title: "Speech Rate",
                value: $model.ttsRate,
                range: Double(AVSpeechUtteranceMinimumSpeechRate)...Double(AVSpeechUtteranceMaximumSpeechRate),
                step: 0.1,
                valueText: { String(format: "%.1f", $0) }
            )
            PreferenceSlider(
                title: "Speech Volume",
                value: $model.ttsVolume,
                range: 0...1,
                step: 0.1,
                valueText: { String(format: "%.1f", $0) }
            )
            NavigationLink {
                TextToSpeechEventsView()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Setup Announcements")
                    Text("Choose events to playback")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var connectionSection: some View {
        Section("Connection") {
            Toggle(isOn: $model.joinRootChannel) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Join Root Channel")
                    Text("Join root channel after login")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var subscriptionsSection: some View {
        Section("Default Subscriptions") {
            ForEach(model.subscriptionRows) { row in
                Toggle(isOn: model.subscriptionBinding(for: row)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title)
                        Text(row.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var versionSection: some View {
        Section("Version Information") {
            ForEach(model.versionRows) { row in
                LabeledContent(row.title, value: row.value)
            }
        }
    }

}

struct PreferenceSubtitle: View {
    let text: Text

    init(_ text: LocalizedStringKey) {
        self.text = Text(text)
    }

    init(verbatim text: String) {
        self.text = Text(verbatim: text)
    }

    init(_ text: Text) {
        self.text = text
    }

    var body: some View {
        text
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

/// A titled slider with a trailing value label. No subtitle: the value is only shown once.
struct PreferenceSlider: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueText: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(title)
                Spacer(minLength: 16)
                Text(valueText(value))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}
