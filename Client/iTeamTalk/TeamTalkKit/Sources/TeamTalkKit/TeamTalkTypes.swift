import Foundation
import TeamTalkC

public struct TeamTalkCommandID: RawRepresentable, Hashable, Sendable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public init(integerLiteral value: Int32) {
        self.init(rawValue: value)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkCommandID(rawValue: 0)
    public static let invalid = TeamTalkCommandID(rawValue: -1)
}

public struct TeamTalkUserID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkUserID(rawValue: 0)
    public static let invalid = TeamTalkUserID(rawValue: -1)
}

public struct TeamTalkChannelID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkChannelID(rawValue: 0)
    public static let invalid = TeamTalkChannelID(rawValue: -1)
}

public struct TeamTalkChannelPathComponent: RawRepresentable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.replacingOccurrences(of: "/", with: "")
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }

    public var isEmpty: Bool {
        rawValue.isEmpty
    }

    public var description: String {
        rawValue
    }
}

public struct TeamTalkChannelPath: RawRepresentable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = TeamTalkChannelPath.normalize(rawValue)
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }

    public init(components: [TeamTalkChannelPathComponent]) {
        let normalized = components.map(\.rawValue).filter { !$0.isEmpty }
        if normalized.isEmpty {
            self.rawValue = "/"
        } else {
            self.rawValue = "/" + normalized.joined(separator: "/")
        }
    }

    public static let empty = TeamTalkChannelPath(rawValue: "")
    public static let root = TeamTalkChannelPath(rawValue: "/")

    public var isEmpty: Bool {
        rawValue.isEmpty
    }

    public var isRoot: Bool {
        rawValue == "/"
    }

    public var components: [TeamTalkChannelPathComponent] {
        rawValue.split(separator: "/").map { TeamTalkChannelPathComponent(String($0)) }
    }

    public var depth: Int {
        components.count
    }

    public var lastComponent: TeamTalkChannelPathComponent? {
        components.last
    }

    public var parent: TeamTalkChannelPath? {
        if isEmpty || isRoot {
            return nil
        }

        let parentComponents = Array(components.dropLast())
        return parentComponents.isEmpty ? .root : TeamTalkChannelPath(components: parentComponents)
    }

    public func appending(_ component: TeamTalkChannelPathComponent) -> TeamTalkChannelPath {
        guard !component.isEmpty else {
            return self
        }
        return TeamTalkChannelPath(components: components + [component])
    }

    public func appending(component: String) -> TeamTalkChannelPath {
        appending(TeamTalkChannelPathComponent(component))
    }

    public var description: String {
        rawValue
    }

    private static func normalize(_ rawValue: String) -> String {
        guard !rawValue.isEmpty else {
            return ""
        }

        let components = rawValue
            .split(separator: "/")
            .map { String($0).replacingOccurrences(of: "/", with: "") }
            .filter { !$0.isEmpty }

        guard !components.isEmpty else {
            return "/"
        }
        return "/" + components.joined(separator: "/")
    }
}

public struct TeamTalkFileID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkFileID(rawValue: 0)
    public static let invalid = TeamTalkFileID(rawValue: -1)
}

public struct TeamTalkTransferID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkTransferID(rawValue: 0)
    public static let invalid = TeamTalkTransferID(rawValue: -1)
}

public struct TeamTalkPlaybackSessionID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkPlaybackSessionID(rawValue: 0)
    public static let invalid = TeamTalkPlaybackSessionID(rawValue: -1)
}

public struct TeamTalkDesktopSessionID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkDesktopSessionID(rawValue: 0)
    public static let invalid = TeamTalkDesktopSessionID(rawValue: -1)
}

public struct TeamTalkMediaStreamID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isValid: Bool {
        rawValue > 0
    }

    public var description: String {
        String(rawValue)
    }

    public static let none = TeamTalkMediaStreamID(rawValue: 0)
    public static let invalid = TeamTalkMediaStreamID(rawValue: -1)
}

public struct TeamTalkAudioBlockSourceID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.init(rawValue: rawValue)
    }

    public init(userID: TeamTalkUserID) {
        self.init(rawValue: userID.rawValue)
    }

    public init(playbackSessionID: TeamTalkPlaybackSessionID) {
        self.init(rawValue: playbackSessionID.rawValue)
    }

    public var cValue: Int32 {
        rawValue
    }

    public var isSpecialSource: Bool {
        self == .localUser || self == .localTransmission || self == .muxed
    }

    public var description: String {
        String(rawValue)
    }

    public static let localUser = TeamTalkAudioBlockSourceID(rawValue: TT_LOCAL_USERID)
    public static let localTransmission = TeamTalkAudioBlockSourceID(rawValue: TT_LOCAL_TX_USERID)
    public static let muxed = TeamTalkAudioBlockSourceID(rawValue: TT_MUXED_USERID)
}
