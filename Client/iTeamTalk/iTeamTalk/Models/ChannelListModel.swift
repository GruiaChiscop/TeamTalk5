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

enum ChannelListRow: Identifiable {
    case join
    case user(TeamTalkUser)
    case channel(TeamTalkChannel)

    var id: String {
        switch self {
        case .join: return "join"
        case .user(let user): return "user-\(user.userID)"
        case .channel(let channel): return "channel-\(channel.channelID)"
        }
    }
}

// MARK: - Channel List Model

final class ChannelListModel: ObservableObject {

    // MARK: Published state for the channel list view
    @Published var rows: [ChannelListRow] = []
    @Published var isTransmitting: Bool = false
    @Published var pttHint: String = String(localized: "Toggle to enable/disable transmission", comment: "channel list")
    @Published var navigationTitle: String = ""

    // MARK: Published navigation state
    @Published var navigationPath: [ChannelListDestination] = []
    @Published var channelDetailModel: ChannelDetailModel?

    // MARK: Published alert state
    @Published var showingJoinPasswordAlert = false
    @Published var joinPassword = ""
    @Published var errorMessage: String?

    // MARK: Server / channel state
    var channels = [TeamTalkChannelID: TeamTalkChannel]()
    var chanpasswds = [TeamTalkChannelID: String]()
    var curchannel = TeamTalkChannel(Channel())
    var mychannel = TeamTalkChannel(Channel())
    var rejoinchannel: TeamTalkChannelConfiguration?
    var users = [TeamTalkUserID: TeamTalkUser]()
    var moveusers = Set<TeamTalkUserID>()
    var isProcessingCommand = false
    var srvprop = ServerProperties()
    var myuseraccount = UserAccount()
    var textmessages = [TeamTalkUserID: [MyTextMessage]]()
    var unreadTimer: Timer?
    var displayUsers = [TeamTalkUser]()
    var displayChans = [TeamTalkChannel]()
    var pttLockTimeout = Date()

    // MARK: Private state
    private var joiningChannel: TeamTalkChannel?
    private weak var currentTextMessageModel: TextMessageModel?

    // MARK: Deinit
    deinit {
        for (_, user) in users {
            syncToUserCache(user: user)
        }
    }

    @MainActor
    private func presentError(_ message: String) {
        errorMessage = message
    }

    // MARK: - Display helpers

    func updateDisplayItems() {
        let subchans: [TeamTalkChannel] = channels.values.filter { $0.parentChannelID == curchannel.channelID }
        let chanusers: [TeamTalkUser] = users.values.filter { $0.channelIdentifier == curchannel.channelID }

        let settings = UserDefaults.standard
        let chansort = settings.object(forKey: PREF_DISPLAY_SORTCHANNELS) == nil
            ? ChanSort.ASCENDING.rawValue
            : settings.integer(forKey: PREF_DISPLAY_SORTCHANNELS)

        switch chansort {
        case ChanSort.POPULARITY.rawValue:
            displayChans = subchans.sorted { lhs, rhs in
                let au = users.values.filter { $0.channelIdentifier == lhs.channelID }
                let bu = users.values.filter { $0.channelIdentifier == rhs.channelID }
                let aname = lhs.name
                let bname = rhs.name
                return au.count == bu.count
                    ? aname.caseInsensitiveCompare(bname) == .orderedAscending
                    : au.count > bu.count
            }
        default:
            displayChans = subchans.sorted {
                let aname = $0.name
                let bname = $1.name
                return aname.caseInsensitiveCompare(bname) == .orderedAscending
            }
        }
        displayUsers = chanusers.sorted {
            getDisplayName($0.rawValue).caseInsensitiveCompare(getDisplayName($1.rawValue)) == .orderedAscending
        }
    }

    func refreshChannelList() {
        moveusers = Set(moveusers.filter { users[$0] != nil })
        updateDisplayItems()
        rows = displayRows()
    }

    private func displayRows() -> [ChannelListRow] {
        let showJoin = curchannel.channelID != mychannel.channelID && curchannel.channelID.isValid
        var result = [ChannelListRow]()
        if showJoin { result.append(.join) }
        for user in displayUsers { result.append(.user(user)) }
        if curchannel.parentChannelID.isValid, let parent = channels[curchannel.parentChannelID] {
            result.append(.channel(parent))
        }
        for channel in displayChans { result.append(.channel(channel)) }
        return result
    }

    func updateTitle() {
        if !curchannel.parentChannelID.isValid {
            navigationTitle = TeamTalkString.serverProperties(.name, from: srvprop)
        } else {
            navigationTitle = curchannel.name
        }
    }

    // MARK: - User / channel detail providers

    func userDetails(_ user: TeamTalkUser) -> ChannelUserDetails {
        let female = (UInt(user.rawValue.nStatusMode) & StatusMode.STATUSMODE_FEMALE.rawValue) != 0
        let isTalking = user.states.contains(.voice) ||
            (TeamTalkClient.shared.myUserIdentifier == user.userID && TeamTalkClient.shared.isVoiceTransmitting)
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
            title: getDisplayName(user.rawValue),
            subtitle: user.statusMessage,
            iconName: iconName,
            iconAccessibilityLabel: iconAccessibilityLabel,
            messageIconName: messageIcon
        )
    }

    func channelDetails(_ channel: TeamTalkChannel) -> ChannelDisplayDetails {
        let op = TeamTalkClient.shared.isChannelOperator(in: channel)
        let canEdit = (myuseraccount.uUserRights & USERRIGHT_MODIFY_CHANNELS.rawValue) != 0 || op
        let actionTitle = canEdit
            ? String(localized: "Edit", comment: "channel list")
            : String(localized: "View", comment: "channel list")

        if !curchannel.channelID.isValid {
            let iconName = channel.isPasswordProtected ? "channel_pink.png" : "channel_orange.png"
            let iconLabel = channel.isPasswordProtected
                ? String(localized: "Password protected", comment: "channel list")
                : String(localized: "No password", comment: "channel list")
            return ChannelDisplayDetails(
                title: TeamTalkString.serverProperties(.name, from: srvprop),
                subtitle: channel.topic,
                iconName: iconName,
                iconAccessibilityLabel: iconLabel,
                actionTitle: actionTitle,
                isParent: false
            )
        }

        if channel.channelID == curchannel.parentChannelID {
            let subtitle = !channel.parentChannelID.isValid
                ? TeamTalkString.serverProperties(.name, from: srvprop)
                : channel.name
            return ChannelDisplayDetails(
                title: String(localized: "Parent channel", comment: "channel list"),
                subtitle: subtitle,
                iconName: "back_orange.png",
                iconAccessibilityLabel: String(localized: "Return to previous channel", comment: "channel list"),
                actionTitle: actionTitle,
                isParent: true
            )
        }

        let userCount = getUsersCount(channel.channelID)
        let iconName = channel.isPasswordProtected ? "channel_pink.png" : "channel_orange.png"
        let iconLabel = String(format: String(localized: "Channel. %d users", comment: "channel list"), userCount)
        return ChannelDisplayDetails(
            title: channel.name + " (\(userCount))",
            subtitle: channel.topic,
            iconName: iconName,
            iconAccessibilityLabel: iconLabel,
            actionTitle: actionTitle,
            isParent: false
        )
    }

    func getUsersCount(_ channelID: TeamTalkChannelID) -> Int {
        var count = users.values.filter { $0.channelIdentifier == channelID }.count
        for channel in channels.values.filter({ $0.parentChannelID == channelID }) {
            count += getUsersCount(channel.channelID)
        }
        return count
    }

    // MARK: - Row selection

    func selectRow(_ row: ChannelListRow) {
        switch row {
        case .join:
            joinCurrentChannel()
        case .user(let user):
            showUserDetail(user)
        case .channel(let channel):
            curchannel = channel
            refreshChannelList()
            updateTitle()
        }
    }

    func joinCurrentChannel() {
        joinNewChannel(curchannel)
    }

    // MARK: - Channel joining

    func joinNewChannel(_ channel: TeamTalkChannel) {
        if channel.isPasswordProtected {
            joiningChannel = channel
            joinPassword = channel.password
            showingJoinPasswordAlert = true
        } else {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await TeamTalkClient.shared.joinChannel(channel)
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
                try await TeamTalkClient.shared.joinChannel(channel, password: password)
            } catch {
                await self.presentError(error.localizedDescription)
            }
        }
    }

    func joinChannelFromAccessibility(channelID: TeamTalkChannelID) {
        if let channel = channels[channelID] {
            joinNewChannel(channel)
        }
    }

    // MARK: - Accessibility actions

    func muteUser(userID: TeamTalkUserID) {
        guard let user = users[userID] else { return }
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
        guard let user = users[userID] else { return }

        let isSelected = moveusers.contains(userID)
        if isSelected {
            moveusers.remove(userID)
        } else {
            moveusers.insert(userID)
        }

        refreshChannelList()
        announceForAccessibility(
            String(
                format: isSelected
                    ? String(localized: "%@ deselected", comment: "channel list")
                    : String(localized: "%@ selected", comment: "channel list"),
                getDisplayName(user.rawValue)
            )
        )
    }

    func kickUser(userID: TeamTalkUserID) {
        let op = TeamTalkClient.shared.isChannelOperator(in: curchannel)
        guard (myuseraccount.uUserRights & USERRIGHT_KICK_USERS.rawValue) != 0 || op else { return }
        guard let user = users[userID] else { return }
        let channel = curchannel.channelID.isValid ? curchannel : nil

        Task { [weak self] in
            guard let self else { return }
            do {
                try await TeamTalkClient.shared.kickUser(user, from: channel)
            } catch {
                await self.presentError(error.localizedDescription)
            }
        }
    }

    func banUser(userID: TeamTalkUserID) {
        let op = TeamTalkClient.shared.isChannelOperator(in: curchannel)
        guard (myuseraccount.uUserRights & USERRIGHT_BAN_USERS.rawValue) != 0 || op else { return }
        guard let user = users[userID] else { return }
        let channel = curchannel.channelID.isValid ? curchannel : nil

        Task { [weak self] in
            guard let self else { return }
            do {
                try await TeamTalkClient.shared.banUser(user, from: channel)
                try await TeamTalkClient.shared.kickUser(user, from: channel)
            } catch {
                await self.presentError(error.localizedDescription)
            }
        }
    }

    func moveIntoChannel(channelID: TeamTalkChannelID) {
        guard !moveusers.isEmpty else {
            announceForAccessibility(String(localized: "No users selected to move", comment: "channel list"))
            return
        }
        guard let destinationChannel = channels[channelID] else { return }

        let selectedUsers = moveusers.compactMap { users[$0] }
        moveusers.removeAll()
        refreshChannelList()

        Task { [weak self] in
            guard let self else { return }
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
                await self.presentError(firstError.localizedDescription)
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

    // MARK: - Navigation

    func showUserDetail(_ user: TeamTalkUser) {
        let model = UserDetailModel(user: user)
        navigationPath.append(.userDetail(model))
    }

    func showChannelDetail(_ channel: TeamTalkChannel) {
        var rawChannel = channel.cValue
        if TeamTalkString.channel(.password, from: rawChannel).isEmpty {
            if let password = chanpasswds[channel.channelID] {
                TeamTalkString.setChannel(.password, on: &rawChannel, to: password)
            }
        }
        let model = ChannelDetailModel(channel: TeamTalkChannel(rawChannel))
        channelDetailModel = model
    }

    func showNewChannel() {
        var newChannel = Channel()
        newChannel.nParentID = curchannel.channelID.cValue
        if newChannel.nParentID == 0 {
            let subchans = channels.values.filter { !$0.parentChannelID.isValid }
            if let root = subchans.first {
                newChannel.nParentID = root.channelID.cValue
            }
        }
        let model = ChannelDetailModel(channel: newChannel)
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
            title: String(localized: "Private Text Message", comment: "text message navigation title")
        )
        openTextMessages(model)
        return model
    }

    func openTextMessages(_ model: TextMessageModel) {
        model.delegate = self
        addToTeamTalkEvents(model)
        if let user = model.privateUser, let msgs = textmessages[user.userID] {
            for m in msgs { model.appendEventMessage(m) }
        }
    }

    // MARK: - PTT

    func txBtnDown() {
        if hasPTTLock() {
            enableVoiceTx(true)
        } else {
            enableVoiceTx(!TeamTalkClient.shared.isVoiceTransmitting)
        }
    }

    func enableVoiceTx(_ enable: Bool) {
        TeamTalkClient.shared.enableVoiceTransmission(enable)
        playSound(enable ? .tx_ON : .tx_OFF)
        updateTX()
    }

    func txBtnUp() {
        if hasPTTLock() {
            let now = Date()
            if (pttLockTimeout as NSDate).earlierDate(now) == now {
                enableVoiceTx(true)
            } else {
                enableVoiceTx(false)
            }
            pttLockTimeout = now.addingTimeInterval(0.5)
        }
    }

    func txBtnAccessibilityAction() {
        enableVoiceTx(!TeamTalkClient.shared.isVoiceTransmitting)
    }

    func updateTX() {
        isTransmitting = TeamTalkClient.shared.isVoiceTransmitting
        pttHint = hasPTTLock()
            ? String(localized: "Double tap and hold to transmit. Triple tap fast to lock transmission.", comment: "channel list")
            : String(localized: "Toggle to enable/disable transmission", comment: "channel list")
        refreshChannelList()
    }

    func timerUnreadBlinker() {
        refreshChannelList()
        if unreadmessages.isEmpty {
            unreadTimer?.invalidate()
        }
    }

    // MARK: - Login follow-up

    func configureInitialJoin(channelPath: String, password: String) {
        rejoinchannel = nil

        guard !channelPath.isEmpty else { return }

        let channelID = TeamTalkClient.shared.channelIdentifier(from: TeamTalkChannelPath(channelPath))
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
        let parentID = TeamTalkClient.shared.channelIdentifier(from: TeamTalkChannelPath(channelPath))

        guard parentID.isValid else { return }

        rejoinchannel = TeamTalkChannelConfiguration(
            parentChannelID: parentID,
            name: channelName,
            password: password,
            audioCodec: newAudioCodec(DEFAULT_AUDIOCODEC)
        )
    }

    @MainActor
    func joinInitialChannelIfNeeded() async throws {
        guard TeamTalkClient.shared.isAuthorized else {
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
                if let channel = TeamTalkClient.shared.channel(id: channelID) {
                    try await TeamTalkClient.shared.joinChannel(channel, password: password)
                }
            } else if !rejoinchannel.name.isEmpty {
                try await TeamTalkClient.shared.joinChannel(rejoinchannel)
            }
        } else if UserDefaults.standard.object(forKey: PREF_JOINROOTCHANNEL) == nil
            || UserDefaults.standard.bool(forKey: PREF_JOINROOTCHANNEL) {
            if let rootChannel = TeamTalkClient.shared.channel(id: TeamTalkChannelID(TeamTalkClient.shared.rootChannelID)) {
                try await TeamTalkClient.shared.joinChannel(rootChannel)
            }
        }

        refreshChannelList()
    }

    // MARK: - Audio config

    func updateAudioConfig() {
        if mychannel.rawValue.audiocfg.bEnableAGC == TRUE {
            TeamTalkClient.shared.setSoundInputGainLevel(INT32(SOUND_GAIN_DEFAULT.rawValue))
            var ap = TeamTalkAudioPreprocessor.makeWebRTCPreprocessor()
            let gain = Float(mychannel.rawValue.audiocfg.nGainLevel) / Float(TeamTalkAudioPreprocessor.channelAudioConfigMax)
            ap.webrtc.gaincontroller2.fixeddigital.fGainDB = WEBRTC_GAINCONTROLLER2_FIXEDGAIN_MAX * gain
            ap.webrtc.gaincontroller2.bEnable = TRUE
            TeamTalkClient.shared.setSoundInputPreprocess(&ap)
        } else {
            var ap = TeamTalkAudioPreprocessor.makeTeamTalkPreprocessor()
            TeamTalkClient.shared.setSoundInputPreprocess(&ap)
            let vol = UserDefaults.standard.integer(forKey: PREF_MICROPHONE_GAIN)
            TeamTalkClient.shared.setSoundInputGainLevel(INT32(refVolume(Double(vol))))
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
            curchannel = TeamTalkChannel(Channel())
            mychannel = TeamTalkChannel(Channel())
            rejoinchannel = nil
            refreshChannelList()

        case .commandProcessing(_, let isActive):
            isProcessingCommand = isActive

        case .serverUpdated(let properties):
            srvprop = properties.rawValue

        case .myselfLoggedIn(_, let account):
            myuseraccount = account.rawValue
            if (myuseraccount.uUserType & USERTYPE_ADMIN.rawValue) != 0 {
                myuseraccount.uUserRights = 0xFFFFFFFF
            }

        case .channelCreated(let channel):
            channels[channel.channelID] = channel
            if !channel.parentChannelID.isValid { updateTitle() }
            if !isProcessingCommand { refreshChannelList() }

        case .channelUpdated(let channel):
            channels[channel.channelID] = channel
            if mychannel.channelID == channel.channelID {
                let myUserID = TeamTalkClient.shared.myUserIdentifier
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
                if user.channelIdentifier == curchannel.channelID { refreshChannelList() }
                if TeamTalkClient.shared.myUserIdentifier != user.userID {
                    let defaults = UserDefaults.standard
                    if defaults.object(forKey: PREF_TTSEVENT_USERLOGIN) != nil && defaults.bool(forKey: PREF_TTSEVENT_USERLOGIN) {
                        newUtterance(getDisplayName(user) + " " + String(localized: "has logged on", comment: "TTS EVENT"))
                    }
                }
            }

        case .userLoggedOut(let user):
            playSound(.logged_OUT)
            users.removeValue(forKey: user.userID)
            if !isProcessingCommand {
                if user.channelIdentifier == curchannel.channelID { refreshChannelList() }
                if TeamTalkClient.shared.myUserIdentifier != user.userID {
                    let defaults = UserDefaults.standard
                    if defaults.object(forKey: PREF_TTSEVENT_USERLOGOUT) != nil && defaults.bool(forKey: PREF_TTSEVENT_USERLOGOUT) {
                        newUtterance(getDisplayName(user) + " " + String(localized: "has logged out", comment: "TTS EVENT"))
                    }
                }
            }

        case .userJoined(let user):
            users[user.userID] = user
            if user.userID == TeamTalkClient.shared.myUserIdentifier, let joinedChannel = channels[user.channelIdentifier] {
                curchannel = joinedChannel
                mychannel = joinedChannel
                if rejoinchannel?.id == 0 && chanpasswds[user.channelIdentifier] == nil {
                    chanpasswds[user.channelIdentifier] = rejoinchannel?.password ?? ""
                }
                rejoinchannel = TeamTalkChannelConfiguration(joinedChannel)
                updateTitle()
                updateAudioConfig()
            }
            if user.channelIdentifier == mychannel.channelID && mychannel.channelID.isValid {
                playSound(.joined_CHAN)
                let defaults = UserDefaults.standard
                if defaults.object(forKey: PREF_TTSEVENT_JOINEDCHAN) == nil || defaults.bool(forKey: PREF_TTSEVENT_JOINEDCHAN) {
                    newUtterance(getDisplayName(user) + " " + String(localized: "has joined the channel", comment: "TTS EVENT"))
                }
            }
            if !isProcessingCommand { refreshChannelList() }

        case .userUpdated(let user):
            users[user.userID] = user
            if !isProcessingCommand { refreshChannelList() }

        case .userLeft(let previousChannelID, let user):
            if myuseraccount.uUserRights & USERRIGHT_VIEW_ALL_USERS.rawValue == 0 {
                users.removeValue(forKey: user.userID)
            } else {
                users[user.userID] = user
            }
            if user.userID == TeamTalkClient.shared.myUserIdentifier {
                mychannel = TeamTalkChannel(Channel())
                rejoinchannel = nil
            }
            if previousChannelID == mychannel.channelID && mychannel.channelID.isValid {
                playSound(.left_CHAN)
                let defaults = UserDefaults.standard
                if defaults.object(forKey: PREF_TTSEVENT_LEFTCHAN) == nil || defaults.bool(forKey: PREF_TTSEVENT_LEFTCHAN) {
                    newUtterance(getDisplayName(user) + " " + String(localized: "has left the channel", comment: "TTS EVENT"))
                }
            }
            if !isProcessingCommand { refreshChannelList() }

        case .textMessage(let message):
            if message.type == .user {
                let settings = UserDefaults.standard
                let fromUserID = message.fromUserIdentifier
                if let user = users[fromUserID] {
                    let name = getDisplayName(user)
                    let newmsg = MyTextMessage(
                        m: message.rawValue,
                        nickname: name,
                        msgtype: TeamTalkClient.shared.myUserIdentifier == message.fromUserIdentifier ? .PRIV_IM_MYSELF : .PRIV_IM
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
                   settings.object(forKey: PREF_DISPLAY_POPUPTXTMSG) == nil || settings.bool(forKey: PREF_DISPLAY_POPUPTXTMSG) {
                    let model = makeTextMessageModel(for: user)
                    currentTextMessageModel = model
                    navigationPath.append(.textMessage(model))
                    if let msg = model.getLastEventMessage() {
                        speakTextMessage(message.type.cValue, mymsg: msg)
                    }
                }
            }

        case .userStateChanged(let user):
            users[user.userID] = user
            refreshChannelList()

        case .voiceActivation:
            refreshChannelList()

        default:
            break
        }
    }
}
