import Vapor

struct BlogLoginRedirectAuthMiddleware: AsyncMiddleware {
    
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            let user = try request.auth.require(BlogUser.self)
            let resetPasswordPath = BlogPathCreator.createPath(for: "steampress/resetPassword")
            var requestPath = request.url.string
            if !requestPath.hasSuffix("/") {
                requestPath = requestPath + "/"
            }
            if user.resetPasswordRequired && requestPath != resetPasswordPath {
                let redirect = request.redirect(to: resetPasswordPath)
                return redirect
            }
        } catch {
            return request.redirect(to: BlogPathCreator.createPath(for: "steampress/login", query: "loginRequired"))
        }
        return try await next.respond(to: request)
    }
}
