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

struct UserDetailView: View {
    @Bindable var model: UserDetailModel
    var body: some View {
        Form {
            Section("General") {
                VStack(alignment: .leading) {
                Text("Username")
                    Text(model.usernameText)
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading) {
                    Text("User ID")
                    Text(String(model.userid))
                }
                .accessibilityElement(children: .combine)
                //todo: add TeamTalk client version
                VStack(alignment: .leading) {
                    Text("Client name")
                    Text(model.clientName)
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading) {
                    Text("Status mode")
                    Text(model.statusMode)
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading) {
                    Text("Status message")
                    Text(model.statusMessage)
                }
                .accessibilityElement(children: .combine)
                            }

            Section("Volume Controls") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text("Voice Volume")
                        Spacer(minLength: 16)
                        Text("\(Int(model.voiceVolume.rounded()))")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    Slider(value: $model.voiceVolume, in: 0...100, step: 1) {
                        Text("Voice Volume")
                    }
                }
                Toggle("Mute Voice", isOn: $model.isVoiceMuted)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text("Media File Volume")
                        Spacer(minLength: 16)
                        Text("\(Int(model.mediaVolume.rounded()))")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    Slider(value: $model.mediaVolume, in: 0...100, step: 1) {
                        Text("Media File Volume")
                    }
                }
                Toggle("Mute Media File", isOn: $model.isMediaMuted)
            }

            Section("Subscriptions") {
                ForEach(model.subscriptionRows) { row in
                    Toggle(row.title, isOn: model.subscriptionBinding(for: row.type))
                }
            }

            Section("Actions") {
                Button(action: model.kickUser) {
                    Text("Kick User")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Button(role: .destructive, action: model.kickAndBanUser) {
                    Text("Kick and Ban User")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle(model.displayName)
        .alert("Error", isPresented: $model.isPresentingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
