import TeamTalkC
import TeamTalkKit
import XCTest

final class TeamTalkEventTests: XCTestCase {
    func testCommandProcessingEventDecoding() {
        var message = TTMessage()
        message.event = .commandProcessing
        message.nSource = 42
        message.payloadType = .boolean
        message.bActive = 1

        switch TeamTalkEvent(message).kind {
        case .commandProcessing(let commandID, let isActive):
            XCTAssertEqual(commandID, TeamTalkCommandID(42))
            XCTAssertTrue(isActive)
        default:
            XCTFail("Expected commandProcessing event")
        }
    }

    func testCommandErrorEventDecoding() {
        var message = TTMessage()
        message.event = .commandError
        message.nSource = 77
        message.payloadType = .clientError

        var error = ClientErrorMsg()
        error.nErrorNo = TeamTalkErrorCode.notAuthorized.cValue
        message.clienterrormsg = error

        switch TeamTalkEvent(message).kind {
        case .commandError(let commandID, let error):
            XCTAssertEqual(commandID, TeamTalkCommandID(77))
            XCTAssertEqual(error.errorCode, .notAuthorized)
            XCTAssertEqual(error.code, TeamTalkErrorCode.notAuthorized.cValue)
        default:
            XCTFail("Expected commandError event")
        }
    }

    func testServerStatisticsEventDecoding() {
        var message = TTMessage()
        message.event = .serverStatistics
        message.payloadType = .serverStatistics

        var statistics = ServerStatistics()
        statistics.nUsersServed = 12
        statistics.nUsersPeak = 5
        statistics.nUptimeMSec = 123_456
        message.serverstatistics = statistics

        switch TeamTalkEvent(message).kind {
        case .serverStatistics(let statistics):
            XCTAssertEqual(statistics.usersServed, 12)
            XCTAssertEqual(statistics.usersPeak, 5)
            XCTAssertEqual(statistics.uptimeMilliseconds, 123_456)
        default:
            XCTFail("Expected serverStatistics event")
        }
    }

    func testTextMessageEventDecoding() {
        var message = TTMessage()
        message.event = .userTextMessage
        message.payloadType = .textMessage

        var textMessage = TeamTalkOutgoingTextMessage.channel(9, content: "Hello").cValue
        textMessage.nFromUserID = 4
        message.textmessage = textMessage

        switch TeamTalkEvent(message).kind {
        case .textMessage(let textMessage):
            XCTAssertEqual(textMessage.type, .channel)
            XCTAssertEqual(textMessage.fromUserID, 4)
            XCTAssertEqual(textMessage.channelID, 9)
            XCTAssertEqual(textMessage.content, "Hello")
        default:
            XCTFail("Expected textMessage event")
        }
    }

    func testBannedUserEventDecoding() {
        var message = TTMessage()
        message.event = .bannedUser
        message.payloadType = .bannedUser
        message.banneduser = TeamTalkBanConfiguration(
            ipAddress: "10.0.0.*",
            channelPath: "/Lobby",
            username: "blocked",
            types: [.ipAddress, .username]
        ).cValue

        switch TeamTalkEvent(message).kind {
        case .bannedUser(let bannedUser):
            XCTAssertEqual(bannedUser.ipAddress, "10.0.0.*")
            XCTAssertEqual(bannedUser.channelPath, "/Lobby")
            XCTAssertEqual(bannedUser.username, "blocked")
            XCTAssertEqual(bannedUser.types, [.ipAddress, .username])
        default:
            XCTFail("Expected bannedUser event")
        }
    }
}
