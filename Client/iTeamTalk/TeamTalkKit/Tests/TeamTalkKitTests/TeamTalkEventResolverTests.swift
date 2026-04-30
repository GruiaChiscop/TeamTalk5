import XCTest
@testable import TeamTalkKit
import TeamTalkC

final class TeamTalkEventResolverTests: XCTestCase {
    func testResolvedUserPicksEmbeddedUserWithoutQueryingClient() {
        var rawUser = User()
        rawUser.nUserID = 5
        let user = TeamTalkUser(rawUser)
        let event = TeamTalkEvent.Kind.userJoined(user)

        // Passing an unstarted client never gets queried because the event already carries the user.
        let client = TeamTalkClient.shared
        let resolved = event.resolvedUser(in: client)
        XCTAssertEqual(resolved?.userID, TeamTalkUserID(5))
    }

    func testResolvedChannelPicksEmbeddedChannelWithoutQueryingClient() {
        var rawChannel = Channel()
        rawChannel.nChannelID = 12
        let channel = TeamTalkChannel(rawChannel)
        let event = TeamTalkEvent.Kind.channelCreated(channel)

        let client = TeamTalkClient.shared
        let resolved = event.resolvedChannel(in: client)
        XCTAssertEqual(resolved?.channelID, TeamTalkChannelID(12))
    }

    func testResolvedUserOnEventWithoutUserPayloadReturnsNil() {
        let event = TeamTalkEvent.Kind.connectionSucceeded
        let client = TeamTalkClient.shared
        XCTAssertNil(event.resolvedUser(in: client))
        XCTAssertNil(event.resolvedChannel(in: client))
    }
}
