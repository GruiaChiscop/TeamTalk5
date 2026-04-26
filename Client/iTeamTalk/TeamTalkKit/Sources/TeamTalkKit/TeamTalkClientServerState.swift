import Foundation
import TeamTalkC

extension TeamTalkClient {
public func start(licenseName: String, licenseKey: String) {
    guard instance == nil else {
        return
    }

    TT_SetLicenseInformation(licenseName, licenseKey)
    instance = TT_InitTeamTalkPoll()
}

public func close() {
    guard let instance else {
        return
    }

    TT_CloseTeamTalk(instance)
    self.instance = nil
    observers.removeAll()
    eventObservers.removeAll()
}

@discardableResult
public func connect(toHost host: String, tcpPort: Int32, udpPort: Int32, encrypted: Bool) -> Bool {
    TT_Connect(instance, host, tcpPort, udpPort, 0, 0, encrypted ? 1 : 0) != 0
}

public func disconnect() {
    TT_Disconnect(instance)
}

@discardableResult
public func login(nickname: String, username: String, password: String, clientName: String) -> Int32 {
    TT_DoLoginEx(instance, nickname, username, password, clientName)
}

public func channelID(fromPath path: String) -> Int32 {
    TT_GetChannelIDFromPath(instance, path)
}

public func channelID(from path: TeamTalkChannelPath) -> Int32 {
    channelID(fromPath: path.rawValue)
}

public func channelIdentifier(fromPath path: String) -> TeamTalkChannelID {
    TeamTalkChannelID(channelID(fromPath: path))
}

public func channelIdentifier(from path: TeamTalkChannelPath) -> TeamTalkChannelID {
    TeamTalkChannelID(channelID(from: path))
}

public func channelPath(id channelID: Int32) -> String? {
    guard let instance else {
        return nil
    }

    var channelPath = [TTCHAR](repeating: 0, count: Int(TT_STRLEN))
    let success: TTBOOL = channelPath.withUnsafeMutableBufferPointer { buffer in
        guard let baseAddress = buffer.baseAddress else {
            return 0
        }
        return TT_GetChannelPath(instance, channelID, baseAddress)
    }
    guard success != 0 else {
        return nil
    }
    return String(cString: channelPath)
}

public func channelPath(id channelID: TeamTalkChannelID) -> TeamTalkChannelPath? {
    channelPath(id: channelID.cValue).map { TeamTalkChannelPath(rawValue: $0) }
}

public func channel(path: TeamTalkChannelPath) -> TeamTalkChannel? {
    channel(id: channelIdentifier(from: path))
}

public func channelPath(for channel: Channel) -> TeamTalkChannelPath? {
    channelPath(id: channel.channelID)
}

public func isChannelOperator(userID: Int32? = nil, channelID: Int32) -> Bool {
    TT_IsChannelOperator(instance, userID ?? myUserID, channelID) != 0
}

public func isChannelOperator(userID: TeamTalkUserID? = nil, channelID: TeamTalkChannelID) -> Bool {
    isChannelOperator(userID: userID?.cValue, channelID: channelID.cValue)
}

public func isChannelOperator(user: User? = nil, channel: Channel) -> Bool {
    isChannelOperator(userID: user?.userID, channelID: channel.channelID)
}

public func withServerProperties<T>(_ body: (inout ServerProperties) -> T) -> T {
    var properties = ServerProperties()
    TT_GetServerProperties(instance, &properties)
    return body(&properties)
}

public func withChannel<T>(id channelID: Int32, _ body: (inout Channel) -> T) -> T {
    var channel = Channel()
    TT_GetChannel(instance, channelID, &channel)
    return body(&channel)
}

public func withChannel<T>(id channelID: TeamTalkChannelID, _ body: (inout Channel) -> T) -> T {
    withChannel(id: channelID.cValue, body)
}

public func withUser<T>(id userID: Int32, _ body: (inout User) -> T) -> T {
    var user = User()
    TT_GetUser(instance, userID, &user)
    return body(&user)
}

public func withUser<T>(id userID: TeamTalkUserID, _ body: (inout User) -> T) -> T {
    withUser(id: userID.cValue, body)
}

public func serverProperties() -> TeamTalkServerProperties? {
    guard let instance else {
        return nil
    }

    var properties = ServerProperties()
    guard TT_GetServerProperties(instance, &properties) != 0 else {
        return nil
    }
    return TeamTalkServerProperties(properties)
}

public func currentUserAccount() -> TeamTalkUserAccount? {
    guard let instance else {
        return nil
    }

    var account = UserAccount()
    guard TT_GetMyUserAccount(instance, &account) != 0 else {
        return nil
    }
    return TeamTalkUserAccount(account)
}

public func clientStatisticsInfo() -> ClientStatistics? {
    guard let instance else {
        return nil
    }

    var statistics = ClientStatistics()
    guard TT_GetClientStatistics(instance, &statistics) != 0 else {
        return nil
    }
    return statistics
}

public func clientStatistics() -> TeamTalkClientStatistics? {
    clientStatisticsInfo().map(TeamTalkClientStatistics.init)
}

public func clientKeepAliveInfo() -> ClientKeepAlive? {
    guard let instance else {
        return nil
    }

    var keepAlive = ClientKeepAlive()
    guard TT_GetClientKeepAlive(instance, &keepAlive) != 0 else {
        return nil
    }
    return keepAlive
}

public func clientKeepAlive() -> TeamTalkClientKeepAlive? {
    clientKeepAliveInfo().map(TeamTalkClientKeepAlive.init)
}

@discardableResult
public func setClientKeepAlive(_ keepAlive: inout ClientKeepAlive) -> Bool {
    guard let instance else {
        return false
    }

    return TT_SetClientKeepAlive(instance, &keepAlive) != 0
}

@discardableResult
public func setClientKeepAlive(_ configuration: TeamTalkClientKeepAliveConfiguration) -> Bool {
    var keepAlive = configuration.cValue
    return setClientKeepAlive(&keepAlive)
}

@discardableResult
public func setClientKeepAlive(_ keepAlive: TeamTalkClientKeepAlive) -> Bool {
    var rawKeepAlive = keepAlive.cValue
    return setClientKeepAlive(&rawKeepAlive)
}

public func userStatisticsInfo(id userID: Int32) -> UserStatistics? {
    guard let instance else {
        return nil
    }

    var statistics = UserStatistics()
    guard TT_GetUserStatistics(instance, userID, &statistics) != 0 else {
        return nil
    }
    return statistics
}

public func userStatisticsInfo(id userID: TeamTalkUserID) -> UserStatistics? {
    userStatisticsInfo(id: userID.cValue)
}

public func userStatistics(id userID: Int32) -> TeamTalkUserStatistics? {
    userStatisticsInfo(id: userID).map(TeamTalkUserStatistics.init)
}

public func userStatistics(id userID: TeamTalkUserID) -> TeamTalkUserStatistics? {
    userStatistics(id: userID.cValue)
}

public func serverUsers() -> [TeamTalkUser] {
    guard let instance else {
        return []
    }

    var count: Int32 = 0
    guard TT_GetServerUsers(instance, nil, &count) != 0, count > 0 else {
        return []
    }

    var users = Array(repeating: User(), count: Int(count))
    var userCount = count
    let didRead = users.withUnsafeMutableBufferPointer { buffer in
        TT_GetServerUsers(instance, buffer.baseAddress, &userCount) != 0
    }
    guard didRead else {
        return []
    }

    return users.prefix(Int(max(0, min(userCount, count)))).map(TeamTalkUser.init)
}

public func channels() -> [TeamTalkChannel] {
    guard let instance else {
        return []
    }

    var count: Int32 = 0
    guard TT_GetServerChannels(instance, nil, &count) != 0, count > 0 else {
        return []
    }

    var channels = Array(repeating: Channel(), count: Int(count))
    var channelCount = count
    let didRead = channels.withUnsafeMutableBufferPointer { buffer in
        TT_GetServerChannels(instance, buffer.baseAddress, &channelCount) != 0
    }
    guard didRead else {
        return []
    }

    return channels.prefix(Int(max(0, min(channelCount, count)))).map(TeamTalkChannel.init)
}

public func users(inChannelID channelID: Int32) -> [TeamTalkUser] {
    guard let instance else {
        return []
    }

    var count: Int32 = 0
    guard TT_GetChannelUsers(instance, channelID, nil, &count) != 0, count > 0 else {
        return []
    }

    var users = Array(repeating: User(), count: Int(count))
    var userCount = count
    let didRead = users.withUnsafeMutableBufferPointer { buffer in
        TT_GetChannelUsers(instance, channelID, buffer.baseAddress, &userCount) != 0
    }
    guard didRead else {
        return []
    }

    return users.prefix(Int(max(0, min(userCount, count)))).map(TeamTalkUser.init)
}

public func users(inChannelID channelID: TeamTalkChannelID) -> [TeamTalkUser] {
    users(inChannelID: channelID.cValue)
}

public func users(in channel: Channel) -> [TeamTalkUser] {
    users(inChannelID: channel.channelID)
}

public func channel(id channelID: Int32) -> TeamTalkChannel? {
    guard let instance else {
        return nil
    }

    var channel = Channel()
    guard TT_GetChannel(instance, channelID, &channel) != 0 else {
        return nil
    }
    return TeamTalkChannel(channel)
}

public func channel(id channelID: TeamTalkChannelID) -> TeamTalkChannel? {
    channel(id: channelID.cValue)
}

public func user(id userID: Int32) -> TeamTalkUser? {
    guard let instance else {
        return nil
    }

    var user = User()
    guard TT_GetUser(instance, userID, &user) != 0 else {
        return nil
    }
    return TeamTalkUser(user)
}

public func user(id userID: TeamTalkUserID) -> TeamTalkUser? {
    user(id: userID.cValue)
}

public func user(username: String) -> TeamTalkUser? {
    guard let instance else {
        return nil
    }

    var user = User()
    guard TT_GetUserByUsername(instance, username, &user) != 0 else {
        return nil
    }
    return TeamTalkUser(user)
}

public func channelFiles(in channelID: Int32) -> [RemoteFile] {
    guard let instance else {
        return []
    }

    var count: Int32 = 0
    guard TT_GetChannelFiles(instance, channelID, nil, &count) != 0, count > 0 else {
        return []
    }

    var files = Array(repeating: RemoteFile(), count: Int(count))
    var fileCount = count
    let didRead = files.withUnsafeMutableBufferPointer { buffer in
        TT_GetChannelFiles(instance, channelID, buffer.baseAddress, &fileCount) != 0
    }
    guard didRead else {
        return []
    }

    let returnedCount = max(0, min(Int(fileCount), files.count))
    if returnedCount < files.count {
        files.removeLast(files.count - returnedCount)
    }
    return files
}

public func channelFiles(in channelID: TeamTalkChannelID) -> [RemoteFile] {
    channelFiles(in: channelID.cValue)
}

public func channelFiles(in channel: Channel) -> [RemoteFile] {
    channelFiles(in: channel.channelID)
}

public func channelFile(channelID: Int32, fileID: Int32) -> RemoteFile? {
    guard let instance else {
        return nil
    }

    var file = RemoteFile()
    guard TT_GetChannelFile(instance, channelID, fileID, &file) != 0 else {
        return nil
    }
    return file
}

public func channelFile(channelID: TeamTalkChannelID, fileID: TeamTalkFileID) -> RemoteFile? {
    channelFile(channelID: channelID.cValue, fileID: fileID.cValue)
}

public func channelFile(in channel: Channel, fileID: TeamTalkFileID) -> RemoteFile? {
    channelFile(channelID: channel.channelID, fileID: fileID)
}

public func remoteFiles(in channelID: Int32) -> [TeamTalkRemoteFile] {
    channelFiles(in: channelID).map(TeamTalkRemoteFile.init)
}

public func remoteFiles(in channelID: TeamTalkChannelID) -> [TeamTalkRemoteFile] {
    remoteFiles(in: channelID.cValue)
}

public func remoteFiles(in channel: Channel) -> [TeamTalkRemoteFile] {
    remoteFiles(in: channel.channelID)
}

public func remoteFile(channelID: Int32, fileID: Int32) -> TeamTalkRemoteFile? {
    channelFile(channelID: channelID, fileID: fileID).map(TeamTalkRemoteFile.init)
}

public func remoteFile(channelID: TeamTalkChannelID, fileID: TeamTalkFileID) -> TeamTalkRemoteFile? {
    remoteFile(channelID: channelID.cValue, fileID: fileID.cValue)
}

public func remoteFile(in channel: Channel, fileID: TeamTalkFileID) -> TeamTalkRemoteFile? {
    remoteFile(channelID: channel.channelID, fileID: fileID)
}

}
