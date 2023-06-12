import Vapor

struct UserAdminController: RouteCollection {

    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("createUser", use: createUserHandler)
        routes.post("createUser", use: createUserPostHandler)
        routes.get("users", BlogUser.parameter, "edit", use: editUserHandler)
        routes.post("users", BlogUser.parameter, "edit", use: editUserPostHandler)
        routes.post("users", BlogUser.parameter, "delete", use: deleteUserPostHandler)
    }

    // MARK: - Route handlers
    func createUserHandler(_ req: Request) async throws -> View {
        return try await req.presenters.admin.createUserView(editing: false, errors: nil, name: nil, nameError: false, username: nil, usernameErorr: false, passwordError: false, confirmPasswordError: false, resetPasswordOnLogin: false, userID: nil, profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil, site: req.siteInformation())
    }

    func createUserPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreateUserData.self)

        let createUserErrors = try await validateUserCreation(data, on: req)
        if let errors = createUserErrors {
            let view = try await req.presenters.admin.createUserView(editing: false, errors: errors.errors, name: data.name, nameError: errors.nameError, username: data.username, usernameErorr: errors.usernameError, passwordError: errors.passwordError, confirmPasswordError: errors.confirmPasswordError, resetPasswordOnLogin: data.resetPasswordOnLogin ?? false, userID: nil, profilePicture: data.profilePicture, twitterHandle: data.twitterHandle, biography: data.biography, tagline: data.tagline, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        guard let name = data.name, let username = data.username, let password = data.password, let email = data.email else {
            throw Abort(.internalServerError)
        }
        
        let hashedPassword = try await req.password.async.hash(password)
        let profilePicture = data.profilePicture.isEmptyOrWhitespace() ? nil : data.profilePicture
        let twitterHandle = data.twitterHandle.isEmptyOrWhitespace() ? nil : data.twitterHandle
        let biography = data.biography.isEmptyOrWhitespace() ? nil : data.biography
        let tagline = data.tagline.isEmptyOrWhitespace() ? nil : data.tagline
        let newUser = BlogUser(
            name: name,
            username: username.lowercased(),
            email: email,
            password: hashedPassword,
            type: .administrator, // for now
            profilePicture: profilePicture,
            twitterHandle: twitterHandle,
            biography: biography,
            tagline: tagline
        )
        if let resetPasswordRequired = data.resetPasswordOnLogin, resetPasswordRequired {
            newUser.resetPasswordRequired = true
        }
        let _ = try await req.repositories.blogUser.save(newUser)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress"))
    }

    func editUserHandler(_ req: Request) async throws -> View {
        let user = try await req.parameters.findUser(on: req)
        return try await req.presenters.admin.createUserView(editing: true, errors: nil, name: user.name, nameError: false, username: user.username, usernameErorr: false, passwordError: false, confirmPasswordError: false, resetPasswordOnLogin: user.resetPasswordRequired, userID: user.id, profilePicture: user.profilePicture, twitterHandle: user.twitterHandle, biography: user.biography, tagline: user.tagline, site: req.siteInformation())
    }

    func editUserPostHandler(_ req: Request) async throws -> Response {
        let user = try await req.parameters.findUser(on: req)
        
        let data = try req.content.decode(CreateUserData.self)
        
        guard let name = data.name, let username = data.username else {
            throw Abort(.internalServerError)
        }
        
        let errors = try await self.validateUserCreation(data, editing: true, existingUsername: user.username, on: req)
        if let editUserErrors = errors {
            let view = try await req.presenters.admin.createUserView(editing: true, errors: editUserErrors.errors, name: data.name, nameError: errors?.nameError ?? false, username: data.username, usernameErorr: errors?.usernameError ?? false, passwordError: editUserErrors.passwordError, confirmPasswordError: editUserErrors.confirmPasswordError, resetPasswordOnLogin: data.resetPasswordOnLogin ?? false, userID: user.id, profilePicture: data.profilePicture, twitterHandle: data.twitterHandle, biography: data.biography, tagline: data.tagline, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        user.name = name
        user.username = username.lowercased()
        
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
        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "admin"))
        let _ = try await req.repositories.blogUser.save(user)
        return redirect
    }

    func deleteUserPostHandler(_ req: Request) async throws -> Response {
        let user = try await req.parameters.findUser(on: req)
        let userCount = try await req.repositories.blogUser.getUsersCount()
        guard userCount > 1 else {
            let usersCount = try await req.repositories.blogUser.getAllUsers().count
            let view = try await req.presenters.admin.createIndexView(usersCount: usersCount, errors: ["You cannot delete the last user"], site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        let loggedInUser: BlogUser = try req.auth.require(BlogUser.self)
        guard loggedInUser.id != user.id else {
            let usersCount = try await req.repositories.blogUser.getAllUsers().count
            let view = try await req.presenters.admin.createIndexView(usersCount: usersCount, errors: ["You cannot delete yourself whilst logged in"], site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "admin"))
        try await req.repositories.blogUser.delete(user)
        return redirect
    }

    // MARK: - Validators
    private func validateUserCreation(_ data: CreateUserData, editing: Bool = false, existingUsername: String? = nil, on req: Request) async throws -> CreateUserErrors? {
        var createUserErrors = [String]()
        var passwordError = false
        var confirmPasswordError = false
        var nameErorr = false
        var usernameError = false

        if data.name.isEmptyOrWhitespace() {
            createUserErrors.append("You must specify a name")
            nameErorr = true
        }

        if data.username.isEmptyOrWhitespace() {
            createUserErrors.append("You must specify a username")
            usernameError = true
        }

        if !editing || !data.password.isEmptyOrWhitespace() {
            if data.password.isEmptyOrWhitespace() {
                createUserErrors.append("You must specify a password")
                passwordError = true
            }

            if data.confirmPassword.isEmptyOrWhitespace() {
                createUserErrors.append("You must confirm your password")
                confirmPasswordError = true
            }
        }

        if let password = data.password, password != "" {
            if password.count < 10 {
                createUserErrors.append("Your password must be at least 10 characters long")
                passwordError = true
            }

            if data.password != data.confirmPassword {
                createUserErrors.append("Your passwords must match")
                passwordError = true
                confirmPasswordError = true
            }
        }

        do {
            try CreateUserData.validate(content: req)
        } catch {
            createUserErrors.append("The username provided is not valid")
            usernameError = true
        }

        var usernameUniqueError: String?
        if let username = data.username {
            if editing && data.username == existingUsername {
                usernameUniqueError = nil
            } else {
                let user = try await req.repositories.blogUser.getUser(username: username.lowercased())
                if user != nil {
                    usernameUniqueError =  "Sorry that username has already been taken"
                } else {
                    usernameUniqueError = nil
                }
            }
        } else {
            usernameUniqueError = nil
        }
        
        if let uniqueError = usernameUniqueError {
            createUserErrors.append(uniqueError)
            usernameError = true
        }
        if createUserErrors.count == 0 {
            return nil
        }
        
        let errors = CreateUserErrors(errors: createUserErrors, passwordError: passwordError, confirmPasswordError: confirmPasswordError, nameError: nameErorr, usernameError: usernameError)
        
        return errors
    }
}
