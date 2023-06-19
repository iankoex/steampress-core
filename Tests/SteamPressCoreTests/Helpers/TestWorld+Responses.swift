import Vapor
@testable import SteamPressCore

extension TestWorld {
    func getResponse<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), decodeTo type: T.Type) async throws -> T where T: Content {
        let response = try await getResponse(to: path, method: method, headers: headers)
        return try response.content.decode(type)
    }

    func getResponseString(to path: String, headers: HTTPHeaders = .init()) async throws -> String {
        return try await getResponse(to: path, headers: headers).body.string!
    }

    func getResponse<T: Content>(to path: String, method: HTTPMethod = .POST, body: T, loggedInUser: BlogUser? = nil, passwordToLoginWith: String? = nil, headers: HTTPHeaders = .init()) async throws -> Response {
        let request = try  await setupRequest(to: path, method: method, loggedInUser: loggedInUser, passwordToLoginWith: passwordToLoginWith, headers: headers)
        try request.content.encode(body)
        return try await getResponse(to: request)
    }

    func getResponse(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), loggedInUser: BlogUser? = nil) async throws -> Response {
        let request = try await setupRequest(to: path, method: method, loggedInUser: loggedInUser, passwordToLoginWith: nil, headers: headers)
        return try await getResponse(to: request)
    }

    func setupRequest(to path: String, method: HTTPMethod = .POST, loggedInUser: BlogUser? = nil, passwordToLoginWith: String? = nil, headers: HTTPHeaders = .init()) async throws -> Request {
        let request = Request(application: context.app, method: method, url: URI(path: path), headers: headers, on: context.eventLoopGroup.next())
        if let user = loggedInUser {
            request.auth.login(user)
        }
        return request
    }

    func getResponse(to request: Request) async throws -> Response {
        return try await context.app.responder.respond(to: request).get()
    }
}
