import Vapor

public final class BlogAuthSessionsMiddleware: AsyncMiddleware {
    
    public init() {}
    
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if let userIDString = request.session.data["_BlogUserSession"], let userID = Int(userIDString) {
            let user = try await request.blogUserRepository.getUser(id: userID)
            if let user = user {
                request.auth.login(user)
            }
        }
        let response = try await next.respond(to: request)
        if let user = request.auth.get(BlogUser.self) {
            user.authenticateSession(on: request)
        } else {
            request.unauthenticateBlogUserSession()
        }
        return response
    }
}
