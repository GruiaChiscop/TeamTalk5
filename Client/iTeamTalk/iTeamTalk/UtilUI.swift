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

import TeamTalkKit
import UIKit
import SwiftUI

enum ChanSort : Int {
    case ASCENDING = 0
    case POPULARITY
    case COUNT
}

enum MsgType {
    case PRIV_IM
    case PRIV_IM_MYSELF
    case CHAN_IM
    case CHAN_IM_MYSELF
    case LOGMSG
    case BCAST
}

struct MyTextMessage {
    var nickname = ""
    var message : String
    var date = Date()
    var msgtype : MsgType
    var fromUserID: TeamTalkUserID = .none
    
    init(m: TextMessage, nickname: String, msgtype: MsgType) {
        message = TeamTalkString.textMessage(m)
        self.nickname = nickname
        self.msgtype = msgtype
        self.fromUserID = TeamTalkUserID(m.nFromUserID)
    }

    init(fromUserID: TeamTalkUserID, nickname: String, msgtype: MsgType, content: String) {
        self.fromUserID = fromUserID
        self.message = content
        self.nickname = nickname
        self.msgtype = msgtype
    }

    init(logmsg: String) {
        message = logmsg
        msgtype = .LOGMSG
    }
}

protocol MyTextMessageDelegate: AnyObject {
    func appendTextMessage(for userID: TeamTalkUserID, message: MyTextMessage)
}

class MyCustomAction : UIAccessibilityCustomAction {
    
    var tag = 0
    
    init(name: String, target: AnyObject?, selector: Selector, tag: Int) {
        super.init(name: name, target: target, selector: selector)
        self.tag = tag
    }
}

func hasPTTLock() -> Bool {
    Preferences.current.general.pushToTalkLock
}

func limitText(_ s: String) -> String {
    let length = Int(Preferences.current.display.limitText)

    if s.count > length {
        return String(s.prefix(length))
    }
    return s
}

func announceForAccessibility(_ message: String) {
    guard UIAccessibility.isVoiceOverRunning,
          UIApplication.shared.applicationState == .active else {
        return
    }

    UIAccessibility.post(notification: .announcement, argument: message)
}

private func getDisplayName(_ user: User) -> String {
    if Preferences.current.display.showUsername {
        return limitText(TeamTalkString.user(.username, from: user))
    }

    let nickname = TeamTalkString.user(.nickname, from: user)
    if nickname.isEmpty {
        return DEFAULT_NICKNAME + " - #\(user.nUserID)"
    }
    
    return limitText(nickname)
}

func getDisplayName(_ user: TeamTalkUser) -> String {
    getDisplayName(user.rawValue)
}


func formTextField(
    _ title: LocalizedStringKey,
    text: Binding<String>,
    keyboardType: UIKeyboardType = .default,
    disabled: Bool=false
) -> some View {
    LabeledContent {
        TextField("", text: text)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .multilineTextAlignment(.trailing)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(keyboardType)
            .disabled(disabled)
            .accessibilityLabel(Text(title))
    } label: {
        Text(title)
            .accessibilityHidden(true)
    }
}

func formPasswordField(
    _ title: LocalizedStringKey,
    text: Binding<String>,
    isRevealed: Bool=false
) -> some View {
    LabeledContent {
        Group {
            if isRevealed {
                TextField("", text: text)
                    .autocorrectionDisabled()
            } else {
                SecureField("", text: text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .multilineTextAlignment(.trailing)
        .textInputAutocapitalization(.never)
        .accessibilityLabel(Text(title))
    } label: {
        Text(title)
            .accessibilityHidden(true)
    }
}

let DEFAULT_NICKNAME = String(localized: "Noname", comment: "default nickname")

func within<T: Comparable>(_ min_v: T, max_v: T, value: T) -> T {
    if value < min_v {
        return min_v
    }
    if value > max_v {
        return max_v
    }
    return value
}

func getXMLPath(elementStack: [String]) -> String {
    var path = ""
    for s in elementStack {
        path += "/" + s
    }
    return path
}
