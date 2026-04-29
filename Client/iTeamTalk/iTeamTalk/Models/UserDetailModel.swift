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

final class UserDetailModel: ObservableObject {

    struct SubscriptionRow: Identifiable {
        let title: String
        let type: TeamTalkSubscriptions

        var id: TeamTalkSubscriptions.RawValue {
            type.rawValue
        }
    }

    let userID: TeamTalkUserID
    let displayName: String
    let subscriptionRows: [SubscriptionRow]

    private let initialUser: TeamTalkUser

    @Published var errorMessage: String?
    @Published var usernameText: String
    @Published var voiceVolume: Double
    @Published var mediaVolume: Double
    @Published var isVoiceMuted: Bool
    @Published var isMediaMuted: Bool
    @Published private var subscriptions: TeamTalkSubscriptions

    convenience init(user: User) {
        self.init(user: TeamTalkUser(user))
    }

    init(user: TeamTalkUser) {
        initialUser = user
        userID = user.userID
        displayName = getDisplayName(user.rawValue)
        usernameText = user.username
        voiceVolume = Double(refVolumeToPercent(Int(user.rawValue.nVolumeVoice)))
        mediaVolume = Double(refVolumeToPercent(Int(user.rawValue.nVolumeMediaFile)))
        isVoiceMuted = user.states.contains(.voiceMuted)
        isMediaMuted = user.states.contains(.mediaFileMuted)
        subscriptions = user.localSubscriptions
        subscriptionRows = [
            SubscriptionRow(title: String(localized: "User Messages", comment: "user detail"), type: .userMessages),
            SubscriptionRow(title: String(localized: "Channel Messages", comment: "user detail"), type: .channelMessages),
            SubscriptionRow(title: String(localized: "Broadcast Messages", comment: "user detail"), type: .broadcastMessages),
            SubscriptionRow(title: String(localized: "Voice", comment: "user detail"), type: .voice),
            SubscriptionRow(title: String(localized: "WebCam", comment: "user detail"), type: .videoCapture),
            SubscriptionRow(title: String(localized: "Media File", comment: "user detail"), type: .mediaFile),
            SubscriptionRow(title: String(localized: "Desktop", comment: "user detail"), type: .desktop)
        ]
    }

    var userid: INT32 {
        userID.cValue
    }

    private var currentUser: TeamTalkUser {
        TeamTalkClient.shared.user(id: userID) ?? initialUser
    }

    func isSubscribed(to subscription: TeamTalkSubscriptions) -> Bool {
        subscriptions.contains(subscription)
    }

    func voiceVolumeChanged(_ value: Double) {
        voiceVolume = value
        TeamTalkClient.shared.setUserVolume(user: currentUser, stream: .voice, volume: INT32(refVolume(value)))
        TeamTalkClient.shared.pump(.userStateChanged, source: currentUser)
    }

    func mediaVolumeChanged(_ value: Double) {
        mediaVolume = value
        TeamTalkClient.shared.setUserVolume(user: currentUser, stream: .mediaFileAudio, volume: INT32(refVolume(value)))
        TeamTalkClient.shared.pump(.userStateChanged, source: currentUser)
    }

    func muteVoice(_ muted: Bool) {
        isVoiceMuted = muted
        TeamTalkClient.shared.setUserMute(user: currentUser, stream: .voice, muted: muted)
        TeamTalkClient.shared.pump(.userStateChanged, source: currentUser)
    }

    func muteMediaStream(_ muted: Bool) {
        isMediaMuted = muted
        TeamTalkClient.shared.setUserMute(user: currentUser, stream: .mediaFileAudio, muted: muted)
        TeamTalkClient.shared.pump(.userStateChanged, source: currentUser)
    }

    func setSubscription(_ subscription: TeamTalkSubscriptions, enabled: Bool) {
        if enabled {
            subscriptions.insert(subscription)
            TeamTalkClient.shared.subscribe(user: currentUser, subscriptions: subscription)
        } else {
            subscriptions.remove(subscription)
            TeamTalkClient.shared.unsubscribe(user: currentUser, subscriptions: subscription)
        }
    }

    func kickUser() {
        Task { [weak self] in
            guard let self else { return }

            do {
                let user = currentUser
                let channel = TeamTalkClient.shared.channel(id: user.channelIdentifier)
                try await TeamTalkClient.shared.kickUser(user, fromChannel: channel)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func kickAndBanUser() {
        Task { [weak self] in
            guard let self else { return }

            do {
                let user = currentUser
                try await TeamTalkClient.shared.kickUser(user)
                try await TeamTalkClient.shared.banUser(user)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
