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
    var voiceVolume: Double {
        didSet {
            session.setUserVolume(currentUser, stream: .voice, volume: INT32(refVolume(voiceVolume)))
        }
    }
    var mediaVolume: Double {
        didSet {
            session.setUserVolume(currentUser, stream: .mediaFileAudio, volume: INT32(refVolume(mediaVolume)))
        }
    }
    var isVoiceMuted: Bool {
        didSet {
            session.setUserMute(currentUser, stream: .voice, muted: isVoiceMuted)
        }
    }
    var isMediaMuted: Bool {
        didSet {
            session.setUserMute(currentUser, stream: .mediaFileAudio, muted: isMediaMuted)
        }
    }
    private var subscriptions: TeamTalkSubscriptions

    var isPresentingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    init(user: TeamTalkUser, session: TeamTalkSession) {
        self.session = session
        initialUser = user
        userID = user.userID
        displayName = getDisplayName(user)
        usernameText = user.username
        voiceVolume = Double(refVolumeToPercent(Int(user.voiceVolume)))
        mediaVolume = Double(refVolumeToPercent(Int(user.mediaFileVolume)))
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

    func subscriptionBinding(for subscription: TeamTalkSubscriptions) -> Binding<Bool> {
        Binding(
            get: { self.isSubscribed(to: subscription) },
            set: { enabled in
                if enabled {
                    self.subscriptions.insert(subscription)
                    self.session.subscribe(subscription, to: self.currentUser)
                } else {
                    self.subscriptions.remove(subscription)
                    self.session.unsubscribe(subscription, from: self.currentUser)
                }
            }
        )
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
