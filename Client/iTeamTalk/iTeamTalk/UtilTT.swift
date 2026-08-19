//
//  UtilTT.swift
//  iTeamTalk
//
//  Created by Bjørn Damstedt Rasmussen on 10/01/2021.
//  Copyright © 2021 BearWare.dk. All rights reserved.
//

import Foundation
import TeamTalkKit

func addToTeamTalkEvents(_ observer: TeamTalkEventObserver, on session: TeamTalkSession) {
    session.addEventObserver(observer)
}

func removeFromTeamTalkEvents(_ observer: TeamTalkEventObserver, from session: TeamTalkSession) {
    session.removeEventObserver(observer)
}

func setupEncryption(server: Server, session: TeamTalkSession) -> Bool {
    if server.encrypted == false {
        return true
    }

    do {
        let configuration = TeamTalkEncryptionConfiguration(
            caCertificate: server.cacertdata,
            certificate: server.certdata,
            privateKey: server.certprivkeydata,
            verifyPeer: server.certverifypeer
        )
        let result = try session.configureEncryption(configuration)
        if result {
           print("Encryption activated")
        }
        else {
            print("Failed to set encryption")
        }
        return result
    } catch {
        print("Exception thrown trying to create directory")
        return false
    }
}

let TRUE : TTBOOL = 1
let FALSE : TTBOOL = 0

// MARK: - Per-user settings cache

// Keyed by BearWare.dk web-login username, since that's the only identity
// that's stable across reconnects and across different servers.
func userCacheID(user: TeamTalkUser) -> String {
    let username = user.username
    if username.hasSuffix(AppInfo.WEBLOGIN_BEARWARE_USERNAMEPOSTFIX) {
        return username + "|" + user.clientName
    }
    return ""
}

class UserCached {
    var subscriptions: TeamTalkSubscriptions
    var voiceMute: Bool
    var mediaMute: Bool
    var voiceVolume: Int32
    var mediaVolume: Int32
    var voiceLeftSpeaker, voiceRightSpeaker,
    mediaLeftSpeaker, mediaRightSpeaker: Bool

    init(user: TeamTalkUser) {
        subscriptions = user.localSubscriptions
        voiceMute = user.states.contains(.voiceMuted)
        mediaMute = user.states.contains(.mediaFileMuted)
        voiceVolume = user.voiceVolume
        mediaVolume = user.mediaFileVolume
        voiceLeftSpeaker = user.voiceStereoLeftSpeaker
        voiceRightSpeaker = user.voiceStereoRightSpeaker
        mediaLeftSpeaker = user.mediaFileStereoLeftSpeaker
        mediaRightSpeaker = user.mediaFileStereoRightSpeaker
    }

    func sync(user: TeamTalkUser, session: TeamTalkSession) {
        session.setUserMute(user, stream: .voice, muted: voiceMute)
        session.setUserMute(user, stream: .mediaFileAudio, muted: mediaMute)
        session.setUserVolume(user, stream: .voice, volume: voiceVolume)
        session.setUserVolume(user, stream: .mediaFileAudio, volume: mediaVolume)
        session.setUserStereo(user, stream: .voice, leftSpeaker: voiceLeftSpeaker, rightSpeaker: voiceRightSpeaker)
        session.setUserStereo(user, stream: .mediaFileAudio, leftSpeaker: mediaLeftSpeaker, rightSpeaker: mediaRightSpeaker)
        if subscriptions != user.localSubscriptions {
            let diff = TeamTalkSubscriptions(rawValue: user.localSubscriptions.rawValue ^ subscriptions.rawValue)
            session.unsubscribe(diff, from: user)
            session.subscribe(subscriptions, to: user)
        }
    }
}

var userCache = [String: UserCached]()

func syncFromUserCache(user: TeamTalkUser, session: TeamTalkSession) {
    let cacheid = userCacheID(user: user)
    if cacheid.isEmpty == false {
        if let cache = userCache[cacheid] {
            cache.sync(user: user, session: session)
        }
    }
}

func syncToUserCache(user: TeamTalkUser) {
    let cacheid = userCacheID(user: user)
    if cacheid.isEmpty == false {
        userCache[cacheid] = UserCached(user: user)
    }
}
