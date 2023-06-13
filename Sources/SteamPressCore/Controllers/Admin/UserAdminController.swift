import Vapor

struct UserAdminController: RouteCollection {

    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("members", use: membersHandler)
        routes.get("members", "new", use: createMemberHandler)
        routes.post("members", "new", use: createNewMemberHandler)
        routes.get("members", BlogUser.parameter, use: memberHandler)
        routes.post("members", BlogUser.parameter, use: updateMemberHandler)
        
//        adminProtectedRoutes.get("tags", BlogTag.parameter, use: tagHandler)
//        adminProtectedRoutes.post("tags", BlogTag.parameter, use: updateTagHandler)
//        adminProtectedRoutes.get("tags", BlogTag.parameter, "delete", use: deleteTagHandler)
    }

    // MARK: - Route handlers
    
    func membersHandler(_ req: Request) async throws -> View {
        let users = try await req.repositories.blogUser.getAllUsers()
        return try await req.presenters.admin.createMembersView(users: users.convertToPublic(), usersCount: users.count, site: req.siteInformation())
    }
    
    func createMemberHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createCreateMemberView(userData: nil, errors: nil, usersCount: usersCount, site: req.siteInformation())
    }
    
    func createNewMemberHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreateUserData.self)
        
        let createUserErrors = try await validateUserCreation(data, on: req)
        if let errors = createUserErrors {
            let usersCount = try await req.repositories.blogUser.getUsersCount()
            let view = try await req.presenters.admin.createCreateMemberView(userData: data, errors: errors, usersCount: usersCount, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        guard let password = data.password else {
            throw Abort(.internalServerError)
        }
        
        let hashedPassword = try await req.password.async.hash(password)
        let profilePicture = data.profilePicture.isEmptyOrWhitespace() ? nil : data.profilePicture
        let twitterHandle = data.twitterHandle.isEmptyOrWhitespace() ? nil : data.twitterHandle
        let biography = data.biography.isEmptyOrWhitespace() ? nil : data.biography
        let tagline = data.tagline.isEmptyOrWhitespace() ? nil : data.tagline
        let newUser = BlogUser(
            name: data.name,
            username: data.username,
            email: data.email,
            password: hashedPassword,
            type: .member, // for now
            profilePicture: profilePicture,
            twitterHandle: twitterHandle,
            biography: biography,
            tagline: tagline
        )
        if let resetPasswordRequired = data.resetPasswordOnLogin, resetPasswordRequired {
            newUser.resetPasswordRequired = true
        }
        try await req.repositories.blogUser.save(newUser)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress/members"))
    }
    
    func memberHandler(_ req: Request) async throws -> View {
        let member = try await req.parameters.findUser(on: req)
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createCreateMemberView(userData: member.convertToUserData(), errors: nil, usersCount: usersCount, site: req.siteInformation())
    }
    
    func updateMemberHandler(_ req: Request) async throws -> Response {
        let user = try await req.parameters.findUser(on: req)
        let data = try req.content.decode(CreateUserData.self)
        
        let errors = try await self.validateUserCreation(data, editing: true, existingUsername: user.username, on: req)
        if let editUserErrors = errors {
            let usersCount = try await req.repositories.blogUser.getUsersCount()
            let view = try await req.presenters.admin.createCreateMemberView(userData: data, errors: errors, usersCount: usersCount, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        user.name = data.name
        user.username = data.username.lowercased()
        
        let profilePicture = data.profilePicture.isEmptyOrWhitespace() ? nil : data.profilePicture
        let twitterHandle = data.twitterHandle.isEmptyOrWhitespace() ? nil : data.twitterHandle
        let biography = data.biography.isEmptyOrWhitespace() ? nil : data.biography
        let tagline = data.tagline.isEmptyOrWhitespace() ? nil : data.tagline
        
        user.profilePicture = profilePicture
        user.twitterHandle = twitterHandle
        user.biography = biography
        user.tagline = tagline
        
        if let resetPasswordOnLogin = data.resetPasswordOnLogin, resetPasswordOnLogin {
            user.resetPasswordRequired = true
        }
        
        if let password = data.password, password != "" {
            let hashedPassword = try await req.password.async.hash(password)
            user.password = hashedPassword
        }
        try await req.repositories.blogUser.save(user)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress/members"))
    }
    
//    func createUserHandler(_ req: Request) async throws -> View {
//        return try await req.presenters.admin.createUserView(editing: false, errors: nil, name: nil, nameError: false, username: nil, usernameErorr: false, passwordError: false, confirmPasswordError: false, resetPasswordOnLogin: false, userID: nil, profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil, site: req.siteInformation())
//    }

//    func createUserPostHandler(_ req: Request) async throws -> Response {
//        let data = try req.content.decode(CreateUserData.self)
//
//        let createUserErrors = try await validateUserCreation(data, on: req)
//        if let errors = createUserErrors {
////            let view = try await req.presenters.admin.createUserView(editing: false, errors: errors.errors, name: data.name, nameError: errors.nameError, username: data.username, usernameErorr: errors.usernameError, passwordError: errors.passwordError, confirmPasswordError: errors.confirmPasswordError, resetPasswordOnLogin: data.resetPasswordOnLogin ?? false, userID: nil, profilePicture: data.profilePicture, twitterHandle: data.twitterHandle, biography: data.biography, tagline: data.tagline, site: req.siteInformation())
////            return try await view.encodeResponse(for: req)
//        }
//        
//        guard let password = data.password else {
//            throw Abort(.internalServerError)
//        }
//        
//        let hashedPassword = try await req.password.async.hash(password)
//        let profilePicture = data.profilePicture.isEmptyOrWhitespace() ? nil : data.profilePicture
//        let twitterHandle = data.twitterHandle.isEmptyOrWhitespace() ? nil : data.twitterHandle
//        let biography = data.biography.isEmptyOrWhitespace() ? nil : data.biography
//        let tagline = data.tagline.isEmptyOrWhitespace() ? nil : data.tagline
//        let newUser = BlogUser(
//            name: data.name,
//            username: data.username.lowercased(),
//            email: data.email,
//            password: hashedPassword,
//            type: .administrator, // for now
//            profilePicture: profilePicture,
//            twitterHandle: twitterHandle,
//            biography: biography,
//            tagline: tagline
//        )
//        if let resetPasswordRequired = data.resetPasswordOnLogin, resetPasswordRequired {
//            newUser.resetPasswordRequired = true
//        }
//        let _ = try await req.repositories.blogUser.save(newUser)
//        return req.redirect(to: BlogPathCreator.createPath(for: "steampress"))
//    }

//    func editUserHandler(_ req: Request) async throws -> View {
//        let user = try await req.parameters.findUser(on: req)
//        return try await req.presenters.admin.createUserView(editing: true, errors: nil, name: user.name, nameError: false, username: user.username, usernameErorr: false, passwordError: false, confirmPasswordError: false, resetPasswordOnLogin: user.resetPasswordRequired, userID: user.id, profilePicture: user.profilePicture, twitterHandle: user.twitterHandle, biography: user.biography, tagline: user.tagline, site: req.siteInformation())
//    }

//    func editUserPostHandler(_ req: Request) async throws -> Response {
//        let user = try await req.parameters.findUser(on: req)
//
//        let data = try req.content.decode(CreateUserData.self)
//
//        guard let name = data.name, let username = data.username else {
//            throw Abort(.internalServerError)
//        }
//
//        let errors = try await self.validateUserCreation(data, editing: true, existingUsername: user.username, on: req)
//        if let editUserErrors = errors {
////            let view = try await req.presenters.admin.createUserView(editing: true, errors: editUserErrors.errors, name: data.name, nameError: errors?.nameError ?? false, username: data.username, usernameErorr: errors?.usernameError ?? false, passwordError: editUserErrors.passwordError, confirmPasswordError: editUserErrors.confirmPasswordError, resetPasswordOnLogin: data.resetPasswordOnLogin ?? false, userID: user.id, profilePicture: data.profilePicture, twitterHandle: data.twitterHandle, biography: data.biography, tagline: data.tagline, site: req.siteInformation())
////            return try await view.encodeResponse(for: req)
//        }
//
//        user.name = name
//        user.username = username.lowercased()
//
//        let profilePicture = data.profilePicture.isEmptyOrWhitespace() ? nil : data.profilePicture
//        let twitterHandle = data.twitterHandle.isEmptyOrWhitespace() ? nil : data.twitterHandle
//        let biography = data.biography.isEmptyOrWhitespace() ? nil : data.biography
//        let tagline = data.tagline.isEmptyOrWhitespace() ? nil : data.tagline
//
//        user.profilePicture = profilePicture
//        user.twitterHandle = twitterHandle
//        user.biography = biography
//        user.tagline = tagline
//
//        if let resetPasswordOnLogin = data.resetPasswordOnLogin, resetPasswordOnLogin {
//            user.resetPasswordRequired = true
//        }
//
//        if let password = data.password, password != "" {
//            let hashedPassword = try await req.password.async.hash(password)
//            user.password = hashedPassword
//        }
//        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "admin"))
//        let _ = try await req.repositories.blogUser.save(user)
//        return redirect
//    }

    func deleteUserPostHandler(_ req: Request) async throws -> Response {
        let user = try await req.parameters.findUser(on: req)
        let userCount = try await req.repositories.blogUser.getUsersCount()
        guard userCount > 1 else {
            let usersCount = try await req.repositories.blogUser.getUsersCount()
            let view = try await req.presenters.admin.createIndexView(usersCount: usersCount, errors: ["You cannot delete the last user"], site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        let loggedInUser: BlogUser = try req.auth.require(BlogUser.self)
        guard loggedInUser.id != user.id else {
            let usersCount = try await req.repositories.blogUser.getUsersCount()
            let view = try await req.presenters.admin.createIndexView(usersCount: usersCount, errors: ["You cannot delete yourself whilst logged in"], site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "admin"))
        try await req.repositories.blogUser.delete(user)
        return redirect
    }

    // MARK: - Validators
    private func validateUserCreation(_ data: CreateUserData, editing: Bool = false, existingUsername: String? = nil, on req: Request) async throws -> [String]? {
        var createUserErrors: [String] = []

        if data.name.isEmptyOrWhitespace() {
            createUserErrors.append("You must specify a name")
        }

        if data.username.isEmptyOrWhitespace() {
            createUserErrors.append("You must specify a username")
        }
        
        if data.email.isEmptyOrWhitespace() {
            createUserErrors.append("You must specify an email")
        }

        if !editing || !data.password.isEmptyOrWhitespace() {
            if data.password.isEmptyOrWhitespace() {
                createUserErrors.append("You must specify a password")
            }

            if data.confirmPassword.isEmptyOrWhitespace() {
                createUserErrors.append("You must confirm your password")
            }
        }

        if let password = data.password, password != "" {
            if password.count < 8 {
                createUserErrors.append("Your password must be at least 8 characters long")
            }

            if data.password != data.confirmPassword {
                createUserErrors.append("Your passwords must match")
            }
        }

        do {
            try CreateUserData.validate(content: req)
        } catch {
            createUserErrors.append("The username provided is not valid")
        }

        var usernameUniqueError: String?
        if editing && data.username == existingUsername {
            usernameUniqueError = nil
        } else {
            let user = try await req.repositories.blogUser.getUser(username: data.username.lowercased())
            if user != nil {
                usernameUniqueError =  "Sorry that username has already been taken"
            } else {
                usernameUniqueError = nil
            }
        }
        
        if let uniqueError = usernameUniqueError {
            createUserErrors.append(uniqueError)
        }
        if createUserErrors.count == 0 {
            return nil
        }
        
        return createUserErrors
    }
}
