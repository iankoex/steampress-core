import Vapor

struct LoginController: RouteCollection {
    
    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("login", use: loginHandler)
        routes.post("login", use: loginPostHandler)
        routes.post("createOwner", use: createOwnerPostHandler)
        
        let redirectMiddleware = BlogLoginRedirectAuthMiddleware()
        let protectedRoutes = routes.grouped(redirectMiddleware)
        protectedRoutes.get("logout", use: logoutHandler)
        protectedRoutes.get("resetPassword", use: resetPasswordHandler)
        protectedRoutes.post("resetPassword", use: resetPasswordPostHandler)
    }
    
    // MARK: - Route handlers
    
    func loginHandler(_ req: Request) async throws -> View {
        let loginRequied = (try? req.query.get(Bool.self, at: "loginRequired")) != nil
        let requireName = (try await req.repositories.blogUser.getUsersCount() == 0)
        return try await req.presenters.admin.loginView(loginWarning: loginRequied, errors: nil, email: nil, rememberMe: false, requireName: requireName, site: req.siteInformation())
    }
    
    func loginPostHandler(_ req: Request) async throws -> Response {
        let loginData = try req.content.decode(LoginData.self)
        
        if let rememberMe = loginData.rememberMe, rememberMe {
            req.session.data["SteamPressRememberMe"] = "YES"
        } else {
            req.session.data["SteamPressRememberMe"] = nil
        }
        let user = try await req.repositories.blogUser.getUser(email: loginData.email)
        guard let user = user else {
            let loginError = ["Your email or password is incorrect"]
            let requireName = (try await req.repositories.blogUser.getUsersCount() == 0)
            return try await req.presenters.admin.loginView(loginWarning: false, errors: loginError, email: loginData.email, rememberMe: loginData.rememberMe ?? false, requireName: requireName, site: req.siteInformation()).encodeResponse(for: req)
        }
        let userAuthenticated = try await req.password.async.verify(loginData.password, created: user.password)
        guard userAuthenticated else {
            let loginError = ["Your email or password is incorrect"]
            let requireName = (try await req.repositories.blogUser.getUsersCount() == 0)
            return try await req.presenters.admin.loginView(loginWarning: false, errors: loginError, email: loginData.email, rememberMe: loginData.rememberMe ?? false, requireName: requireName, site: req.siteInformation()).encodeResponse(for: req)
        }
        user.authenticateSession(on: req)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress"))
    }
    
    func createOwnerPostHandler(_ req: Request) async throws -> Response {
        let requireName = (try await req.repositories.blogUser.getUsersCount() == 0)
        guard requireName else {
            let errors = ["Owner already exists what you are attempting is illegal"]
            return try await req.presenters.admin.loginView(loginWarning: true, errors: errors, email: nil, rememberMe: false, requireName: requireName, site: req.siteInformation()).encodeResponse(for: req)
        }
        
        let data = try req.content.decode(CreateOwnerData.self)
        guard !data.name.isEmptyOrWhitespace(), !data.password.isEmptyOrWhitespace(), !data.email.isEmptyOrWhitespace() else {
            return try await req.presenters.admin.loginView(loginWarning: true, errors: nil, email: data.email, rememberMe: false, requireName: requireName, site: req.siteInformation()).encodeResponse(for: req)
        }
        let hashedPassword = try await req.password.async.hash(data.password)
        let username = data.name.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces)
        
        let owner = BlogUser(
            name: data.name,
            username: username,
            email: data.email,
            password: hashedPassword,
            type: .owner,
            profilePicture: nil,
            twitterHandle: nil,
            biography: nil,
            tagline: nil
        )
        try await req.repositories.blogUser.save(owner)
        owner.authenticateSession(on: req)
        print("oioi", 1)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress"))
    }
    
    func logoutHandler(_ request: Request) -> Response {
        request.unauthenticateBlogUserSession()
        return request.redirect(to: BlogPathCreator.createPath(for: BlogPathCreator.blogPath))
    }
    
    func resetPasswordHandler(_ req: Request) async throws -> View {
        try await req.presenters.admin.createResetPasswordView(errors: nil, site: req.siteInformation())
    }
    
    func resetPasswordPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(ResetPasswordData.self)
        
        var resetPasswordErrors: [String] = []
        
        guard let password = data.password, let confirmPassword = data.confirmPassword else {
            if data.password == nil {
                resetPasswordErrors.append("You must specify a password")
            }
            
            if data.confirmPassword == nil {
                resetPasswordErrors.append("You must confirm your password")
            }
            
            let view = try await req.presenters.admin.createResetPasswordView(errors: resetPasswordErrors, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        if password != confirmPassword {
            resetPasswordErrors.append("Your passwords must match!")
        }
        
        if password.count < 8 {
            resetPasswordErrors.append("Your password must be at least 8 characters long")
        }
        
        guard resetPasswordErrors.isEmpty else {
            let view = try await req.presenters.admin.createResetPasswordView(errors: resetPasswordErrors, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        let user = try req.auth.require(BlogUser.self)
        let hashedPassword = try await req.password.async.hash(password)
        user.password = hashedPassword
        user.resetPasswordRequired = false
        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "steampress"))
        try await req.repositories.blogUser.save(user)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress"))
    }
}
