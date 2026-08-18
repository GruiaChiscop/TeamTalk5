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
import UIKit

// initialize TTS values globally
let synth = AVSpeechSynthesizer()
var myUtterance = AVSpeechUtterance(string: "")

let DEFAULT_TTS_VOL : Float = 0.5

func newUtterance(_ utterance: String) {
    let preferences = Preferences.current
    myUtterance = AVSpeechUtterance(string: utterance)
    if UIAccessibility.isVoiceOverRunning && UIApplication.shared.applicationState == .active{
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: utterance)
        return
    }
    myUtterance.rate = Float(preferences.textToSpeech.rate)
    // Only override AVSpeechUtterance's own default volume (1.0) once the user has
    // touched the slider — Preferences.textToSpeech.volume defaults to 0.5 for
    // *display* purposes on the Preferences screen, which isn't the same thing.
    if UserDefaults.standard.value(forKey: PREF_TTSEVENT_VOL) != nil {
        myUtterance.volume = Float(preferences.textToSpeech.volume)
    }
    if let voice = preferences.textToSpeechEvents.voiceIdentifier {
        myUtterance.voice = AVSpeechSynthesisVoice(identifier: voice)
    }
    else if let lang = preferences.textToSpeechEvents.voiceLanguage {
        myUtterance.voice = AVSpeechSynthesisVoice(language: lang)
    }

    synth.speak(myUtterance)
}

func speakTextMessage(_ msgtype: TextMsgType, mymsg: MyTextMessage) {

    let events = Preferences.current.textToSpeechEvents
    let tts_priv = events.privateTextMessage && msgtype == MSGTYPE_USER
    let tts_chan = events.channelTextMessage && msgtype == MSGTYPE_CHANNEL
    
    if tts_priv {
        let ttsmsg = String(format: String(localized: "Private text message from %@. %@", comment: "TTS EVENT"),
            limitText(mymsg.nickname), mymsg.message)
        newUtterance(ttsmsg)
    }
    if tts_chan {
        let ttsmsg = String(format: String(localized: "Channel message from %@. %@", comment: "TTS EVENT"),
            limitText(mymsg.nickname), mymsg.message)
        newUtterance(ttsmsg)
    }
}
