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
final class UserDetailModel {

    struct SubscriptionRow: Identifiable {
        let title: String
        let type: TeamTalkSubscriptions

        var id: TeamTalkSubscriptions.RawValue {
            type.rawValue
        }
    }

    let session: TeamTalkSession
    let userID: TeamTalkUserID
    let displayName: String
    let subscriptionRows: [SubscriptionRow]
    private let initialUser: TeamTalkUser

    var errorMessage: String?
    var usernameText: String
    var voiceVolume: Double
    var mediaVolume: Double
    var isVoiceMuted: Bool
    var isMediaMuted: Bool
    private var subscriptions: TeamTalkSubscriptions

    init(user: TeamTalkUser, session: TeamTalkSession) {
        self.session = session
        initialUser = user
        userID = user.userID
        displayName = getDisplayName(user)
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
        session.user(id: userID) ?? initialUser
    }

    var clientName: String {
        currentUser.clientName
    }

    var nickname: String {
        currentUser.nickname
    }

    var statusMessage: String {
        currentUser.statusMessage
    }

    var statusMode: String {
        "\(currentUser.statusMode)"
    }

    func isSubscribed(to subscription: TeamTalkSubscriptions) -> Bool {
        subscriptions.contains(subscription)
    }

    func voiceVolumeChanged(_ value: Double) {
        voiceVolume = value
        session.setUserVolume(currentUser, stream: .voice, volume: INT32(refVolume(value)))
    }

    func mediaVolumeChanged(_ value: Double) {
        mediaVolume = value
        session.setUserVolume(currentUser, stream: .mediaFileAudio, volume: INT32(refVolume(value)))
    }

    func muteVoice(_ muted: Bool) {
        isVoiceMuted = muted
        session.setUserMute(currentUser, stream: .voice, muted: muted)
    }

    func muteMediaStream(_ muted: Bool) {
        isMediaMuted = muted
        session.setUserMute(currentUser, stream: .mediaFileAudio, muted: muted)
    }

    func setSubscription(_ subscription: TeamTalkSubscriptions, enabled: Bool) {
        if enabled {
            subscriptions.insert(subscription)
            session.subscribe(subscription, to: currentUser)
        } else {
            subscriptions.remove(subscription)
            session.unsubscribe(subscription, from: currentUser)
        }
    }

    func kickUser() {
        Task { [weak self] in
            guard let self else { return }

            do {
                let user = currentUser
                let channel = self.session.channel(id: user.channelIdentifier)
                try await self.session.kickUser(user, from: channel)
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
                try await self.session.kickUser(user)
                try await self.session.banUser(user)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
