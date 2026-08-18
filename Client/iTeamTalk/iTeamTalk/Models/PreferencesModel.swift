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

// In-memory snapshot of the settings shown on the Preferences screen. This is
// the single source of truth PreferencesModel reads from and writes through;
// persistence still goes to the same individual UserDefaults keys other parts
// of the app (sound/TTS playback, channel defaults, server filtering, ...)
// read directly, so those call sites don't need to know this struct exists.
struct Preferences {
    struct General {
        var nickname = ""
        var genderIndex = 0
        var pushToTalkLock = false
        var headsetTXToggle = false
        var sendOnReturn = true
    }

    struct Display {
        var proximitySensor = false
        var popupTextMessages = true
        var limitText = Double(DEFAULT_LIMIT_TEXT)
        var showUsername = false
        var channelSortIndex = ChanSort.ASCENDING.rawValue
    }

    struct Sound {
        var masterVolumePercent = 0.0
        var mediaFileVolumePercent = Double(DEFAULT_MEDIAFILE_VOLUME * 100)
        var microphoneGainPercent = 0.0
        var voiceActivationLevel = Double(VOICEACT_DISABLED)
    }

    struct TextToSpeech {
        var rate = Double(AVSpeechUtteranceDefaultSpeechRate)
        var volume = Double(DEFAULT_TTS_VOL)
    }

    struct Connection {
        var joinRootChannel = true
    }

    struct SoundEvents {
        var voiceTransmission = true
        var channelMessage = true
        var userMessage = true
        var broadcastMessage = true
        var serverConnectionLost = true
        var userJoinedChannel = true
        var userLeftChannel = true
        var voiceActivationTriggered = true
        var transmitReady = true
        var userLoggedIn = false
        var userLoggedOut = false
        var fileTransferComplete = true
        var fileAddedOrRemoved = true
    }

    struct SoundDevice {
        var speakerOutput = false
        var voicePreprocessing = false
        var bluetoothA2DP = false
    }

    struct TextToSpeechEvents {
        var userLoggedIn = false
        var userLoggedOut = false
        var userJoinedChannel = true
        var userLeftChannel = true
        var connectionLost = true
        var privateTextMessage = false
        var channelTextMessage = false
        var voiceIdentifier: String?
        var voiceLanguage: String?
    }

    struct ServerListFilters {
        var showOfficialServers = true
        var showPublicServers = true
        var showUnofficialServers = false
    }

    struct WebLogin {
        var bearwareID: String?
        var bearwareToken: String?
    }

    var general = General()
    var display = Display()
    var sound = Sound()
    var textToSpeech = TextToSpeech()
    var connection = Connection()
    var soundEvents = SoundEvents()
    var soundDevice = SoundDevice()
    var textToSpeechEvents = TextToSpeechEvents()
    var serverListFilters = ServerListFilters()
    var webLogin = WebLogin()
    var defaultSubscriptions: TeamTalkSubscriptions = .customMessages

    // Fresh, on-demand read of every key, for call sites that don't hold a
    // long-lived PreferencesModel (free functions, other model classes).
    static var current: Preferences {
        loaded()
    }

    // Only PreferencesModel (which holds a session) ever needs the two live-SDK
    // fields below populated accurately; every other call site reads a section
    // that comes straight from UserDefaults, so `session` defaults to nil and
    // those fields stay at the struct's own defaults (0.0) rather than forcing
    // a session through 25+ unrelated call sites across the app.
    static func loaded(session: TeamTalkSession? = nil) -> Preferences {
        let settings = UserDefaults.standard
        var preferences = Preferences()

        preferences.general.nickname = settings.string(forKey: PREF_GENERAL_NICKNAME) ?? ""
        preferences.general.genderIndex = settings.integer(forKey: PREF_GENERAL_GENDER)
        preferences.general.pushToTalkLock = settings.object(forKey: PREF_GENERAL_PTTLOCK) != nil && settings.bool(forKey: PREF_GENERAL_PTTLOCK)
        preferences.general.headsetTXToggle = settings.object(forKey: PREF_HEADSET_TXTOGGLE) != nil && settings.bool(forKey: PREF_HEADSET_TXTOGGLE)
        preferences.general.sendOnReturn = settings.object(forKey: PREF_GENERAL_SENDONRETURN) == nil || settings.bool(forKey: PREF_GENERAL_SENDONRETURN)

        preferences.display.proximitySensor = settings.object(forKey: PREF_DISPLAY_PROXIMITY) != nil && settings.bool(forKey: PREF_DISPLAY_PROXIMITY)
        preferences.display.popupTextMessages = settings.object(forKey: PREF_DISPLAY_POPUPTXTMSG) == nil || settings.bool(forKey: PREF_DISPLAY_POPUPTXTMSG)
        preferences.display.limitText = Double(settings.object(forKey: PREF_DISPLAY_LIMITTEXT) == nil ? DEFAULT_LIMIT_TEXT : settings.integer(forKey: PREF_DISPLAY_LIMITTEXT))
        preferences.display.showUsername = settings.object(forKey: PREF_DISPLAY_SHOWUSERNAME) != nil && settings.bool(forKey: PREF_DISPLAY_SHOWUSERNAME)
        preferences.display.channelSortIndex = settings.object(forKey: PREF_DISPLAY_SORTCHANNELS) == nil ? ChanSort.ASCENDING.rawValue : settings.integer(forKey: PREF_DISPLAY_SORTCHANNELS)

        if let session {
            preferences.sound.masterVolumePercent = Double(refVolumeToPercent(Int(session.soundOutputVolume)))
        }
        var mediaVolume = DEFAULT_MEDIAFILE_VOLUME
        if settings.value(forKey: PREF_MEDIAFILE_VOLUME) != nil {
            mediaVolume = settings.float(forKey: PREF_MEDIAFILE_VOLUME)
        }
        preferences.sound.mediaFileVolumePercent = Double(mediaVolume * 100)
        if let session {
            preferences.sound.microphoneGainPercent = Double(refVolumeToPercent(Int(session.soundInputGainLevel)))
        }
        var voiceActivation = VOICEACT_DISABLED
        if settings.object(forKey: PREF_VOICEACTIVATION) != nil {
            voiceActivation = settings.integer(forKey: PREF_VOICEACTIVATION)
        }
        preferences.sound.voiceActivationLevel = Double(voiceActivation)

        var storedTTSRate = AVSpeechUtteranceDefaultSpeechRate
        if settings.value(forKey: PREF_TTSEVENT_RATE) != nil {
            storedTTSRate = settings.float(forKey: PREF_TTSEVENT_RATE)
        }
        preferences.textToSpeech.rate = Double(storedTTSRate)
        var storedTTSVolume = DEFAULT_TTS_VOL
        if settings.value(forKey: PREF_TTSEVENT_VOL) != nil {
            storedTTSVolume = settings.float(forKey: PREF_TTSEVENT_VOL)
        }
        preferences.textToSpeech.volume = Double(storedTTSVolume)

        preferences.connection.joinRootChannel = settings.object(forKey: PREF_JOINROOTCHANNEL) == nil || settings.bool(forKey: PREF_JOINROOTCHANNEL)

        preferences.soundEvents.voiceTransmission = settings.object(forKey: PREF_SNDEVENT_VOICETX) == nil || settings.bool(forKey: PREF_SNDEVENT_VOICETX)
        preferences.soundEvents.channelMessage = settings.object(forKey: PREF_SNDEVENT_CHANMSG) == nil || settings.bool(forKey: PREF_SNDEVENT_CHANMSG)
        preferences.soundEvents.userMessage = settings.object(forKey: PREF_SNDEVENT_USERMSG) == nil || settings.bool(forKey: PREF_SNDEVENT_USERMSG)
        preferences.soundEvents.broadcastMessage = settings.object(forKey: PREF_SNDEVENT_BCASTMSG) == nil || settings.bool(forKey: PREF_SNDEVENT_BCASTMSG)
        preferences.soundEvents.serverConnectionLost = settings.object(forKey: PREF_SNDEVENT_SERVERLOST) == nil || settings.bool(forKey: PREF_SNDEVENT_SERVERLOST)
        preferences.soundEvents.userJoinedChannel = settings.object(forKey: PREF_SNDEVENT_JOINEDCHAN) == nil || settings.bool(forKey: PREF_SNDEVENT_JOINEDCHAN)
        preferences.soundEvents.userLeftChannel = settings.object(forKey: PREF_SNDEVENT_LEFTCHAN) == nil || settings.bool(forKey: PREF_SNDEVENT_LEFTCHAN)
        preferences.soundEvents.voiceActivationTriggered = settings.object(forKey: PREF_SNDEVENT_VOXTRIGGER) == nil || settings.bool(forKey: PREF_SNDEVENT_VOXTRIGGER)
        preferences.soundEvents.transmitReady = settings.object(forKey: PREF_SNDEVENT_TRANSMITREADY) == nil || settings.bool(forKey: PREF_SNDEVENT_TRANSMITREADY)
        preferences.soundEvents.userLoggedIn = settings.object(forKey: PREF_SNDEVENT_LOGGEDIN) != nil && settings.bool(forKey: PREF_SNDEVENT_LOGGEDIN)
        preferences.soundEvents.userLoggedOut = settings.object(forKey: PREF_SNDEVENT_LOGGEDOUT) != nil && settings.bool(forKey: PREF_SNDEVENT_LOGGEDOUT)
        preferences.soundEvents.fileTransferComplete = settings.object(forKey: PREF_SNDEVENT_FILECOMPLETE) != nil && settings.bool(forKey: PREF_SNDEVENT_FILECOMPLETE)
        preferences.soundEvents.fileAddedOrRemoved = settings.object(forKey: PREF_SNDEVENT_FILEUPDATE) != nil && settings.bool(forKey: PREF_SNDEVENT_FILEUPDATE)

        preferences.soundDevice.speakerOutput = settings.object(forKey: PREF_SPEAKER_OUTPUT) != nil && settings.bool(forKey: PREF_SPEAKER_OUTPUT)
        preferences.soundDevice.voicePreprocessing = settings.object(forKey: PREF_VOICEPROCESSINGIO) != nil && settings.bool(forKey: PREF_VOICEPROCESSINGIO)
        preferences.soundDevice.bluetoothA2DP = settings.object(forKey: PREF_BLUETOOTH_A2DP) != nil && settings.bool(forKey: PREF_BLUETOOTH_A2DP)

        preferences.textToSpeechEvents.userLoggedIn = settings.object(forKey: PREF_TTSEVENT_USERLOGIN) != nil && settings.bool(forKey: PREF_TTSEVENT_USERLOGIN)
        preferences.textToSpeechEvents.userLoggedOut = settings.object(forKey: PREF_TTSEVENT_USERLOGOUT) != nil && settings.bool(forKey: PREF_TTSEVENT_USERLOGOUT)
        preferences.textToSpeechEvents.userJoinedChannel = settings.object(forKey: PREF_TTSEVENT_JOINEDCHAN) == nil || settings.bool(forKey: PREF_TTSEVENT_JOINEDCHAN)
        preferences.textToSpeechEvents.userLeftChannel = settings.object(forKey: PREF_TTSEVENT_LEFTCHAN) == nil || settings.bool(forKey: PREF_TTSEVENT_LEFTCHAN)
        preferences.textToSpeechEvents.connectionLost = settings.object(forKey: PREF_TTSEVENT_CONLOST) == nil || settings.bool(forKey: PREF_TTSEVENT_CONLOST)
        preferences.textToSpeechEvents.privateTextMessage = settings.object(forKey: PREF_TTSEVENT_TEXTMSG) != nil && settings.bool(forKey: PREF_TTSEVENT_TEXTMSG)
        preferences.textToSpeechEvents.channelTextMessage = settings.object(forKey: PREF_TTSEVENT_CHANTEXTMSG) != nil && settings.bool(forKey: PREF_TTSEVENT_CHANTEXTMSG)
        preferences.textToSpeechEvents.voiceIdentifier = settings.string(forKey: PREF_TTSEVENT_VOICEID)
        preferences.textToSpeechEvents.voiceLanguage = settings.string(forKey: PREF_TTSEVENT_VOICELANG)

        preferences.serverListFilters.showOfficialServers = settings.object(forKey: PREF_DISPLAY_OFFICIALSERVERS) == nil || settings.bool(forKey: PREF_DISPLAY_OFFICIALSERVERS)
        preferences.serverListFilters.showPublicServers = settings.object(forKey: PREF_DISPLAY_PUBLICSERVERS) == nil || settings.bool(forKey: PREF_DISPLAY_PUBLICSERVERS)
        preferences.serverListFilters.showUnofficialServers = settings.object(forKey: PREF_DISPLAY_UNOFFICIALSERVERS) != nil && settings.bool(forKey: PREF_DISPLAY_UNOFFICIALSERVERS)

        preferences.webLogin.bearwareID = settings.string(forKey: PREF_GENERAL_BEARWARE_ID)
        preferences.webLogin.bearwareToken = settings.string(forKey: PREF_GENERAL_BEARWARE_TOKEN)

        preferences.defaultSubscriptions = getDefaultSubscriptions()

        return preferences
    }
}

let PREF_GENERAL_NICKNAME = "nickname_preference"
let PREF_GENERAL_GENDER = "gender_preference"
let PREF_GENERAL_BEARWARE_ID = "general_bearwareid_preference"
let PREF_GENERAL_BEARWARE_TOKEN = "general_bearwaretoken_preference"
let PREF_GENERAL_PTTLOCK = "general_pttlock_preference"
let PREF_GENERAL_SENDONRETURN = "general_sendonreturn_preference"
let PREF_JOINROOTCHANNEL = "joinroot_preference"

let PREF_DISPLAY_SHOWUSERNAME = "display_showusername_preference"
let PREF_DISPLAY_PROXIMITY = "display_proximity_sensor"
let PREF_DISPLAY_POPUPTXTMSG = "display_popuptxtmsg_preference"
let PREF_DISPLAY_LIMITTEXT = "display_limittext_preference"
let PREF_DISPLAY_SORTCHANNELS = "display_sortchannels_preference"
let PREF_DISPLAY_OFFICIALSERVERS = "display_officialservers_preference"
let PREF_DISPLAY_PUBLICSERVERS = "display_publicservers_preference"
let PREF_DISPLAY_UNOFFICIALSERVERS = "display_unofficialservers_preference"

let PREF_MASTER_VOLUME = "mastervolume_preference"
let PREF_MICROPHONE_GAIN = "microphonegain_preference"
let PREF_SPEAKER_OUTPUT = "speakeroutput_preference"
let PREF_BLUETOOTH_A2DP = "bluetooth_a2dp_preference"
let PREF_VOICEACTIVATION = "voiceactivationlevel_preference"
let PREF_MEDIAFILE_VOLUME = "mediafile_volume_preference"
let PREF_HEADSET_TXTOGGLE = "headset_tx_preference"
let PREF_VOICEPROCESSINGIO = "voiceprocessing_preference"
let PREF_SNDINPUT_PORT = "sndinput_port_preference"

let PREF_SNDEVENT_SERVERLOST = "snd_srvlost_preference"
let PREF_SNDEVENT_VOICETX = "snd_voicetx_preference"
let PREF_SNDEVENT_CHANMSG = "snd_chanmsg_preference"
let PREF_SNDEVENT_USERMSG = "snd_usermsg_preference"
let PREF_SNDEVENT_BCASTMSG = "snd_bcastmsg_preference"
let PREF_SNDEVENT_JOINEDCHAN = "snd_joinedchan_preference"
let PREF_SNDEVENT_LEFTCHAN = "snd_leftchan_preference"
let PREF_SNDEVENT_VOXTRIGGER = "snd_vox_triggered_preference"
let PREF_SNDEVENT_TRANSMITREADY = "snd_transmitready_preference"
let PREF_SNDEVENT_LOGGEDIN = "snd_loggedin_preference"
let PREF_SNDEVENT_LOGGEDOUT = "snd_loggedout_preference"
let PREF_SNDEVENT_FILEUPDATE = "snd_fileupdate_preference"
let PREF_SNDEVENT_FILECOMPLETE="snd_filetx_complete_preference"

let PREF_SUB_USERMSG = "sub_usertextmsg_preference"
let PREF_SUB_CHANMSG = "sub_chantextmsg_preference"
let PREF_SUB_BROADCAST = "sub_broadcastmsg_preference"
let PREF_SUB_VOICE = "sub_voice_preference"
let PREF_SUB_VIDEOCAP = "sub_videocapture_preference"
let PREF_SUB_MEDIAFILE = "sub_mediafile_preference"
let PREF_SUB_DESKTOP = "sub_desktop_preference"
let PREF_SUB_DESKTOPINPUT = "sub_desktopinput_preference"

let DEFAULT_SUBSCRIPTION_USERMSG = true
let DEFAULT_SUBSCRIPTION_CHANMSG = true
let DEFAULT_SUBSCRIPTION_BCASTMSG = true
let DEFAULT_SUBSCRIPTION_VOICE = true
let DEFAULT_SUBSCRIPTION_VIDEOCAP = true
let DEFAULT_SUBSCRIPTION_MEDIAFILE = true
let DEFAULT_SUBSCRIPTION_DESKTOP = true
let DEFAULT_SUBSCRIPTION_DESKTOPINPUT = false

func getDefaultSubscriptions() -> TeamTalkSubscriptions {
    let settings = UserDefaults.standard

    var sub_usermsg = DEFAULT_SUBSCRIPTION_USERMSG
    if settings.object(forKey: PREF_SUB_USERMSG) != nil {
        sub_usermsg = settings.bool(forKey: PREF_SUB_USERMSG)
    }
    var sub_chanmsg = DEFAULT_SUBSCRIPTION_CHANMSG
    if settings.object(forKey: PREF_SUB_CHANMSG) != nil {
        sub_chanmsg = settings.bool(forKey: PREF_SUB_CHANMSG)
    }
    var sub_bcastmsg = DEFAULT_SUBSCRIPTION_BCASTMSG
    if settings.object(forKey: PREF_SUB_BROADCAST) != nil {
        sub_bcastmsg = settings.bool(forKey: PREF_SUB_BROADCAST)
    }
    var sub_voice = DEFAULT_SUBSCRIPTION_VOICE
    if settings.object(forKey: PREF_SUB_VOICE) != nil {
        sub_voice = settings.bool(forKey: PREF_SUB_VOICE)
    }
    var sub_vidcap = DEFAULT_SUBSCRIPTION_VIDEOCAP
    if settings.object(forKey: PREF_SUB_VIDEOCAP) != nil {
        sub_vidcap = settings.bool(forKey: PREF_SUB_VIDEOCAP)
    }
    var sub_mediafile = DEFAULT_SUBSCRIPTION_MEDIAFILE
    if settings.object(forKey: PREF_SUB_MEDIAFILE) != nil {
        sub_mediafile = settings.bool(forKey: PREF_SUB_MEDIAFILE)
    }
    var sub_desktop = DEFAULT_SUBSCRIPTION_DESKTOP
    if settings.object(forKey: PREF_SUB_DESKTOP) != nil {
        sub_desktop = settings.bool(forKey: PREF_SUB_DESKTOP)
    }
    var sub_deskinput = DEFAULT_SUBSCRIPTION_DESKTOPINPUT
    if settings.object(forKey: PREF_SUB_DESKTOPINPUT) != nil {
        sub_deskinput = settings.bool(forKey: PREF_SUB_DESKTOPINPUT)
    }

    var subs: TeamTalkSubscriptions = .customMessages
    if sub_usermsg {
        subs.insert(.userMessages)
    }
    if sub_chanmsg {
        subs.insert(.channelMessages)
    }
    if sub_bcastmsg {
        subs.insert(.broadcastMessages)
    }
    if sub_voice {
        subs.insert(.voice)
    }
    if sub_vidcap {
        subs.insert(.videoCapture)
    }
    if sub_mediafile {
        subs.insert(.mediaFile)
    }
    if sub_desktop {
        subs.insert(.desktop)
    }
    if sub_deskinput {
        subs.insert(.desktopInput)
    }

    return subs
}

let MAX_TEXTMESSAGES = 100
let VOICEACT_DISABLED = 21 // one past the real max voice activation level (SOUND_VU_MAX = 20)
let DEFAULT_VOICEACT = 2
let DEFAULT_MEDIAFILE_VOLUME: Float = 0.5
let DEFAULT_LIMIT_TEXT = 25

let PREF_TTSEVENT_VOICEID = "tts_voiceid_preference"
let PREF_TTSEVENT_VOICELANG = "tts_voicelang_preference"
let PREF_TTSEVENT_JOINEDCHAN = "tts_joinedchan_preference"
let PREF_TTSEVENT_LEFTCHAN = "tts_leftchan_preference"
let PREF_TTSEVENT_CONLOST = "tts_conlost_preference"
let PREF_TTSEVENT_TEXTMSG = "tts_usertxtmsg_preference"
let PREF_TTSEVENT_CHANTEXTMSG = "tts_chantxtmsg_preference"
let PREF_TTSEVENT_RATE = "tts_rate_preference"
let PREF_TTSEVENT_VOL = "tts_volume_preference"
let PREF_TTSEVENT_USERLOGIN = "tts_user_login"
let PREF_TTSEVENT_USERLOGOUT = "tts_user_logout"

@Observable
final class PreferencesModel {

    struct SubscriptionRow: Identifiable {
        let title: String
        let subtitle: String
        let type: TeamTalkSubscriptions
        let key: String

        var id: String {
            key
        }
    }

    struct VersionRow: Identifiable {
        let title: String
        let value: String

        var id: String {
            title
        }
    }

    let session: TeamTalkSession

    var preferences: Preferences

    var users = Set<INT32>()

    let subscriptionRows: [SubscriptionRow]
    let versionRows: [VersionRow]

    init(session: TeamTalkSession) {
        self.session = session
        preferences = Preferences.loaded(session: session)
        subscriptionRows = [
            SubscriptionRow(title: String(localized: "User Messages", comment: "preferences"), subtitle: String(localized: "Receive text messages by default", comment: "preferences"), type: .userMessages, key: PREF_SUB_USERMSG),
            SubscriptionRow(title: String(localized: "Channel Messages", comment: "preferences"), subtitle: String(localized: "Receive channel messages by default", comment: "preferences"), type: .channelMessages, key: PREF_SUB_CHANMSG),
            SubscriptionRow(title: String(localized: "Broadcast Messages", comment: "preferences"), subtitle: String(localized: "Receive broadcast messages by default", comment: "preferences"), type: .broadcastMessages, key: PREF_SUB_BROADCAST),
            SubscriptionRow(title: String(localized: "Voice", comment: "preferences"), subtitle: String(localized: "Receive voice streams by default", comment: "preferences"), type: .voice, key: PREF_SUB_VOICE),
            SubscriptionRow(title: String(localized: "WebCam", comment: "preferences"), subtitle: String(localized: "Receive webcam streams by default", comment: "preferences"), type: .videoCapture, key: PREF_SUB_VIDEOCAP),
            SubscriptionRow(title: String(localized: "Media File", comment: "preferences"), subtitle: String(localized: "Receive media file streams by default", comment: "preferences"), type: .mediaFile, key: PREF_SUB_MEDIAFILE),
            SubscriptionRow(title: String(localized: "Desktop", comment: "preferences"), subtitle: String(localized: "Receive desktop sessions by default", comment: "preferences"), type: .desktop, key: PREF_SUB_DESKTOP)
        ]

        let version = session.version
        versionRows = [
            VersionRow(
                title: String(localized: "Translator", comment: "preferences"),
                value: String(localized: "Bjoern D. Rasmussen, contact@bearware.dk", comment: "preferences")
            ),
            VersionRow(
                title: String(localized: "App Version", comment: "preferences"),
                value: "\(AppInfo.getAppName()) v\(AppInfo.getAppVersionLong()), Library v\(version)"
            )
        ]
    }

    var nickname: String {
        get { preferences.general.nickname }
        set {
            preferences.general.nickname = newValue
            session.setNickname(newValue)
            UserDefaults.standard.set(newValue, forKey: PREF_GENERAL_NICKNAME)
        }
    }

    var genderIndex: Int {
        get { preferences.general.genderIndex }
        set {
            preferences.general.genderIndex = newValue
            UserDefaults.standard.set(newValue, forKey: PREF_GENERAL_GENDER)

            let mode: TeamTalkStatusMode = newValue != 0 ? .female : .available
            session.setStatus(mode: mode)
        }
    }

    var pushToTalkLock: Bool {
        get { preferences.general.pushToTalkLock }
        set {
            preferences.general.pushToTalkLock = newValue
            UserDefaults.standard.set(newValue, forKey: PREF_GENERAL_PTTLOCK)
        }
    }

    var sendOnReturn: Bool {
        get { preferences.general.sendOnReturn }
        set {
            preferences.general.sendOnReturn = newValue
            UserDefaults.standard.set(newValue, forKey: PREF_GENERAL_SENDONRETURN)
        }
    }

    var headsetTXToggle: Bool {
        get { preferences.general.headsetTXToggle }
        set {
            preferences.general.headsetTXToggle = newValue
            UserDefaults.standard.set(newValue, forKey: PREF_HEADSET_TXTOGGLE)

            if newValue {
                UIApplication.shared.beginReceivingRemoteControlEvents()
            } else {
                UIApplication.shared.endReceivingRemoteControlEvents()
            }

            setupSoundDevices(session: session)
        }
    }

    var popupTextMessages: Bool {
        get { preferences.display.popupTextMessages }
        set {
            preferences.display.popupTextMessages = newValue
            UserDefaults.standard.set(newValue, forKey: PREF_DISPLAY_POPUPTXTMSG)
        }
    }

    var proximitySensor: Bool {
        get { preferences.display.proximitySensor }
        set {
            preferences.display.proximitySensor = newValue
            UserDefaults.standard.set(newValue, forKey: PREF_DISPLAY_PROXIMITY)
            UIDevice.current.isProximityMonitoringEnabled = newValue
        }
    }

    var limitText: Double {
        get { preferences.display.limitText }
        set {
            preferences.display.limitText = newValue
            UserDefaults.standard.set(Int(newValue), forKey: PREF_DISPLAY_LIMITTEXT)
        }
    }

    var showUsername: Bool {
        get { preferences.display.showUsername }
        set {
            preferences.display.showUsername = newValue
            UserDefaults.standard.set(newValue, forKey: PREF_DISPLAY_SHOWUSERNAME)
        }
    }

    var channelSortIndex: Int {
        get { preferences.display.channelSortIndex }
        set {
            preferences.display.channelSortIndex = newValue
            UserDefaults.standard.set(newValue == 0 ? ChanSort.ASCENDING.rawValue : ChanSort.POPULARITY.rawValue, forKey: PREF_DISPLAY_SORTCHANNELS)
        }
    }

    var joinRootChannel: Bool {
        get { preferences.connection.joinRootChannel }
        set {
            preferences.connection.joinRootChannel = newValue
            UserDefaults.standard.set(newValue, forKey: PREF_JOINROOTCHANNEL)
        }
    }

    var masterVolumePercent: Double {
        get { preferences.sound.masterVolumePercent }
        set {
            let roundedPercent = Double(Int(newValue / 10.0) * 10)
            preferences.sound.masterVolumePercent = roundedPercent
            let vol = refVolume(roundedPercent)
            session.setSoundOutputVolume(INT32(vol))
            UserDefaults.standard.set(Int(roundedPercent), forKey: PREF_MASTER_VOLUME)
        }
    }

    var mediaFileVolumePercent: Double {
        get { preferences.sound.mediaFileVolumePercent }
        set {
            preferences.sound.mediaFileVolumePercent = newValue
            let normalized = Float(newValue / 100.0)
            UserDefaults.standard.set(normalized, forKey: PREF_MEDIAFILE_VOLUME)

            let vol = refVolume(newValue)
            for userID in users {
                if let user = session.user(id: TeamTalkUserID(userID)) {
                    session.setUserVolume(user, stream: .mediaFileAudio, volume: INT32(vol))
                }
            }
        }
    }

    var microphoneGainPercent: Double {
        get { preferences.sound.microphoneGainPercent }
        set {
            let roundedPercent = Double(Int(newValue / 10.0) * 10)
            preferences.sound.microphoneGainPercent = roundedPercent
            let vol = refVolume(roundedPercent)
            session.setSoundInputGainLevel(INT32(vol))
            UserDefaults.standard.set(Int(roundedPercent), forKey: PREF_MICROPHONE_GAIN)
        }
    }

    var voiceActivationLevel: Double {
        get { preferences.sound.voiceActivationLevel }
        set {
            let level = Int(newValue)
            preferences.sound.voiceActivationLevel = Double(level)

            if level == VOICEACT_DISABLED {
                session.enableVoiceActivation(false)
            } else {
                session.enableVoiceActivation(true)
                session.setVoiceActivationLevel(INT32(level))
            }
            UserDefaults.standard.set(level, forKey: PREF_VOICEACTIVATION)
        }
    }

    var ttsRate: Double {
        get { preferences.textToSpeech.rate }
        set {
            preferences.textToSpeech.rate = newValue
            UserDefaults.standard.set(Float(newValue), forKey: PREF_TTSEVENT_RATE)
        }
    }

    var ttsVolume: Double {
        get { preferences.textToSpeech.volume }
        set {
            preferences.textToSpeech.volume = newValue
            UserDefaults.standard.set(Float(newValue), forKey: PREF_TTSEVENT_VOL)
        }
    }

    func isSubscribed(to row: SubscriptionRow) -> Bool {
        preferences.defaultSubscriptions.contains(row.type)
    }

    func subscriptionBinding(for row: SubscriptionRow) -> Binding<Bool> {
        Binding(
            get: { self.isSubscribed(to: row) },
            set: { enabled in
                if enabled {
                    self.preferences.defaultSubscriptions.insert(row.type)
                } else {
                    self.preferences.defaultSubscriptions.remove(row.type)
                }
                UserDefaults.standard.set(enabled, forKey: row.key)
            }
        )
    }

    func percentText(_ value: Double) -> String {
        let percent = Int(value.rounded())
        let vol = refVolume(Double(percent))
        if UInt32(vol) == SOUND_VOLUME_DEFAULT.rawValue {
            return String(format: String(localized: "%d %% - Default", comment: "preferences"), percent)
        }
        return "\(percent) %"
    }

    func voiceActivationValueText(_ value: Double) -> String {
        let level = Int(value.rounded())
        if level == VOICEACT_DISABLED {
            return String(localized: "Disabled", comment: "preferences")
        }
        return "\(level)"
    }
}

extension PreferencesModel: TeamTalkEventObserver {
    func handleTeamTalkEvent(_ event: TeamTalkEvent) {
        switch event.kind {
        case .userJoined(let user):
            users.insert(user.userID.cValue)
        case .userLeft(_, let user):
            users.remove(user.userID.cValue)
        default:
            break
        }
    }
}
