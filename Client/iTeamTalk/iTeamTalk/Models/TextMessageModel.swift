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

enum TextMessageTarget {
    case channelFeed
    case directMessage(TeamTalkUser)

    var privateUser: TeamTalkUser? {
        if case .directMessage(let user) = self {
            return user
        }
        return nil
    }

    var showLogMessages: Bool {
        self == .channelFeed
    }

    func matches(_ message: TeamTalkTextMessage) -> Bool {
        switch self {
        case .channelFeed:
            return message.type == .channel || message.type == .broadcast
        case .directMessage(let user):
            return message.type == .user && message.fromUserIdentifier == user.userID
        }
    }
}

extension TextMessageTarget: Equatable {
    static func == (lhs: TextMessageTarget, rhs: TextMessageTarget) -> Bool {
        switch (lhs, rhs) {
        case (.channelFeed, .channelFeed):
            return true
        case (.directMessage(let leftUser), .directMessage(let rightUser)):
            return leftUser.userID == rightUser.userID
        default:
            return false
        }
    }
}

final class TextMessageModel: ObservableObject {
    let target: TextMessageTarget
    let title: String
    weak var delegate: MyTextMessageDelegate?

    @Published private(set) var sections: [TextMessageSection] = []
    @Published var composedText = ""

    private var messageAssembler = TeamTalkTextMessageAssembler()

    init(target: TextMessageTarget, title: String) {
        self.target = target
        self.title = title
    }

    deinit {
        removeFromTeamTalkEvents(self)
    }

    var showLogMessages: Bool { target.showLogMessages }

    var privateUser: TeamTalkUser? {
        target.privateUser
    }

    func isShowingConversation(with userID: TeamTalkUserID) -> Bool {
        privateUser?.userID == userID
    }

    func appendEventMessage(_ message: MyTextMessage) {
        if shouldStartNewSection(for: message) {
            sections.append(TextMessageSection(title: sectionTitle(for: message), messages: [message]))
        } else {
            sections[sections.count - 1].messages.append(message)
        }
        trimMessagesIfNeeded()
    }

    func clearUnreadMessages() {
        guard let privateUser else { return }
        unreadmessages.remove(privateUser.userID)
    }

    func sendMessage() {
        let content = composedText
        guard !content.isEmpty else { return }

        if let privateUser {
            let myID = TeamTalkClient.shared.myUserIdentifier
            let mymsg = MyTextMessage(
                fromUserID: myID,
                nickname: myDisplayName,
                msgtype: .PRIV_IM_MYSELF,
                content: content
            )
            appendEventMessage(mymsg)
            delegate?.appendTextMessage(for: privateUser.userID, message: mymsg)
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                switch self.target {
                case .channelFeed:
                    try await TeamTalkClient.shared.sendChannelMessage(content)
                case .directMessage(let user):
                    try await TeamTalkClient.shared.sendTextMessage(to: user, content: content)
                }
                await self.clearComposer()
            } catch {
                let text = String(
                    format: String(localized: "Command failed: %@", comment: "log entry"),
                    error.localizedDescription
                )
                await self.appendCommandError(text)
            }
        }
    }

    @MainActor
    private func clearComposer() {
        composedText = ""
    }

    @MainActor
    private func appendCommandError(_ message: String) {
        appendEventMessage(MyTextMessage(logmsg: message))
    }

    func lastMessage() -> MyTextMessage? {
        sections.last?.messages.last
    }
    

    private func shouldStartNewSection(for message: MyTextMessage) -> Bool {
        guard let last = sections.last?.messages.last else { return true }
        return last.fromUserID != message.fromUserID
            || last.nickname != message.nickname
            || last.msgtype != message.msgtype
    }

    private func trimMessagesIfNeeded() {
        var totalCount = sections.reduce(0) { $0 + $1.messages.count }
        while totalCount > MAX_TEXTMESSAGES, !sections.isEmpty {
            sections[0].messages.removeFirst()
            totalCount -= 1
            if sections[0].messages.isEmpty {
                sections.removeFirst()
            }
        }
    }

    private func sectionTitle(for message: MyTextMessage) -> String {
        switch message.msgtype {
        case .PRIV_IM, .PRIV_IM_MYSELF, .CHAN_IM, .CHAN_IM_MYSELF, .BCAST:
            return message.nickname
        case .LOGMSG:
            return String(localized: "Status Event", comment: "Text message view")
        }
    }

    private var myDisplayName: String {
        let me = TeamTalkClient.shared.currentUser() ?? TeamTalkUser(User())
        return getDisplayName(me)
    }

    private func displayName(forSender userID: TeamTalkUserID) -> String {
        let user = TeamTalkClient.shared.user(id: userID) ?? privateUser ?? TeamTalkUser(User())
        return getDisplayName(user)
    }
}

extension TextMessageModel: TeamTalkEventObserver {
    func handleTeamTalkEvent(_ event: TeamTalkEvent) {
        switch event.kind {
        case .textMessage(let txtmsg):
            handleIncomingTextMessage(txtmsg)
        case .userLoggedIn(let user):
            handleMyselfLoggedIn(user)
        case .userJoined(let user):
            handleUserJoined(user)
        case .userLeft(let previousChannelID, let user):
            handleUserLeft(previousChannel: previousChannelID, user: user)
        case .commandError(_, let error):
            handleCommandError(error)
        default:
            break
        }
    }

    private func handleIncomingTextMessage(_ txtmsg: TeamTalkTextMessage) {
        guard target.matches(txtmsg),
              let content = messageAssembler.append(txtmsg) else { return }

        let mymsg = MyTextMessage(
            fromUserID: txtmsg.fromUserIdentifier,
            nickname: displayName(forSender: txtmsg.fromUserIdentifier),
            msgtype: msgType(for: txtmsg),
            content: content
        )
        appendEventMessage(mymsg)
        speakTextMessage(txtmsg.type.cValue, mymsg: mymsg)
    }

    private func msgType(for txtmsg: TeamTalkTextMessage) -> MsgType {
        let isFromMyself = TeamTalkClient.shared.myUserIdentifier == txtmsg.fromUserIdentifier
        switch txtmsg.type {
        case .user:
            return isFromMyself ? .PRIV_IM_MYSELF : .PRIV_IM
        case .channel:
            return isFromMyself ? .CHAN_IM_MYSELF : .CHAN_IM
        case .broadcast:
            return .BCAST
        default:
            return .PRIV_IM
        }
    }

    private func handleMyselfLoggedIn(_ user: TeamTalkUser) {
        guard showLogMessages, TeamTalkClient.shared.myUserIdentifier == user.userID else { return }
        appendEventMessage(MyTextMessage(logmsg: String(localized: "Logged on to server", comment: "log entry")))
    }

    private func handleUserJoined(_ user: TeamTalkUser) {
        guard showLogMessages, TeamTalkClient.shared.myChannelIdentifier == user.channelIdentifier else { return }

        let logmsg: MyTextMessage
        if TeamTalkClient.shared.myUserIdentifier == user.userID {
            let channelName = joinedChannelName(for: user.channelIdentifier)
            let txt = String(format: String(localized: "Joined %@", comment: "log entry"), channelName)
            logmsg = MyTextMessage(logmsg: txt)
        } else {
            let txt = String(format: String(localized: "%@ joined channel", comment: "log entry"), getDisplayName(user))
            logmsg = MyTextMessage(logmsg: txt)
        }
        appendEventMessage(logmsg)
    }

    private func joinedChannelName(for channelID: TeamTalkChannelID) -> String {
        let rootName = String(localized: "root channel", comment: "log entry")
        guard let channel = TeamTalkClient.shared.channel(id: channelID),
              channel.parentChannelID.isValid else {
            return rootName
        }
        return channel.name
    }

    private func handleUserLeft(previousChannel: TeamTalkChannelID, user: TeamTalkUser) {
        guard showLogMessages, TeamTalkClient.shared.myChannelIdentifier == previousChannel else { return }
        let txt = String(format: String(localized: "%@ left channel", comment: "log entry"), getDisplayName(user))
        appendEventMessage(MyTextMessage(logmsg: txt))
    }

    private func handleCommandError(_ error: TeamTalkClientError) {
        let txt = String(format: String(localized: "Command failed: %@", comment: "log entry"), error.message)
        appendEventMessage(MyTextMessage(logmsg: txt))
    }
}

struct TextMessageSection: Identifiable {
    let id = UUID()
    let title: String
    var messages: [MyTextMessage]
}
