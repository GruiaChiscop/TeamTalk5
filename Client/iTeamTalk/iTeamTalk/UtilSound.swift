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

import Foundation
import AVFoundation
import TeamTalkKit

func refVolume(_ percent: Double) -> Int {
    //82.832*EXP(0.0508*x) - 50
    if percent == 0 {
        return 0
    }
    
    let d = 82.832 * exp(0.0508 * percent) - 50
    return Int(d)
}

func refVolumeToPercent(_ volume: Int) -> Int {
    if(volume == 0) {
        return 0
    }
    
    let d = (Double(volume) + 50.0) / 82.832
    let d1 = (log(d) / 0.0508) + 0.5
    return Int(d1)
}

enum Sounds : Int {
    case tx_ON = 1,
         tx_OFF = 2,
         chan_MSG = 3,
         broadcast_MSG = 4,
         user_MSG = 5,
         srv_LOST = 6,
         joined_CHAN = 7,
         left_CHAN = 8,
         voxtriggered_ON = 9,
         voxtriggered_OFF = 10,
         transmit_ON = 11,
         transmit_OFF = 12,
         logged_IN = 13,
         logged_OUT = 14,
    file_UPDATE=15,
    file_COMPLETE=16
}

var player : AVAudioPlayer?

func getSoundFile(_ s: Sounds) -> String? {

    let events = Preferences.current.soundEvents

    switch s {
    case .tx_ON:
        if events.voiceTransmission { return "on.mp3" }
    case .tx_OFF:
        if events.voiceTransmission { return "off.mp3" }
    case .chan_MSG:
        if events.channelMessage { return "channel_message.mp3" }
    case .user_MSG:
        if events.userMessage { return "user_message.mp3" }
    case .broadcast_MSG:
        if events.broadcastMessage { return "broadcast_message.mp3" }
    case .srv_LOST:
        if events.serverConnectionLost { return "serverlost.mp3" }
    case .joined_CHAN:
        if events.userJoinedChannel { return "newuser.mp3" }
    case .left_CHAN:
        if events.userLeftChannel { return "removeuser.mp3" }
    case .voxtriggered_ON:
        if events.voiceActivationTriggered { return "voiceact_on.mp3" }
    case .voxtriggered_OFF:
        if events.voiceActivationTriggered { return "voiceact_off.mp3" }
    case .transmit_ON:
        if events.transmitReady { return "txqueue_start.mp3" }
    case .transmit_OFF:
        if events.transmitReady { return "txqueue_stop.mp3" }
    case .logged_IN:
        if events.userLoggedIn { return "logged_on.mp3" }
    case .logged_OUT:
        if events.userLoggedOut { return "logged_off.mp3" }
    case .file_COMPLETE:
        if events.fileTransferComplete { return "filetx_complete.wav" }
    case .file_UPDATE:
        if events.fileAddedOrRemoved { return "fileupdate.wav" }
    }

    return nil
}

func getCategory(_ opt: AVAudioSession.CategoryOptions) -> String {
    var str = ""
    if opt.contains(.defaultToSpeaker) {
        str += "defaultToSpeaker|"
    }
    if opt.contains(.mixWithOthers) {
        str += "mixWithOthers|"
    }
    if opt.contains(.allowBluetoothHFP) {
        str += "allowBluetoothHFP|"
    }
    if opt.contains(.duckOthers) {
        str += "duckOthers|"
    }
    if opt.contains(.interruptSpokenAudioAndMixWithOthers) {
        str += "interruptSpokenAudioAndMixWithOthers|"
    }
    if opt.contains(.overrideMutedMicrophoneInterruption) {
        str += "overrideMutedMicrophoneInterruption|"
    }
    if opt.contains(.allowAirPlay) {
        str += "allowAirPlay|"
    }
    if opt.contains(.allowBluetoothA2DP) {
        str += "allowBluetoothA2DP|"
    }
    return str
}

// Keyed per hardware device UID, so this can't be a fixed field on Preferences.
func getAudioPortDataSource(descr: AVAudioSessionPortDescription) -> NSNumber? {
    let defaults = UserDefaults.standard
    let prefname = PREF_SNDINPUT_PORT + "_" + descr.uid
    if let id = defaults.object(forKey: prefname) as? NSNumber {
        return id
    }
    return nil
}

func setAudioPortDataSource(descr: AVAudioSessionPortDescription, dsrc: AVAudioSessionDataSourceDescription) {
    let defaults = UserDefaults.standard
    let prefname = PREF_SNDINPUT_PORT + "_" + descr.uid
    defaults.set(dsrc.dataSourceID, forKey: prefname)
}

func removeAudioPortDataSource(descr: AVAudioSessionPortDescription) {
    let defaults = UserDefaults.standard
    let prefname = PREF_SNDINPUT_PORT + "_" + descr.uid
    defaults.removeObject(forKey: prefname)
}

// Which input port to prefer even when it has no specific data source chosen
// (i.e. "Default" was picked for it) - a per-port data source preference alone
// doesn't say which of several available *ports* should be active.
func getPreferredInputUID() -> String? {
    UserDefaults.standard.string(forKey: PREF_SNDINPUT_UID)
}

func setPreferredInputUID(_ uid: String) {
    UserDefaults.standard.set(uid, forKey: PREF_SNDINPUT_UID)
}

func closeSoundDevices(session: TeamTalkSession) {
    session.closeSoundDevices()
}

func setupSoundDevices(session: TeamTalkSession) {
    // The native SDK's own mic-permission request is broken (wrong ObjC selector,
    // so it never fires), and initializing the sound input device while the OS
    // permission prompt is still unresolved leaves the input Audio Unit capturing
    // silence even after the user grants access. Resolve permission here first.
    switch AVAudioApplication.shared.recordPermission {
    case .undetermined:
        AVAudioApplication.requestRecordPermission { _ in
            DispatchQueue.main.async {
                performSoundDeviceSetup(session: session)
            }
        }
    default:
        performSoundDeviceSetup(session: session)
    }
}

private func performSoundDeviceSetup(session: TeamTalkSession) {

    do {
        closeSoundDevices(session: session)

        let audioSession = AVAudioSession.sharedInstance()

        print("preset: " + audioSession.mode.rawValue)

        let preferences = Preferences.current
        let speaker = preferences.soundDevice.speakerOutput
        let preprocess = preferences.soundDevice.voicePreprocessing
        let a2dp = preferences.soundDevice.bluetoothA2DP
        let headsettoggle = preferences.general.headsetTXToggle

        // In 'voiceChat' mode stereo cannot be enabled on input devices.
        try audioSession.setMode(preprocess ? .voiceChat : .default)

        var catoptions : AVAudioSession.CategoryOptions
        
        // Toggling 'speaker' on iPad has no effect since it can only output to speaker.
        // When Bluetooth headset is connected to iPad then toggling 'speaker' will have
        // no effect. However, on iPhone toggling 'speaker' has the desired effect both
        // when switching output from Receiver and Bluetooth to 'speaker'.
        if speaker {
            catoptions = [ .defaultToSpeaker ]
        } else {
            catoptions = [ .allowBluetoothHFP, .allowAirPlay, .allowBluetoothA2DP ]
            if #available(iOS 26.0, *) {
                catoptions.update(with: .bluetoothHighQualityRecording)
            }
            if a2dp {
                catoptions.remove(.allowBluetoothHFP)
            }
        }
        // headset notifications, UIApplication.shared.beginReceivingRemoteControlEvents(),
        // will be ignored with .mixWithOthers
        if headsettoggle == false {
            catoptions.update(with: .mixWithOthers)
        }
        
        try audioSession.setCategory(.playAndRecord, options: catoptions)

        // Note that Voice Preprocessing IO will disable ability to select
        // stereo microphone sources
        let sndid = preprocess ? TeamTalkSoundDeviceID.voiceProcessingIO : TeamTalkSoundDeviceID.remoteIO
        if !session.initSoundInputDevice(id: sndid) {
            print("Failed to initialize sound input device: \(sndid)")
        }
        else {
            print("Using sound input device: \(sndid)")
        }
        if !session.initSoundOutputDevice(id: sndid) {
            print("Failed to initialize sound output device: \(sndid)")
        }
        else {
            print("Using sound output device: \(sndid)")
        }

        // The native SDK resets the audio session's category (without
        // .defaultToSpeaker) the first time it opens an input/output device,
        // clobbering the options set above regardless of the speaker preference.
        // Re-assert the category, then force the physical route directly -
        // overrideOutputAudioPort is independent of category options and wins
        // even if something downstream fights the category again.
        try audioSession.setCategory(.playAndRecord, options: catoptions)
        try audioSession.overrideOutputAudioPort(speaker ? .speaker : .none)

        print("postset. Mode \(audioSession.mode.rawValue), category \(audioSession.category.rawValue), options \(getCategory(audioSession.categoryOptions))")

        // Restore the previously chosen input port + data source. Only the one
        // data source matching what was saved should be applied - not whichever
        // one happened to be last in the list - and the port itself needs to be
        // made preferred too, or iOS falls back to its own default input. A port
        // chosen with no specific data source (i.e. "Default") has nothing in
        // getAudioPortDataSource, so it's matched separately, by uid.
        let preferredInputUID = getPreferredInputUID()
        for input in audioSession.availableInputs ?? [] {
            guard let dataSourceID = getAudioPortDataSource(descr: input),
                  let dataSource = input.dataSources?.first(where: { $0.dataSourceID == dataSourceID }) else {
                if input.uid == preferredInputUID {
                    try audioSession.setPreferredInput(input)
                }
                continue
            }

            if dataSource.supportedPolarPatterns?.contains(.stereo) == true {
                try dataSource.setPreferredPolarPattern(.stereo)
                print("Setting \(dataSource.dataSourceName) to stereo")
            } else {
                print("No stereo on \(dataSource.dataSourceName)")
            }
            try input.setPreferredDataSource(dataSource)
            try audioSession.setPreferredInput(input)
            try audioSession.setInputDataSource(dataSource)
        }
    }
    catch {
        print("Failed to set mode")
    }
}

func playSound(_ s: Sounds) {
    
    let filename = getSoundFile(s)
    
    if filename == nil {
        return
    }
    
    if let resPath = Bundle.main.path(forResource: filename, ofType: "") {
        
        let url = URL(fileURLWithPath: resPath)
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player!.prepareToPlay()
            player!.play()
        }
        catch {
            print("Failed to play")
        }
    }
}
