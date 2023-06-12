import Vapor

struct LoginController: RouteCollection {
    
    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("login", use: loginHandler)
        routes.post("login", use: loginPostHandler)
        
        let redirectMiddleware = BlogLoginRedirectAuthMiddleware()
        let protectedRoutes = routes.grouped(redirectMiddleware)
        protectedRoutes.get("logout", use: logoutHandler)
        protectedRoutes.get("resetPassword", use: resetPasswordHandler)
        protectedRoutes.post("resetPassword", use: resetPasswordPostHandler)
    }
    
    // MARK: - Route handlers
    func loginHandler(_ req: Request) async throws -> View {
        try await req.repositories.blogUser.createInitialAdminUser()
        let loginRequied = (try? req.query.get(Bool.self, at: "loginRequired")) != nil
        return try await req.presenters.blog.loginView(loginWarning: loginRequied, errors: nil, username: nil, usernameError: false, passwordError: false, rememberMe: false, site: req.siteInformation())
    }
    
    func loginPostHandler(_ req: Request) async throws -> Response {
        let loginData = try req.content.decode(LoginData.self)
        var loginErrors = [String]()
        var usernameError = false
        var passwordError = false
        
        if loginData.username == nil {
            loginErrors.append("You must supply your username")
            usernameError = true
        }
        
        if loginData.password == nil {
            loginErrors.append("You must supply your password")
            passwordError = true
        }
        
        if !loginErrors.isEmpty {
            return try await req.presenters.blog.loginView(loginWarning: false, errors: loginErrors, username: loginData.username, usernameError: usernameError, passwordError: passwordError, rememberMe: loginData.rememberMe ?? false, site: req.siteInformation()).encodeResponse(for: req)
        }
        
        guard let username = loginData.username, let password = loginData.password else {
            throw Abort(.internalServerError)
        }
        
        if let rememberMe = loginData.rememberMe, rememberMe {
            req.session.data["SteamPressRememberMe"] = "YES"
        } else {
            req.session.data["SteamPressRememberMe"] = nil
        }
        let user = try await req.repositories.blogUser.getUser(username: username)
        guard let user = user else {
            let loginError = ["Your username or password is incorrect"]
            return try await req.presenters.blog.loginView(loginWarning: false, errors: loginError, username: loginData.username, usernameError: false, passwordError: false, rememberMe: loginData.rememberMe ?? false, site: req.siteInformation()).encodeResponse(for: req)
        }
        let userAuthenticated = try await req.password.async.verify(password, created: user.password)
        guard userAuthenticated else {
            let loginError = ["Your username or password is incorrect"]
            return try await req.presenters.blog.loginView(loginWarning: false, errors: loginError, username: loginData.username, usernameError: false, passwordError: false, rememberMe: loginData.rememberMe ?? false, site: req.siteInformation()).encodeResponse(for: req)
        }
        user.authenticateSession(on: req)
        return req.redirect(to: BlogPathCreator.createPath(for: "admin"))
    }
    
    func logoutHandler(_ request: Request) -> Response {
        request.unauthenticateBlogUserSession()
        return request.redirect(to: BlogPathCreator.createPath(for: BlogPathCreator.blogPath))
    }
    
    func resetPasswordHandler(_ req: Request) async throws -> View {
        try await req.presenters.admin.createResetPasswordView(errors: nil, passwordError: nil, confirmPasswordError: nil, site: req.siteInformation())
    }
    
    func resetPasswordPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(ResetPasswordData.self)
        
        var resetPasswordErrors: [String] = []
        var passwordError: Bool?
        var confirmPasswordError: Bool?
        
        guard let password = data.password, let confirmPassword = data.confirmPassword else {
            
            if data.password == nil {
                resetPasswordErrors.append("You must specify a password")
                passwordError = true
            }
            
            if data.confirmPassword == nil {
                resetPasswordErrors.append("You must confirm your password")
                confirmPasswordError = true
            }
            
            let view = try await req.presenters.admin.createResetPasswordView(errors: resetPasswordErrors, passwordError: passwordError, confirmPasswordError: confirmPasswordError, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        if password != confirmPassword {
            resetPasswordErrors.append("Your passwords must match!")
            passwordError = true
            confirmPasswordError = true
        }
        
        if password.count < 8 {
            passwordError = true
            resetPasswordErrors.append("Your password must be at least 8 characters long")
        }
        
        guard resetPasswordErrors.isEmpty else {
            let view = try await req.presenters.admin.createResetPasswordView(errors: resetPasswordErrors, passwordError: passwordError, confirmPasswordError: confirmPasswordError, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        let user = try req.auth.require(BlogUser.self)
        let hashedPassword = try await req.password.async.hash(password)
        user.password = hashedPassword
        user.resetPasswordRequired = false
        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "admin"))
        let _ = try await req.repositories.blogUser.save(user)
        return req.redirect(to: BlogPathCreator.createPath(for: "admin"))
    }
}