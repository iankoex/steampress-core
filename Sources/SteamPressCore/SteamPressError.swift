import Vapor

public struct SteamPressError: AbortError, DebuggableError {

    public let identifier: String
    public let reason: String

    public init(identifier: String, _ reason: String) {
        self.identifier = identifier
        self.reason = reason
    }

    public var status: HTTPResponseStatus {
        return .internalServerError
    }
}
