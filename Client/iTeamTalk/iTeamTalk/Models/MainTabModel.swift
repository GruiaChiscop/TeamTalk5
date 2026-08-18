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
import Observation
import OSLog
import SwiftUI
import TeamTalkKit
import UIKit

@Observable
final class MainTabModel: TeamTalkEventObserver {

    let session: TeamTalkSession

    let channelListModel: ChannelListModel
    let channelChatModel: TextMessageModel
    let channelFilesModel: ChannelFilesModel
    let preferencesModel: PreferencesModel

    var server: Server

    var alertMessage: String?
    var fatalAlertMessage: String?   // dismisses the view when OK tapped
    var showSaveAlert = false

    var isPresentingAlert: Bool {
        get { alertMessage != nil }
        set { if !newValue { alertMessage = nil } }
    }

    var isPresentingFatalAlert: Bool {
        get { fatalAlertMessage != nil }
        set { if !newValue { fatalAlertMessage = nil } }
    }

    private var pendingDismiss: (() -> Void)?
    private var reconnecttimer: Timer?
    private var didSetup = false

    init(server: Server, session: TeamTalkSession) {
        self.server = server
        self.session = session
        channelListModel = ChannelListModel(session: session)
        channelChatModel = TextMessageModel(
            target: .channelFeed,
            title: String(localized: "Messages", comment: "tab"),
            session: session
        )
        channelFilesModel = ChannelFilesModel(session: session)
        preferencesModel = PreferencesModel(session: session)
        channelListModel.openTextMessages(channelChatModel)
    }

    deinit {
        session.disconnect()
        closeSoundDevices(session: session)
        // closeSoundDevices() only closes the individual input/output devices;
        // the native SDK only deactivates the OS audio session when its audio
        // subsystem singleton is destructed, which doesn't happen until process
        // exit. Deactivate it here so leaving a server actually releases it.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        print("Destroyed main view controller")
    }

    func setup() {
        guard !didSetup else { return }
        didSetup = true

        addToTeamTalkEvents(self, on: session)
        addToTeamTalkEvents(channelListModel, on: session)
        addToTeamTalkEvents(channelChatModel, on: session)
        addToTeamTalkEvents(channelFilesModel, on: session)
        addToTeamTalkEvents(preferencesModel, on: session)

        setupSoundDevices(session: session)

        // Reads the persisted values directly: Preferences.sound.* mirrors the SDK's
        // *live* volume for the Preferences screen, not what should be re-applied here.
        let defaults = UserDefaults.standard
        if defaults.object(forKey: PREF_MASTER_VOLUME) != nil {
            let vol = defaults.integer(forKey: PREF_MASTER_VOLUME)
            session.setSoundOutputVolume(INT32(refVolume(Double(vol))))
        }
        if defaults.object(forKey: PREF_VOICEACTIVATION) != nil {
            let voiceact = defaults.integer(forKey: PREF_VOICEACTIVATION)
            if voiceact != VOICEACT_DISABLED {
                session.enableVoiceActivation(true)
                session.setVoiceActivationLevel(INT32(voiceact))
            }
        }
        if defaults.object(forKey: PREF_MICROPHONE_GAIN) != nil {
            let vol = defaults.integer(forKey: PREF_MICROPHONE_GAIN)
            session.setSoundInputGainLevel(INT32(refVolume(Double(vol))))
        }

        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(proximityChanged(_:)),
            name: UIDevice.proximityStateDidChangeNotification,
            object: UIDevice.current
        )
        center.addObserver(
            self, selector: #selector(audioRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        center.addObserver(
            self, selector: #selector(audioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        connectToServer()
    }

    func teardown() {
        reconnecttimer?.invalidate()
        removeFromTeamTalkEvents(self, from: session)
        removeFromTeamTalkEvents(channelListModel, from: session)
        removeFromTeamTalkEvents(channelChatModel, from: session)
        removeFromTeamTalkEvents(channelFilesModel, from: session)
        removeFromTeamTalkEvents(preferencesModel, from: session)
        unreadmessages.removeAll()
        UIDevice.current.isProximityMonitoringEnabled = false
        UIApplication.shared.endReceivingRemoteControlEvents()
    }

    func onVisibleAppear() {
        let preferences = Preferences.current
        if preferences.display.proximitySensor {
            UIDevice.current.isProximityMonitoringEnabled = true
        }
        if preferences.general.headsetTXToggle {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
    }

    func remoteControl(_ event: UIEvent?) {
        guard let rc = event?.subtype else { return }
        switch rc {
        case .remoteControlPause, .remoteControlTogglePlayPause:
            channelListModel.pushToTalk.enableVoiceTx(false)
        case .remoteControlPreviousTrack, .remoteControlNextTrack:
            channelListModel.pushToTalk.enableVoiceTx(true)
        default:
            break
        }
    }

    func disconnectTapped(dismiss: @escaping () -> Void) {
        let servers = loadLocalServers()
        let found = servers.filter {
            $0.ipaddr == server.ipaddr &&
            $0.tcpport == server.tcpport &&
            $0.udpport == server.udpport &&
            $0.username == server.username
        }
        if found.isEmpty && server.servertype == .LOCAL {
            pendingDismiss = { dismiss() }
            showSaveAlert = true
        } else {
            dismiss()
        }
    }

    func saveAndDisconnect(name: String) {
        var servers = loadLocalServers()
        servers = servers.filter { $0.name != name }
        server.name = name
        servers.append(server)
        saveLocalServers(servers)
        pendingDismiss?()
        pendingDismiss = nil
    }

    func skipSaveAndDisconnect() {
        pendingDismiss?()
        pendingDismiss = nil
    }

    func startReconnectTimer() {
        reconnecttimer = Timer.scheduledTimer(
            timeInterval: 5.0,
            target: self,
            selector: #selector(connectToServer),
            userInfo: nil,
            repeats: false
        )
    }

    @objc func connectToServer() {
        if !setupEncryption(server: server, session: session) {
            fatalAlertMessage = String(localized: "Failed to setup encryption", comment: "connect to a server")
        } else if !session.connect(
            toHost: server.ipaddr,
            tcpPort: INT32(server.tcpport),
            udpPort: INT32(server.udpport),
            encrypted: server.encrypted
        ) {
            session.disconnect()
            startReconnectTimer()
        }
    }

    @objc private func proximityChanged(_ notification: Notification) {}

    @objc private func audioRouteChange(_ notification: Notification) {
        guard let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        switch reason {
        case .oldDeviceUnavailable:
            setupSoundDevices(session: session)
        default:
            break
        }
        print(AVAudioSession.sharedInstance().currentRoute)
    }

    @objc private func audioInterruption(_ notification: Notification) {
        guard let optionValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
        let options = AVAudioSession.InterruptionOptions(rawValue: optionValue)
        if options.contains(.shouldResume) {
            setupSoundDevices(session: session)
        }
    }

    func handleTeamTalkEvent(_ event: TeamTalkEvent) {
        switch event.kind {

        case .connectionSucceeded:
            os_log("Connected to \(self.server.ipaddr)")

            if AppInfo.isBearWareWebLogin(self.server.username) {
                let webLogin = Preferences.current.webLogin
                let username = webLogin.bearwareID ?? ""
                let token = webLogin.bearwareToken ?? ""
                let accesstoken = session.serverProperties()?.accessToken ?? ""
                let url = AppInfo.getBearWareServerTokenURL(
                    username: username, token: token, accesstoken: accesstoken
                )
                let authParser = WebLoginParser()
                if let tokenURL = URL(string: url), let parser = XMLParser(contentsOf: tokenURL) {
                    parser.delegate = authParser
                    if parser.parse() && authParser.username.count > 0 {
                        self.server.username = authParser.username
                        self.server.password = AppInfo.WEBLOGIN_BEARWARE_PASSWDPREFIX + authParser.token
                    }
                }
                if self.server.username == AppInfo.WEBLOGIN_BEARWARE_USERNAME {
                    alertMessage = String(localized: "BearWare.dk Web Login failed to authenticate. Check BearWare.dk Web Login in Preferences", comment: "weblogin event")
                }
            }
            login()

        case .connectionFailed:
            session.disconnect()
            startReconnectTimer()
            os_log("Connect to \(self.server.ipaddr) failed")

        case .connectionLost:
            os_log("Connection to \(self.server.ipaddr) lost")
            session.disconnect()
            playSound(.srv_LOST)
            if Preferences.current.textToSpeechEvents.connectionLost {
                newUtterance(String(localized: "Connection lost", comment: "tts event"))
            }
            startReconnectTimer()

        case .voiceActivation(let isActive):
            playSound(isActive ? .voxtriggered_ON : .voxtriggered_OFF)

        case .myselfLoggedIn(_, let account):
            let initchan = account.initialChannel
            if !initchan.isEmpty {
                server.channel = initchan
            }

        case .myselfKicked(let channelID, let kickedBy):
            let msg: String
            if let kickedBy {
                let kicker = getDisplayName(kickedBy)
                msg = !channelID.isValid
                    ? String(format: String(localized: "You have been kicked from server by %@", comment: "Dialog"), kicker)
                    : String(format: String(localized: "You have been kicked from channel by %@", comment: "Dialog"), kicker)
            } else {
                msg = !channelID.isValid
                    ? String(localized: "You have been kicked from server", comment: "Dialog")
                    : String(localized: "You have been kicked from channel", comment: "Dialog")
            }
            if !channelID.isValid { playSound(.srv_LOST) }
            alertMessage = msg

        case .userLoggedIn(let user):
            let subscriptions = getDefaultSubscriptions()
            if session.myUserIdentifier != user.userID && user.localSubscriptions != subscriptions {
                let difference = TeamTalkSubscriptions(rawValue: user.localSubscriptions.rawValue ^ subscriptions.rawValue)
                session.unsubscribe(difference, from: user)
            }
            syncFromUserCache(user: user, session: session)

        case .userLoggedOut(let user):
            syncToUserCache(user: user)

        case .userJoined(let user):
            // Raw read, not Preferences.sound.mediaFileVolumePercent: this must stay
            // unset (skip applying a volume) when the user never touched the slider,
            // whereas Preferences always resolves a display default for that field.
            let defaults = UserDefaults.standard
            if let mfvol = defaults.object(forKey: PREF_MEDIAFILE_VOLUME) as? Double {
                let vol = refVolume(100.0 * mfvol)
                session.setUserVolume(
                    user, stream: .mediaFileAudio, volume: INT32(vol)
                )
            }
            if !session.myRights.contains(.canViewAllUsers) {
                syncFromUserCache(user: user, session: session)
            }

        case .userLeft(_, let user):
            if !session.myRights.contains(.canViewAllUsers) {
                syncToUserCache(user: user)
            }

        case .textMessage(let message):
            switch message.type {
            case .channel:   playSound(.chan_MSG)
            case .user:      playSound(.user_MSG)
            case .broadcast: playSound(.broadcast_MSG)
            default: break
            }

        default:
            break
        }
    }

    private func login() {
        let nickname = server.nickname.isEmpty
            ? Preferences.current.general.nickname
            : server.nickname
        reconnecttimer?.invalidate()

        Task { [weak self] in
            guard let self else { return }

            do {
                try await session.logIn(
                    nickname: nickname,
                    username: server.username,
                    password: server.password,
                    clientName: AppInfo.getAppName()
                )

                await MainActor.run {
                    self.channelListModel.configureInitialJoin(
                        channelPath: self.server.channel,
                        password: self.server.chanpasswd
                    )
                    self.server.channel.removeAll()
                    self.server.chanpasswd.removeAll()

                    if Preferences.current.general.genderIndex != 0 {
                        self.session.setStatus(mode: .female)
                    }
                }

                try await self.channelListModel.joinInitialChannelIfNeeded()
            } catch {
                await MainActor.run {
                    self.alertMessage = error.localizedDescription
                }
            }
        }
    }
}
