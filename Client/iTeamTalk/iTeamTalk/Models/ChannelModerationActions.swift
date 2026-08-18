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

// Mute/kick/ban/move actions for users in the channel list, split out of
// ChannelListModel. Reads channel/user state from `owner` rather than
// duplicating it.
@Observable
final class ChannelModerationActions {
    weak var owner: ChannelListModel?

    var moveusers = Set<TeamTalkUserID>()

    func muteUser(userID: TeamTalkUserID) {
        guard let owner, let user = owner.users[userID] else { return }
        TeamTalkClient.shared.setUserMute(
            user,
            stream: .mediaFileAudio,
            muted: !user.states.contains(.mediaFileMuted)
        )
        TeamTalkClient.shared.setUserMute(
            user,
            stream: .voice,
            muted: !user.states.contains(.voiceMuted)
        )
    }

    func moveUser(userID: TeamTalkUserID) {
        guard let owner, let user = owner.users[userID] else { return }

        let isSelected = moveusers.contains(userID)
        if isSelected {
            moveusers.remove(userID)
        } else {
            moveusers.insert(userID)
        }

        owner.refreshChannelList()
        announceForAccessibility(
            String(
                format: isSelected
                    ? String(localized: "%@ deselected", comment: "channel list")
                    : String(localized: "%@ selected", comment: "channel list"),
                getDisplayName(user)
            )
        )
    }

    func kickUser(userID: TeamTalkUserID) {
        guard let owner else { return }
        let op = TeamTalkClient.shared.isChannelOperator(in: owner.curchannel)
        guard owner.effectiveUserRights.contains(.canKickUsers) || op else { return }
        guard let user = owner.users[userID] else { return }
        let channel = owner.curchannel.channelID.isValid ? owner.curchannel : nil

        Task { [weak owner] in
            guard let owner else { return }
            do {
                try await TeamTalkClient.shared.kickUser(user, from: channel)
            } catch {
                await owner.presentError(error.localizedDescription)
            }
        }
    }

    func banUser(userID: TeamTalkUserID) {
        guard let owner else { return }
        let op = TeamTalkClient.shared.isChannelOperator(in: owner.curchannel)
        guard owner.effectiveUserRights.contains(.canBanUsers) || op else { return }
        guard let user = owner.users[userID] else { return }
        let channel = owner.curchannel.channelID.isValid ? owner.curchannel : nil

        Task { [weak owner] in
            guard let owner else { return }
            do {
                try await TeamTalkClient.shared.banUser(user, from: channel)
                try await TeamTalkClient.shared.kickUser(user, from: channel)
            } catch {
                await owner.presentError(error.localizedDescription)
            }
        }
    }

    func moveIntoChannel(channelID: TeamTalkChannelID) {
        guard let owner else { return }
        guard !moveusers.isEmpty else {
            announceForAccessibility(String(localized: "No users selected to move", comment: "channel list"))
            return
        }
        guard let destinationChannel = owner.channels[channelID] else { return }

        let selectedUsers = moveusers.compactMap { owner.users[$0] }
        moveusers.removeAll()
        owner.refreshChannelList()

        Task { [weak owner] in
            guard let owner else { return }
            var firstError: Error?

            for user in selectedUsers {
                do {
                    try await TeamTalkClient.shared.moveUser(user, to: destinationChannel)
                } catch {
                    if firstError == nil {
                        firstError = error
                    }
                }
            }

            if let firstError {
                await owner.presentError(firstError.localizedDescription)
            }
        }
    }

    func isMoveUserSelected(userID: TeamTalkUserID) -> Bool {
        moveusers.contains(userID)
    }

    func moveUserActionTitle(userID: TeamTalkUserID) -> String {
        if isMoveUserSelected(userID: userID) {
            return String(localized: "Deselect user", comment: "channel list")
        }
        return String(localized: "Move user", comment: "channel list")
    }

    func moveDestinationAccessibilityHint() -> String {
        switch moveusers.count {
        case 0:
            return String(localized: "No users selected to move", comment: "channel list")
        case 1:
            return String(localized: "1 user selected to move here", comment: "channel list")
        default:
            return String(
                format: String(localized: "%d users selected to move here", comment: "channel list"),
                moveusers.count
            )
        }
    }
}
