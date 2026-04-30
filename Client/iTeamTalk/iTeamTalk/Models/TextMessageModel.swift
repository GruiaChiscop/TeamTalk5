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

    @Published var sections = [TextMessageSection]()
    @Published var composedText = ""

    private var messages = [Int: [MyTextMessage]]()
    private var curMessageSection = 0
    private var messageAssembler = TeamTalkTextMessageAssembler()

    init(target: TextMessageTarget, title: String) {
        self.target = target
        self.title = title
    }

    deinit {
        removeFromTeamTalkEvents(self)
    }

    @MainActor
    private func clearComposer() {
        composedText = ""
    }

    @MainActor
    private func appendCommandError(_ message: String) {
        appendEventMessage(MyTextMessage(logmsg: message))
    }

    var showLogMessages: Bool { target.showLogMessages }

    var privateUser: TeamTalkUser? {
        target.privateUser
    }

    func isShowingConversation(with userID: TeamTalkUserID) -> Bool {
        privateUser?.userID == userID
    }

    func appendEventMessage(_ message: MyTextMessage) {
        if messages[curMessageSection] == nil ||
            messages[curMessageSection]?.last?.fromUserID != message.fromUserID ||
            messages[curMessageSection]?.last?.nickname != message.nickname ||
            messages[curMessageSection]?.last?.msgtype != message.msgtype {
            curMessageSection += 1
            messages[curMessageSection] = [MyTextMessage]()
        }
        messages[curMessageSection]?.append(message)

        trimMessagesIfNeeded()
        updateMessages()
    }

    func getLastEventMessage() -> MyTextMessage? {
        messages[curMessageSection]?.last
    }

    func clearUnreadMessages() {
        guard let privateUser else { return }
        unreadmessages.remove(privateUser.userID)
    }

    func sendMessage() {
        let content = composedText
        guard !content.isEmpty else { return }

        if let privateUser {
            let currentUser = TeamTalkClient.shared.currentUser() ?? TeamTalkUser(User())
            let name = getDisplayName(currentUser)
            let mymsg = MyTextMessage(
                fromUserID: TeamTalkClient.shared.myUserIdentifier,
                nickname: name,
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

    private func updateMessages() {
        let updatedSections = messages.keys.sorted().compactMap { key -> TextMessageSection? in
            guard let values = messages[key], let first = values.first else { return nil }
            return TextMessageSection(title: sectionTitle(for: first), messages: values)
        }
        sections = updatedSections
    }

    private func trimMessagesIfNeeded() {
        while messageCount > MAX_TEXTMESSAGES, let key = messages.keys.sorted().first {
            messages[key]?.removeFirst()
            if messages[key]?.isEmpty != false {
                messages.removeValue(forKey: key)
            }
        }
    }

    private var messageCount: Int {
        messages.values.reduce(0) { $0 + $1.count }
    }

    private func sectionTitle(for message: MyTextMessage) -> String {
        switch message.msgtype {
        case .PRIV_IM, .PRIV_IM_MYSELF, .CHAN_IM, .CHAN_IM_MYSELF, .BCAST:
            return message.nickname
        case .LOGMSG:
            return String(localized: "Status Event", comment: "Text message view")
        }
    }
}

extension TextMessageModel: TeamTalkEventObserver {
    func handleTeamTalkEvent(_ event: TeamTalkEvent) {
        switch event.kind {
        case .textMessage(let txtmsg):
            if target.matches(txtmsg) {
                if let content = messageAssembler.append(txtmsg) {
                    let user = TeamTalkClient.shared.user(id: txtmsg.fromUserIdentifier) ?? privateUser ?? TeamTalkUser(User())
                    var msgtype = MsgType.PRIV_IM
                    switch txtmsg.type {
                    case .user:
                        msgtype = TeamTalkClient.shared.myUserIdentifier == txtmsg.fromUserIdentifier ? .PRIV_IM_MYSELF : .PRIV_IM
                    case .channel:
                        msgtype = TeamTalkClient.shared.myUserIdentifier == txtmsg.fromUserIdentifier ? .CHAN_IM_MYSELF : .CHAN_IM
                    case .broadcast:
                        msgtype = .BCAST
                    default:
                        break
                    }
                    let name = getDisplayName(user)
                    let mymsg = MyTextMessage(fromUserID: txtmsg.fromUserIdentifier, nickname: name, msgtype: msgtype, content: content)
                    appendEventMessage(mymsg)
                    speakTextMessage(txtmsg.type.cValue, mymsg: mymsg)
                }
            }

        case .userLoggedIn(let user):
            if showLogMessages && TeamTalkClient.shared.myUserIdentifier == user.userID {
                appendEventMessage(MyTextMessage(logmsg: String(localized: "Logged on to server", comment: "log entry")))
            }

        case .userJoined(let user):
            if showLogMessages && TeamTalkClient.shared.myChannelIdentifier == user.channelIdentifier {
                let logmsg: MyTextMessage
                if TeamTalkClient.shared.myUserIdentifier == user.userID {
                    let channame = TeamTalkClient.shared.channel(id: user.channelIdentifier).map { channel in
                        if !channel.parentChannelID.isValid {
                            return String(localized: "root channel", comment: "log entry")
                        }
                        return channel.name
                    } ?? String(localized: "root channel", comment: "log entry")
                    let txt = String(format: String(localized: "Joined %@", comment: "log entry"), channame)
                    logmsg = MyTextMessage(logmsg: txt)
                } else {
                    let name = getDisplayName(user)
                    let txt = String(format: String(localized: "%@ joined channel", comment: "log entry"), name)
                    logmsg = MyTextMessage(logmsg: txt)
                }
                appendEventMessage(logmsg)
            }

        case .userLeft(let previousChannelID, let user):
            if showLogMessages && TeamTalkClient.shared.myChannelIdentifier == previousChannelID {
                let name = getDisplayName(user)
                let txt = String(format: String(localized: "%@ left channel", comment: "log entry"), name)
                appendEventMessage(MyTextMessage(logmsg: txt))
            }

        case .commandError(_, let error):
            let txt = String(format: String(localized: "Command failed: %@", comment: "log entry"), error.message)
            appendEventMessage(MyTextMessage(logmsg: txt))

        default:
            break
        }
    }
}

struct TextMessageSection: Identifiable {
    let id = UUID()
    let title: String
    let messages: [MyTextMessage]
}
