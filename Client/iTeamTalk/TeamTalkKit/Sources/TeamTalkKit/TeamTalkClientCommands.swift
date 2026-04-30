import Foundation
import TeamTalkC

extension TeamTalkClient {
@discardableResult
public func ping() -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoPing(instance))
}

@discardableResult
public func logIn(nickname: String, username: String, password: String, clientName: String = "") -> TeamTalkCommandID {
    TeamTalkCommandID(login(nickname: nickname, username: username, password: password, clientName: clientName))
}

@discardableResult
public func logOut() -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoLogout(instance))
}

@discardableResult
public func join(_ channel: TeamTalkChannel) -> TeamTalkCommandID {
    var channel = channel.cValue
    return TeamTalkCommandID(TT_DoJoinChannel(instance, &channel))
}

@discardableResult
public func join(_ configuration: TeamTalkChannelConfiguration) -> TeamTalkCommandID {
    var channel = configuration.cValue
    return TeamTalkCommandID(TT_DoJoinChannel(instance, &channel))
}

@discardableResult
public func joinChannel(withID channelID: Int32, password: String = "") -> TeamTalkCommandID {
    TeamTalkCommandID(joinChannel(id: channelID, password: password))
}

@discardableResult
public func joinChannel(withID channelID: TeamTalkChannelID, password: String = "") -> TeamTalkCommandID {
    joinChannel(withID: channelID.cValue, password: password)
}

@discardableResult
public func joinChannel(_ channel: Channel, password: String = "") -> TeamTalkCommandID {
    joinChannel(withID: channel.channelID, password: password)
}

@discardableResult
public func joinChannel(_ channel: TeamTalkChannel, password: String = "") -> TeamTalkCommandID {
    joinChannel(withID: channel.channelID, password: password)
}

@discardableResult
public func leaveChannel() -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoLeaveChannel(instance))
}

@discardableResult
public func createChannel(_ configuration: TeamTalkChannelConfiguration) -> TeamTalkCommandID {
    var channel = configuration.cValue
    return TeamTalkCommandID(TT_DoMakeChannel(instance, &channel))
}

@discardableResult
public func updateChannel(_ channel: TeamTalkChannel) -> TeamTalkCommandID {
    var channel = channel.cValue
    return TeamTalkCommandID(TT_DoUpdateChannel(instance, &channel))
}

@discardableResult
public func updateChannel(_ configuration: TeamTalkChannelConfiguration) -> TeamTalkCommandID {
    var channel = configuration.cValue
    return TeamTalkCommandID(TT_DoUpdateChannel(instance, &channel))
}

@discardableResult
public func removeChannel(withID channelID: Int32) -> TeamTalkCommandID {
    TeamTalkCommandID(removeChannel(id: channelID))
}

@discardableResult
public func removeChannel(withID channelID: TeamTalkChannelID) -> TeamTalkCommandID {
    removeChannel(withID: channelID.cValue)
}

@discardableResult
public func removeChannel(_ channel: Channel) -> TeamTalkCommandID {
    removeChannel(withID: channel.channelID)
}

@discardableResult
public func removeChannel(_ channel: TeamTalkChannel) -> TeamTalkCommandID {
    removeChannel(withID: channel.channelID)
}

@discardableResult
public func setNickname(_ nickname: String) -> TeamTalkCommandID {
    TeamTalkCommandID(changeNickname(nickname))
}

@discardableResult
public func setStatus(mode: TeamTalkStatusMode, message: String = "") -> TeamTalkCommandID {
    TeamTalkCommandID(changeStatus(mode: mode.rawValue, message: message))
}

@discardableResult
public func sendTextMessage(_ message: TeamTalkOutgoingTextMessage) -> [TeamTalkCommandID] {
    TeamTalkTextMessageFactory.messages(from: message.cValue, content: message.content).map { textMessage in
        var textMessage = textMessage
        return TeamTalkCommandID(TT_DoTextMessage(instance, &textMessage))
    }
}

@discardableResult
public func sendTextMessage(to userID: TeamTalkUserID, content: String) -> [TeamTalkCommandID] {
    sendTextMessage(.user(to: userID, content: content))
}

@discardableResult
public func sendTextMessage(to user: TeamTalkUser, content: String) -> [TeamTalkCommandID] {
    sendTextMessage(.user(to: user, content: content))
}

@discardableResult
public func sendTextMessage(to channelID: TeamTalkChannelID, content: String) -> [TeamTalkCommandID] {
    sendTextMessage(.channel(channelID, content: content))
}

@discardableResult
public func sendTextMessage(to channel: TeamTalkChannel, content: String) -> [TeamTalkCommandID] {
    sendTextMessage(.channel(channel, content: content))
}

@discardableResult
public func sendChannelMessage(_ content: String) -> [TeamTalkCommandID] {
    guard let channel = currentChannel() else {
        return []
    }
    return sendTextMessage(to: channel, content: content)
}

@discardableResult
public func setChannelOperator(userID: Int32, channelID: Int32, enabled: Bool) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoChannelOp(instance, userID, channelID, enabled ? 1 : 0))
}

@discardableResult
public func setChannelOperator(userID: TeamTalkUserID, channelID: TeamTalkChannelID, enabled: Bool) -> TeamTalkCommandID {
    setChannelOperator(userID: userID.cValue, channelID: channelID.cValue, enabled: enabled)
}

@discardableResult
public func setChannelOperator(user: User, channel: Channel, enabled: Bool) -> TeamTalkCommandID {
    setChannelOperator(userID: user.userID, channelID: channel.channelID, enabled: enabled)
}

@discardableResult
public func setChannelOperator(user: TeamTalkUser, channel: TeamTalkChannel, enabled: Bool) -> TeamTalkCommandID {
    setChannelOperator(userID: user.userID, channelID: channel.channelID, enabled: enabled)
}

@discardableResult
public func setChannelOperator(userID: Int32, channelID: Int32, operatorPassword: String, enabled: Bool) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoChannelOpEx(instance, userID, channelID, operatorPassword, enabled ? 1 : 0))
}

@discardableResult
public func setChannelOperator(
    userID: TeamTalkUserID,
    channelID: TeamTalkChannelID,
    operatorPassword: String,
    enabled: Bool
) -> TeamTalkCommandID {
    setChannelOperator(
        userID: userID.cValue,
        channelID: channelID.cValue,
        operatorPassword: operatorPassword,
        enabled: enabled
    )
}

@discardableResult
public func setChannelOperator(
    user: User,
    channel: Channel,
    operatorPassword: String,
    enabled: Bool
) -> TeamTalkCommandID {
    setChannelOperator(
        userID: user.userID,
        channelID: channel.channelID,
        operatorPassword: operatorPassword,
        enabled: enabled
    )
}

@discardableResult
public func setChannelOperator(
    user: TeamTalkUser,
    channel: TeamTalkChannel,
    operatorPassword: String,
    enabled: Bool
) -> TeamTalkCommandID {
    setChannelOperator(
        userID: user.userID,
        channelID: channel.channelID,
        operatorPassword: operatorPassword,
        enabled: enabled
    )
}

@discardableResult
public func kickUser(withID userID: Int32, fromChannelID channelID: Int32 = 0) -> TeamTalkCommandID {
    TeamTalkCommandID(kickUser(id: userID, fromChannelID: channelID))
}

@discardableResult
public func kickUser(withID userID: TeamTalkUserID, fromChannelID channelID: TeamTalkChannelID = .none) -> TeamTalkCommandID {
    kickUser(withID: userID.cValue, fromChannelID: channelID.cValue)
}

@discardableResult
public func kickUser(_ user: User, fromChannel channel: Channel? = nil) -> TeamTalkCommandID {
    kickUser(withID: user.userID, fromChannelID: channel?.channelID ?? .none)
}

@discardableResult
public func kickUser(_ user: TeamTalkUser, fromChannel channel: TeamTalkChannel? = nil) -> TeamTalkCommandID {
    kickUser(withID: user.userID, fromChannelID: channel?.channelID ?? .none)
}

@discardableResult
public func banUser(withID userID: Int32, fromChannelID channelID: Int32 = 0) -> TeamTalkCommandID {
    TeamTalkCommandID(banUser(id: userID, fromChannelID: channelID))
}

@discardableResult
public func banUser(withID userID: TeamTalkUserID, fromChannelID channelID: TeamTalkChannelID = .none) -> TeamTalkCommandID {
    banUser(withID: userID.cValue, fromChannelID: channelID.cValue)
}

@discardableResult
public func banUser(_ user: User, fromChannel channel: Channel? = nil) -> TeamTalkCommandID {
    banUser(withID: user.userID, fromChannelID: channel?.channelID ?? .none)
}

@discardableResult
public func banUser(_ user: TeamTalkUser, fromChannel channel: TeamTalkChannel? = nil) -> TeamTalkCommandID {
    banUser(withID: user.userID, fromChannelID: channel?.channelID ?? .none)
}

@discardableResult
public func banUser(withID userID: Int32, types: TeamTalkBanTypes) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoBanUserEx(instance, userID, types.cValue))
}

@discardableResult
public func banUser(withID userID: TeamTalkUserID, types: TeamTalkBanTypes) -> TeamTalkCommandID {
    banUser(withID: userID.cValue, types: types)
}

@discardableResult
public func banUser(_ user: User, types: TeamTalkBanTypes) -> TeamTalkCommandID {
    banUser(withID: user.userID, types: types)
}

@discardableResult
public func banUser(_ user: TeamTalkUser, types: TeamTalkBanTypes) -> TeamTalkCommandID {
    banUser(withID: user.userID, types: types)
}

@discardableResult
public func ban(_ configuration: TeamTalkBanConfiguration) -> TeamTalkCommandID {
    var bannedUser = configuration.cValue
    return TeamTalkCommandID(TT_DoBan(instance, &bannedUser))
}

@discardableResult
public func banIPAddress(_ ipAddress: String, channelID: Int32 = 0) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoBanIPAddress(instance, ipAddress, channelID))
}

@discardableResult
public func banIPAddress(_ ipAddress: String, channelID: TeamTalkChannelID = .none) -> TeamTalkCommandID {
    banIPAddress(ipAddress, channelID: channelID.cValue)
}

@discardableResult
public func unbanIPAddress(_ ipAddress: String, channelID: Int32 = 0) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoUnBanUser(instance, ipAddress, channelID))
}

@discardableResult
public func unbanIPAddress(_ ipAddress: String, channelID: TeamTalkChannelID = .none) -> TeamTalkCommandID {
    unbanIPAddress(ipAddress, channelID: channelID.cValue)
}

@discardableResult
public func unban(_ configuration: TeamTalkBanConfiguration) -> TeamTalkCommandID {
    var bannedUser = configuration.cValue
    return TeamTalkCommandID(TT_DoUnBanUserEx(instance, &bannedUser))
}

@discardableResult
public func listBans(channelID: Int32 = 0, startingAt index: Int32 = 0, count: Int32 = 100) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoListBans(instance, channelID, index, count))
}

@discardableResult
public func listBans(channelID: TeamTalkChannelID = .none, startingAt index: Int32 = 0, count: Int32 = 100) -> TeamTalkCommandID {
    listBans(channelID: channelID.cValue, startingAt: index, count: count)
}

@discardableResult
public func moveUser(withID userID: Int32, toChannelID channelID: Int32) -> TeamTalkCommandID {
    TeamTalkCommandID(moveUser(id: userID, toChannelID: channelID))
}

@discardableResult
public func moveUser(withID userID: TeamTalkUserID, toChannelID channelID: TeamTalkChannelID) -> TeamTalkCommandID {
    moveUser(withID: userID.cValue, toChannelID: channelID.cValue)
}

@discardableResult
public func moveUser(_ user: User, to channel: Channel) -> TeamTalkCommandID {
    moveUser(withID: user.userID, toChannelID: channel.channelID)
}

@discardableResult
public func moveUser(_ user: TeamTalkUser, to channel: TeamTalkChannel) -> TeamTalkCommandID {
    moveUser(withID: user.userID, toChannelID: channel.channelID)
}

@discardableResult
public func uploadFileCommand(at localURL: URL, toChannelID channelID: Int32) -> TeamTalkCommandID {
    TeamTalkCommandID(uploadFile(at: localURL, toChannelID: channelID))
}

@discardableResult
public func uploadFileCommand(at localURL: URL, toChannelID channelID: TeamTalkChannelID) -> TeamTalkCommandID {
    uploadFileCommand(at: localURL, toChannelID: channelID.cValue)
}

@discardableResult
public func uploadFileCommand(at localURL: URL, toChannel channel: Channel) -> TeamTalkCommandID {
    uploadFileCommand(at: localURL, toChannelID: channel.channelID)
}

@discardableResult
public func uploadFile(at localURL: URL, to channel: TeamTalkChannel) -> TeamTalkCommandID {
    uploadFileCommand(at: localURL, toChannelID: channel.channelID)
}

@discardableResult
public func downloadFileCommand(channelID: Int32, fileID: Int32, to localURL: URL) -> TeamTalkCommandID {
    TeamTalkCommandID(downloadFile(channelID: channelID, fileID: fileID, to: localURL))
}

@discardableResult
public func downloadFileCommand(channelID: TeamTalkChannelID, fileID: TeamTalkFileID, to localURL: URL) -> TeamTalkCommandID {
    downloadFileCommand(channelID: channelID.cValue, fileID: fileID.cValue, to: localURL)
}

@discardableResult
public func downloadFileCommand(_ file: RemoteFile, to localURL: URL) -> TeamTalkCommandID {
    downloadFileCommand(channelID: file.channelIdentifier, fileID: file.fileID, to: localURL)
}

@discardableResult
public func downloadFile(_ file: TeamTalkRemoteFile, to localURL: URL) -> TeamTalkCommandID {
    downloadFileCommand(channelID: file.channelIdentifier, fileID: file.fileID, to: localURL)
}

@discardableResult
public func downloadFileCommand(_ file: TeamTalkRemoteFile, to localURL: URL) -> TeamTalkCommandID {
    downloadFileCommand(channelID: file.channelIdentifier, fileID: file.fileID, to: localURL)
}

@discardableResult
public func deleteFileCommand(channelID: Int32, fileID: Int32) -> TeamTalkCommandID {
    TeamTalkCommandID(deleteFile(channelID: channelID, fileID: fileID))
}

@discardableResult
public func deleteFileCommand(channelID: TeamTalkChannelID, fileID: TeamTalkFileID) -> TeamTalkCommandID {
    deleteFileCommand(channelID: channelID.cValue, fileID: fileID.cValue)
}

@discardableResult
public func deleteFileCommand(_ file: RemoteFile) -> TeamTalkCommandID {
    deleteFileCommand(channelID: file.channelIdentifier, fileID: file.fileID)
}

@discardableResult
public func deleteFile(_ file: TeamTalkRemoteFile) -> TeamTalkCommandID {
    deleteFileCommand(channelID: file.channelIdentifier, fileID: file.fileID)
}

@discardableResult
public func deleteFileCommand(_ file: TeamTalkRemoteFile) -> TeamTalkCommandID {
    deleteFileCommand(channelID: file.channelIdentifier, fileID: file.fileID)
}

@discardableResult
public func subscribeCommand(userID: Int32, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoSubscribe(instance, userID, subscriptions.cValue))
}

@discardableResult
public func subscribeCommand(userID: TeamTalkUserID, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
    subscribeCommand(userID: userID.cValue, subscriptions: subscriptions)
}

@discardableResult
public func subscribeCommand(user: User, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
    subscribeCommand(userID: user.userID, subscriptions: subscriptions)
}

@discardableResult
public func subscribeCommand(user: TeamTalkUser, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
    subscribeCommand(userID: user.userID, subscriptions: subscriptions)
}

@discardableResult
public func unsubscribeCommand(userID: Int32, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoUnsubscribe(instance, userID, subscriptions.cValue))
}

@discardableResult
public func unsubscribeCommand(userID: TeamTalkUserID, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
    unsubscribeCommand(userID: userID.cValue, subscriptions: subscriptions)
}

@discardableResult
public func unsubscribeCommand(user: User, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
    unsubscribeCommand(userID: user.userID, subscriptions: subscriptions)
}

@discardableResult
public func unsubscribeCommand(user: TeamTalkUser, subscriptions: TeamTalkSubscriptions) -> TeamTalkCommandID {
    unsubscribeCommand(userID: user.userID, subscriptions: subscriptions)
}

@discardableResult
public func updateServer(_ configuration: TeamTalkServerPropertiesConfiguration) -> TeamTalkCommandID {
    var properties = configuration.cValue
    return TeamTalkCommandID(TT_DoUpdateServer(instance, &properties))
}

@discardableResult
public func updateServer(_ properties: TeamTalkServerProperties) -> TeamTalkCommandID {
    var properties = properties.cValue
    return TeamTalkCommandID(TT_DoUpdateServer(instance, &properties))
}

@discardableResult
public func listUserAccounts(startingAt index: Int32 = 0, count: Int32 = 100) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoListUserAccounts(instance, index, count))
}

@discardableResult
public func createUserAccount(_ configuration: TeamTalkUserAccountConfiguration) -> TeamTalkCommandID {
    var account = configuration.cValue
    return TeamTalkCommandID(TT_DoNewUserAccount(instance, &account))
}

@discardableResult
public func createUserAccount(_ account: TeamTalkUserAccount) -> TeamTalkCommandID {
    var account = account.cValue
    return TeamTalkCommandID(TT_DoNewUserAccount(instance, &account))
}

@discardableResult
public func deleteUserAccount(username: String) -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoDeleteUserAccount(instance, username))
}

@discardableResult
public func saveServerConfiguration() -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoSaveConfig(instance))
}

@discardableResult
public func queryServerStatistics() -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoQueryServerStats(instance))
}

@discardableResult
public func quitServer() -> TeamTalkCommandID {
    TeamTalkCommandID(TT_DoQuit(instance))
}

}
