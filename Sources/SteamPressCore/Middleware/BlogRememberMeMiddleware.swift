import Vapor

public struct BlogRememberMeMiddleware: AsyncMiddleware {

    public init() {}
    
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        if let rememberMe = request.session.data["SteamPressRememberMe"], rememberMe == "YES" {
            if var steampressCookie = response.cookies["steampress-session"] {
                let oneYear: TimeInterval = 60 * 60 * 24 * 365
                steampressCookie.expires = Date().addingTimeInterval(oneYear)
                response.cookies["steampress-session"] = steampressCookie
                request.session.data["SteamPressRememberMe"] = nil
            }
        }
        return response
    }
}
