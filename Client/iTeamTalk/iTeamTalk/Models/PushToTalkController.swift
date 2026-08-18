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

// Push-to-talk button state and voice transmission toggling, split out of
// ChannelListModel.
@Observable
final class PushToTalkController {
    weak var owner: ChannelListModel?
    let session: TeamTalkSession

    var isTransmitting = false
    var pttHint = String(localized: "Toggle to enable/disable transmission", comment: "channel list")
    private var pttLockTimeout = Date()

    init(session: TeamTalkSession) {
        self.session = session
    }

    func txBtnDown() {
        if hasPTTLock() {
            enableVoiceTx(true)
        } else {
            enableVoiceTx(!session.isVoiceTransmitting)
        }
    }

    func enableVoiceTx(_ enable: Bool) {
        session.enableVoiceTransmission(enable)
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
        enableVoiceTx(!session.isVoiceTransmitting)
    }

    func updateTX() {
        isTransmitting = session.isVoiceTransmitting
        pttHint = hasPTTLock()
            ? String(localized: "Double tap and hold to transmit. Triple tap fast to lock transmission.", comment: "channel list")
            : String(localized: "Toggle to enable/disable transmission", comment: "channel list")
        owner?.refreshChannelList()
    }
}
