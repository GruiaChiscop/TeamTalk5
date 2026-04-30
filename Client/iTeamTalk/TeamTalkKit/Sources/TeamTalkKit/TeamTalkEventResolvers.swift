import Foundation

public extension TeamTalkEvent.Kind {
    /// Resolves the user identifier carried by an event payload to a full `TeamTalkUser`,
    /// querying the supplied client. Returns `nil` if the event has no user identifier
    /// or the SDK no longer knows that user (e.g. they have already left).
    func resolvedUser(in client: TeamTalkClient) -> TeamTalkUser? {
        switch self {
        case .myselfLoggedIn(let id, _),
             .userVideoCapture(let id, _),
             .userMediaFileVideo(let id, _),
             .userDesktopWindow(let id, _),
             .userDesktopCursor(let id),
             .userDesktopInput(let id),
             .userRecordMediaFile(let id),
             .userAudioBlock(let id, _):
            return client.user(id: id)
        case .userLoggedIn(let user),
             .userLoggedOut(let user),
             .userUpdated(let user),
             .userJoined(let user),
             .userStateChanged(let user),
             .userLeft(_, let user):
            return user
        case .myselfKicked(_, let by):
            return by
        case .userFirstVoiceStreamPacket(_, let user):
            return user
        default:
            return nil
        }
    }

    /// Resolves the channel identifier carried by an event payload to a full `TeamTalkChannel`,
    /// querying the supplied client. Returns `nil` if the event has no channel identifier or
    /// the channel is no longer known (e.g. for `myselfKicked` after the kick has propagated).
    func resolvedChannel(in client: TeamTalkClient) -> TeamTalkChannel? {
        switch self {
        case .myselfKicked(let id, _),
             .userLeft(let id, _):
            return client.channel(id: id)
        case .channelCreated(let channel),
             .channelUpdated(let channel),
             .channelRemoved(let channel):
            return channel
        default:
            return nil
        }
    }
}

public extension TeamTalkEvent {
    /// Convenience: resolve the event's primary user (if any) using the supplied client.
    func resolvedUser(in client: TeamTalkClient) -> TeamTalkUser? {
        kind.resolvedUser(in: client)
    }

    /// Convenience: resolve the event's primary channel (if any) using the supplied client.
    func resolvedChannel(in client: TeamTalkClient) -> TeamTalkChannel? {
        kind.resolvedChannel(in: client)
    }
}
