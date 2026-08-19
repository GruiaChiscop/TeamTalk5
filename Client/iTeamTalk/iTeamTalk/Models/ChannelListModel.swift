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

// MARK: - Navigation destination

enum ChannelListDestination: Hashable {
    case userDetail(UserDetailModel)
    case textMessage(TextMessageModel)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.userDetail(let a), .userDetail(let b)): return a === b
        case (.textMessage(let a), .textMessage(let b)): return a === b
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .userDetail(let m):  hasher.combine(0); hasher.combine(ObjectIdentifier(m))
        case .textMessage(let m): hasher.combine(1); hasher.combine(ObjectIdentifier(m))
        }
    }
}

// MARK: - Row model

// One node in the channel tree rendered by an OutlineGroup: a channel's
// `children` are its subchannels followed by the users in it, or `nil` (not
// an empty array) when there's nothing to show, so empty channels get no
// disclosure indicator. Users are always leaves.
struct ChannelTreeNode: Identifiable, Equatable {
    enum Kind: Equatable {
        case channel(TeamTalkChannel)
        case user(TeamTalkUser)
    }
    let kind: Kind
    let children: [ChannelTreeNode]?

    var id: String {
        switch kind {
        case .channel(let channel): return "channel-\(channel.channelID)"
        case .user(let user): return "user-\(user.userID)"
        }
    }
}

// Text messages received but not yet read (drives the blinking message icon).
var unreadmessages = Set<TeamTalkUserID>()

// MARK: - Channel List Model

@Observable
final class ChannelListModel {

    let session: TeamTalkSession

    // MARK: Published state for the channel list view
    var rootNodes: [ChannelTreeNode] = []
    var navigationTitle: String = ""

    // MARK: Split-out sub-controllers
    let moderation: ChannelModerationActions
    let pushToTalk: PushToTalkController

    // MARK: Published navigation state
    var navigationPath: [ChannelListDestination] = []
    var channelDetailModel: ChannelDetailModel?

    // MARK: Published alert state
    var showingJoinPasswordAlert = false
    var joinPassword = ""
    var errorMessage: String?

    var isPresentingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // MARK: Server / channel state
    var channels = [TeamTalkChannelID: TeamTalkChannel]()
    var chanpasswds = [TeamTalkChannelID: String]()
    var mychannel = TeamTalkChannel(Channel())
    var rejoinchannel: TeamTalkChannelConfiguration?
    var users = [TeamTalkUserID: TeamTalkUser]()
    var isProcessingCommand = false
    var srvprop = TeamTalkServerProperties(ServerProperties())
    var myuseraccount = TeamTalkUserAccount(UserAccount())

    // Admins implicitly hold every right, regardless of what the account grants.
    var effectiveUserRights: TeamTalkUserRights {
        myuseraccount.types.contains(.administrator) ? TeamTalkUserRights(rawValue: .max) : myuseraccount.rights
    }
    var textmessages = [TeamTalkUserID: [MyTextMessage]]()
    var unreadTimer: Timer?

    // MARK: Private state
    private var joiningChannel: TeamTalkChannel?
    @ObservationIgnored private weak var currentTextMessageModel: TextMessageModel?
    private var isRefreshScheduled = false
    // Indices rebuilt each refresh so lookups don't re-scan the full users/channels
    // dictionaries per row, per render (see updateDisplayItems / getUsersCount).
    private var usersByChannel = [TeamTalkChannelID: [TeamTalkUser]]()
    private var childrenByParent = [TeamTalkChannelID: [TeamTalkChannel]]()

    init(session: TeamTalkSession) {
        self.session = session
        moderation = ChannelModerationActions(session: session)
        pushToTalk = PushToTalkController(session: session)
        moderation.owner = self
        pushToTalk.owner = self
    }

    // MARK: Deinit
    deinit {
        for (_, user) in users {
            syncToUserCache(user: user)
        }
    }

    @MainActor
    func presentError(_ message: String) {
        errorMessage = message
    }

    // MARK: - Display helpers

    func updateDisplayItems() {
        usersByChannel.removeAll(keepingCapacity: true)
        for user in users.values {
            usersByChannel[user.channelIdentifier, default: []].append(user)
        }
        childrenByParent.removeAll(keepingCapacity: true)
        for channel in channels.values {
            childrenByParent[channel.parentChannelID, default: []].append(channel)
        }
    }

    private func channelSortComparator(_ lhs: TeamTalkChannel, _ rhs: TeamTalkChannel) -> Bool {
        guard Preferences.current.display.channelSortIndex == ChanSort.POPULARITY.rawValue else {
            return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        let au = usersByChannel[lhs.channelID]?.count ?? 0
        let bu = usersByChannel[rhs.channelID]?.count ?? 0
        return au == bu
            ? lhs.name.caseInsensitiveCompare(rhs.name) == .orderedAscending
            : au > bu
    }

    private func userSortComparator(_ lhs: TeamTalkUser, _ rhs: TeamTalkUser) -> Bool {
        getDisplayName(lhs).caseInsensitiveCompare(getDisplayName(rhs)) == .orderedAscending
    }

    private func buildNode(for channel: TeamTalkChannel) -> ChannelTreeNode {
        let subchannels = (childrenByParent[channel.channelID] ?? []).sorted(by: channelSortComparator)
        let channelUsers = (usersByChannel[channel.channelID] ?? []).sorted(by: userSortComparator)
        let children = channelUsers.map { ChannelTreeNode(kind: .user($0), children: nil) } + subchannels.map(buildNode)
        return ChannelTreeNode(kind: .channel(channel), children: children.isEmpty ? nil : children)
    }

    private func buildRootNodes() -> [ChannelTreeNode] {
        channels.values
            .filter { !$0.parentChannelID.isValid }
            .sorted(by: channelSortComparator)
            .map(buildNode)
    }

    func refreshChannelList() {
        moderation.moveusers = Set(moderation.moveusers.filter { users[$0] != nil })
        updateDisplayItems()
        let newRootNodes = buildRootNodes()
        if newRootNodes != rootNodes {
            rootNodes = newRootNodes
        }
    }

    // Coalesces bursts of high-frequency events (talk-state toggles, voice
    // activation) into a single refresh per runloop tick instead of one
    // full list rebuild per event.
    private func scheduleRefresh() {
        guard !isRefreshScheduled else { return }
        isRefreshScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isRefreshScheduled = false
            self.refreshChannelList()
        }
    }

    func updateTitle() {
        navigationTitle = srvprop.name
    }

    // MARK: - User / channel detail providers

    func userDetails(_ user: TeamTalkUser) -> ChannelUserDetails {
        let female = user.statusMode.contains(.female)
        let isTalking = user.states.contains(.voice) ||
            (session.myUserIdentifier == user.userID && session.isVoiceTransmitting)
        let iconName = isTalking
            ? (female ? "woman_green.png" : "man_green.png")
            : (female ? "woman_blue.png" : "man_blue.png")
        let iconAccessibilityLabel = isTalking
            ? String(localized: "Talking", comment: "channel list")
            : String(localized: "Silent", comment: "channel list")
        let messageIcon = unreadmessages.contains(user.userID) && Int(Date().timeIntervalSince1970) % 2 == 0
            ? "message_red"
            : "message_blue"
        return ChannelUserDetails(
            title: getDisplayName(user),
            subtitle: user.statusMessage,
            iconName: iconName,
            iconAccessibilityLabel: iconAccessibilityLabel,
            messageIconName: messageIcon
        )
    }

    func channelDetails(_ channel: TeamTalkChannel) -> ChannelDisplayDetails {
        let op = session.isChannelOperator(in: channel)
        let canEdit = effectiveUserRights.contains(.canModifyChannels) || op
        let actionTitle = canEdit
            ? String(localized: "Edit", comment: "channel list")
            : String(localized: "View", comment: "channel list")

        let iconName = channel.isPasswordProtected ? "channel_pink.png" : "channel_orange.png"
        let iconLabel = channel.isPasswordProtected
            ? String(localized: "Password protected", comment: "channel list")
            : String(localized: "No password", comment: "channel list")

        // The root channel's own name is typically empty - show the server's
        // display name there instead.
        let displayName = channel.parentChannelID.isValid ? channel.name : srvprop.name
        let hasChildren = !(childrenByParent[channel.channelID] ?? []).isEmpty
        let directCount = usersByChannel[channel.channelID]?.count ?? 0
        let totalCount = getUsersCount(channel.channelID)
        // Channels with subchannels show direct/total ("MyServer: 0/7") since the
        // two counts can differ; leaves only ever have one meaningful count.
        let title = hasChildren
            ? "\(displayName): \(directCount)/\(totalCount)"
            : "\(displayName) (\(totalCount))"

        return ChannelDisplayDetails(
            title: title,
            subtitle: channel.topic,
            iconName: iconName,
            iconAccessibilityLabel: iconLabel,
            actionTitle: actionTitle
        )
    }

    func getUsersCount(_ channelID: TeamTalkChannelID) -> Int {
        var count = usersByChannel[channelID]?.count ?? 0
        for channel in childrenByParent[channelID] ?? [] {
            count += getUsersCount(channel.channelID)
        }
        return count
    }

    // MARK: - Channel joining

    func joinNewChannel(_ channel: TeamTalkChannel) {
        if channel.isPasswordProtected {
            joiningChannel = channel
            //joinPassword = channel.password
            showingJoinPasswordAlert = true
        } else {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.session.joinChannel(channel)
                } catch {
                    await self.presentError(error.localizedDescription)
                }
            }
        }
    }

    func confirmJoinWithPassword() {
        guard let channel = joiningChannel else { return }
        chanpasswds[channel.channelID] = joinPassword
        let password = joinPassword
        joiningChannel = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.session.joinChannel(channel, password: password)
            } catch {
                await self.presentError(error.localizedDescription)
            }
        }
    }

    // MARK: - Navigation

    func showUserDetail(_ user: TeamTalkUser) {
        let model = UserDetailModel(user: user, session: session)
        navigationPath.append(.userDetail(model))
    }

    func showChannelDetail(_ channel: TeamTalkChannel) {
        var rawChannel = channel.cValue
        if TeamTalkString.channel(.password, from: rawChannel).isEmpty {
            if let password = chanpasswds[channel.channelID] {
                TeamTalkString.setChannel(.password, on: &rawChannel, to: password)
            }
        }
        let model = ChannelDetailModel(channel: TeamTalkChannel(rawChannel), session: session)
        channelDetailModel = model
    }

    func showNewChannel() {
        var newChannel = Channel()
        newChannel.nParentID = mychannel.channelID.cValue
        if newChannel.nParentID == 0 {
            let subchans = channels.values.filter { !$0.parentChannelID.isValid }
            if let root = subchans.first {
                newChannel.nParentID = root.channelID.cValue
            }
        }
        let model = ChannelDetailModel(channel: TeamTalkChannel(newChannel), session: session)
        channelDetailModel = model
    }

    func showTextMessages(user: TeamTalkUser) {
        let model = makeTextMessageModel(for: user)
        currentTextMessageModel = model
        navigationPath.append(.textMessage(model))
    }

    private func makeTextMessageModel(for user: TeamTalkUser) -> TextMessageModel {
        let model = TextMessageModel(
            target: .directMessage(user),
            title: String(localized: "Private Text Message", comment: "text message navigation title"),
            session: session
        )
        openTextMessages(model)
        return model
    }

    func openTextMessages(_ model: TextMessageModel) {
        model.delegate = self
        addToTeamTalkEvents(model, on: session)
        if let user = model.privateUser, let msgs = textmessages[user.userID] {
            for m in msgs { model.appendEventMessage(m) }
        }
    }

    func timerUnreadBlinker() {
        scheduleRefresh()
        if unreadmessages.isEmpty {
            unreadTimer?.invalidate()
        }
    }

    // MARK: - Login follow-up

    func configureInitialJoin(channelPath: String, password: String) {
        rejoinchannel = nil

        guard !channelPath.isEmpty else { return }

        let channelID = session.channelIdentifier(from: TeamTalkChannelPath(channelPath))
        if channelID.isValid {
            rejoinchannel = TeamTalkChannelConfiguration(
                channelID: channelID,
                parentChannelID: .none,
                name: "",
                password: password
            )
            return
        }

        var tokens = channelPath.components(separatedBy: "/")
        guard !tokens.isEmpty else { return }

        let channelName = tokens.removeLast()
        let channelPath = tokens.map { "/" + $0 }.joined()
        let parentID = session.channelIdentifier(from: TeamTalkChannelPath(channelPath))

        guard parentID.isValid else { return }

        rejoinchannel = TeamTalkChannelConfiguration(
            parentChannelID: parentID,
            name: channelName,
            password: password
        )
    }

    @MainActor
    func joinInitialChannelIfNeeded() async throws {
        guard session.isAuthorized else {
            refreshChannelList()
            return
        }

        if let rejoinchannel {
            if rejoinchannel.id > 0 {
                let channelID = TeamTalkChannelID(rejoinchannel.id)
                let password = chanpasswds[channelID] ?? rejoinchannel.password
                if chanpasswds[channelID] == nil {
                    chanpasswds[channelID] = password
                }
                if let channel = session.channel(id: channelID) {
                    try await session.joinChannel(channel, password: password)
                }
            } else if !rejoinchannel.name.isEmpty {
                try await session.joinChannel(rejoinchannel)
            }
        } else if Preferences.current.connection.joinRootChannel {
            if let rootChannel = session.channel(id: TeamTalkChannelID(session.rootChannelID)) {
                try await session.joinChannel(rootChannel)
            }
        }

        refreshChannelList()
    }

    // MARK: - Audio config

    func updateAudioConfig() {
        if mychannel.rawValue.audiocfg.bEnableAGC == TRUE {
            session.setSoundInputGainLevel(INT32(SOUND_GAIN_DEFAULT.rawValue))
            var ap = TeamTalkAudioPreprocessor.makeWebRTCPreprocessor()
            let gain = Float(mychannel.rawValue.audiocfg.nGainLevel) / Float(TeamTalkAudioPreprocessor.channelAudioConfigMax)
            ap.webrtc.gaincontroller2.fixeddigital.fGainDB = WEBRTC_GAINCONTROLLER2_FIXEDGAIN_MAX * gain
            ap.webrtc.gaincontroller2.bEnable = TRUE
            session.setSoundInputPreprocess(&ap)
        } else {
            var ap = TeamTalkAudioPreprocessor.makeTeamTalkPreprocessor()
            session.setSoundInputPreprocess(&ap)
            // Preferences.sound.microphoneGainPercent reflects the SDK's *live* volume
            // (for the Preferences screen), not the persisted value being re-applied here.
            let vol = UserDefaults.standard.integer(forKey: PREF_MICROPHONE_GAIN)
            session.setSoundInputGainLevel(INT32(refVolume(Double(vol))))
        }
    }
}

// MARK: - MyTextMessageDelegate

extension ChannelListModel: MyTextMessageDelegate {
    func appendTextMessage(for userID: TeamTalkUserID, message: MyTextMessage) {
        if textmessages[userID] == nil {
            textmessages[userID] = [MyTextMessage]()
        }
        textmessages[userID]!.append(message)
        if textmessages[userID]!.count > MAX_TEXTMESSAGES {
            textmessages[userID]!.removeFirst()
        }
    }
}

// MARK: - TeamTalkEvent

extension ChannelListModel: TeamTalkEventObserver {
    func handleTeamTalkEvent(_ event: TeamTalkEvent) {
        switch event.kind {

        case .connectionLost:
            channels.removeAll()
            users.removeAll()
            mychannel = TeamTalkChannel(Channel())
            rejoinchannel = nil
            refreshChannelList()

        case .commandProcessing(_, let isActive):
            isProcessingCommand = isActive

        case .serverUpdated(let properties):
            srvprop = properties

        case .myselfLoggedIn(_, let account):
            myuseraccount = account

        case .channelCreated(let channel):
            channels[channel.channelID] = channel
            if !channel.parentChannelID.isValid { updateTitle() }
            if !isProcessingCommand { refreshChannelList() }

        case .channelUpdated(let channel):
            channels[channel.channelID] = channel
            if mychannel.channelID == channel.channelID {
                let myUserID = session.myUserIdentifier
                if channel.transmitUsersQueue.first == myUserID && mychannel.transmitUsersQueue.first != myUserID {
                    playSound(.transmit_ON)
                }
                if mychannel.transmitUsersQueue.first == myUserID && channel.transmitUsersQueue.first != myUserID {
                    playSound(.transmit_OFF)
                }
                mychannel = channel
                updateAudioConfig()
            }
            if !isProcessingCommand { refreshChannelList() }

        case .channelRemoved(let channel):
            channels.removeValue(forKey: channel.channelID)
            if !isProcessingCommand { refreshChannelList() }

        case .userLoggedIn(let user):
            playSound(.logged_IN)
            users[user.userID] = user
            if !isProcessingCommand {
                refreshChannelList()
                if session.myUserIdentifier != user.userID {
                    if Preferences.current.textToSpeechEvents.userLoggedIn {
                        newUtterance(getDisplayName(user) + " " + String(localized: "has logged on", comment: "TTS EVENT"))
                    }
                }
            }

        case .userLoggedOut(let user):
            playSound(.logged_OUT)
            users.removeValue(forKey: user.userID)
            if !isProcessingCommand {
                refreshChannelList()
                if session.myUserIdentifier != user.userID {
                    if Preferences.current.textToSpeechEvents.userLoggedOut {
                        newUtterance(getDisplayName(user) + " " + String(localized: "has logged out", comment: "TTS EVENT"))
                    }
                }
            }

        case .userJoined(let user):
            users[user.userID] = user
            if user.userID == session.myUserIdentifier, let joinedChannel = channels[user.channelIdentifier] {
                mychannel = joinedChannel
                if rejoinchannel?.id == 0 && chanpasswds[user.channelIdentifier] == nil {
                    chanpasswds[user.channelIdentifier] = rejoinchannel?.password ?? ""
                }
                rejoinchannel = TeamTalkChannelConfiguration(joinedChannel)
                updateTitle()
                updateAudioConfig()
                pushToTalk.resumeIfWasLocked()
            }
            if user.channelIdentifier == mychannel.channelID && mychannel.channelID.isValid {
                playSound(.joined_CHAN)
                if Preferences.current.textToSpeechEvents.userJoinedChannel {
                    newUtterance(getDisplayName(user) + " " + String(localized: "has joined the channel", comment: "TTS EVENT"))
                }
            }
            if !isProcessingCommand { refreshChannelList() }

        case .userUpdated(let user):
            users[user.userID] = user
            if !isProcessingCommand { refreshChannelList() }

        case .userLeft(let previousChannelID, let user):
            if !effectiveUserRights.contains(.canViewAllUsers) {
                users.removeValue(forKey: user.userID)
            } else {
                users[user.userID] = user
            }
            if user.userID == session.myUserIdentifier {
                mychannel = TeamTalkChannel(Channel())
                rejoinchannel = nil
            }
            if previousChannelID == mychannel.channelID && mychannel.channelID.isValid {
                playSound(.left_CHAN)
                if Preferences.current.textToSpeechEvents.userLeftChannel {
                    newUtterance(getDisplayName(user) + " " + String(localized: "has left the channel", comment: "TTS EVENT"))
                }
            }
            if !isProcessingCommand { refreshChannelList() }

        case .textMessage(let message):
            if message.type == .user {
                let fromUserID = message.fromUserIdentifier
                if let user = users[fromUserID] {
                    let name = getDisplayName(user)
                    let newmsg = MyTextMessage(
                        m: message.rawValue,
                        nickname: name,
                        msgtype: session.myUserIdentifier == message.fromUserIdentifier ? .PRIV_IM_MYSELF : .PRIV_IM
                    )
                    appendTextMessage(for: message.fromUserIdentifier, message: newmsg)
                    if unreadmessages.isEmpty {
                        unreadTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                            self?.timerUnreadBlinker()
                        }
                    }
                    unreadmessages.insert(message.fromUserIdentifier)
                }

                // Don't auto-navigate if the private chat for this user is already visible
                if currentTextMessageModel?.isShowingConversation(with: message.fromUserIdentifier) == true {
                    break
                }

                if let user = users[fromUserID],
                   Preferences.current.display.popupTextMessages {
                    let model = makeTextMessageModel(for: user)
                    currentTextMessageModel = model
                    navigationPath.append(.textMessage(model))
                    if let msg = model.lastMessage() {
                        speakTextMessage(message.type.cValue, mymsg: msg)
                    }
                }
            }

        case .userStateChanged(let user):
            users[user.userID] = user
            scheduleRefresh()

        case .voiceActivation:
            scheduleRefresh()

        default:
            break
        }
    }
}
