import XCTest
import Vapor
@testable import SteamPressCore

class AdminMemberUpdateTests: XCTestCase {
    
    // MARK: - Properties
    
    private var testWorld: TestWorld!
    private var sessionCookie: HTTPCookies!
    private let blogIndexPath = "blog"
    private let owner = CreateOwnerData(name: "Steam Press Owner", password: "SP@Password", email: "admin@steampress.io")
    private let websiteURL = "https://www.steampress.io"
    
    var app: Application {
        testWorld.context.app
    }
    
    // MARK: - Overrides
    
    override func setUpWithError() throws {
        testWorld = try TestWorld.create(path: blogIndexPath, passwordHasherToUse: .real, url: websiteURL)
        sessionCookie = try createAndLoginOwner()
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }
    
    // MARK: - Update Users
    
    func testPresenterGetsUserInformationOnEditUserPage() async throws {
        let users = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        let user = try XCTUnwrap(users.first)
        
        try app
            .describe("Presenter Gets User Information on Edit User Page")
            .get(adminPath(for: "members/\(user.id!)"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        let data = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertEqual(data.name, user.name)
        XCTAssertEqual(data.username, user.username)
        XCTAssertEqual(data.profilePicture, user.profilePicture)
        XCTAssertEqual(data.twitterHandle, user.twitterHandle)
        XCTAssertEqual(data.biography, user.biography)
        XCTAssertEqual(data.tagline, user.tagline)
        XCTAssertEqual(data.resetPasswordOnLogin, user.resetPasswordRequired)
    }
    
    func testUserCanBeUpdated() async throws {
        let user = try await createAndReturnUser()
        
        let editData = CreateUserData(
            name: "Luke Sky",
            username: "lukessky",
            password: "somePasswordSky",
            confirmPassword: "somePasswordSky",
            email: "lukeSky@lukes.com",
            profilePicture: "https://static.brokenhands.io/images/cat.png",
            tagline: "awesomest Sky",
            biography: "bio bio bio SKY",
            twitterHandle: "lukesSky"
        )
        
        try app
            .describe("Update the Newly created User Successfully")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let updatedUsers = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // First is user created in setup, final is one just created
        XCTAssertEqual(updatedUsers.count, 2)
        let updatedUser = try XCTUnwrap(updatedUsers.last)
        
        XCTAssertEqual(updatedUser.id, user.id)
        XCTAssertEqual(updatedUser.username, editData.username.lowercased())
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertEqual(updatedUser.email, editData.email)
        XCTAssertEqual(updatedUser.profilePicture, editData.profilePicture)
        XCTAssertEqual(updatedUser.tagline, editData.tagline)
        XCTAssertEqual(updatedUser.biography, editData.biography)
        XCTAssertEqual(updatedUser.twitterHandle, editData.twitterHandle)
        XCTAssertNotEqual(updatedUser.password, editData.password)
    }
    
    func testOptionalInfoDoesntGetUpdatedWhenEditingUsernameAndSendingEmptyValuesIfSomeAlreadySet() async throws {
        let user = try await createAndReturnUser()
        
        let editData = CreateUserData(
            name: "Luke Sky",
            username: "lukessky",
            email: "lukeSky@lukes.com"
        )
        
        try app
            .describe("Update the Newly created User Successfully")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let updatedUsers = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        
        // First is user created in setup, final is one just created
        XCTAssertEqual(updatedUsers.count, 2)
        let updatedUser = try XCTUnwrap(updatedUsers.last)
        
        XCTAssertEqual(updatedUser.id, user.id)
        XCTAssertEqual(updatedUser.username, editData.username.lowercased())
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertEqual(updatedUser.email, editData.email)
        
        // updating password with nil value does not change the password
        XCTAssertEqual(user.password, updatedUser.password)
        
        XCTAssertNil(updatedUser.profilePicture)
        XCTAssertNil(updatedUser.tagline)
        XCTAssertNil(updatedUser.biography)
        XCTAssertNil(updatedUser.twitterHandle)
    }
    
    func testWhenEditingUserPasswordResetIsRequiredEvenIfSetToFalse() async throws {
        let createData = CreateUserData(
            name: "Luke",
            username: "lukes",
            password: "somePassword",
            confirmPassword: "somePassword",
            email: "luke@lukes.com"
        )
        
        try app
            .describe("New User Can be Created Successfully")
            .post(adminPath(for: "members/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let users = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // First is user created in setup, final is one just created
        XCTAssertEqual(users.count, 2)
        let user = try XCTUnwrap(users.last)
        
        var cookie: HTTPCookies = HTTPCookies()
        let loginData = LoginData(email: createData.email, password: createData.password!)
        
        try app
            .describe("User Can login Successfully")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = response.headers.setCookie!
            }
            .test()
        
        let newPassword = "NewSP@Password"
        let resetData = ResetPasswordData(password: newPassword, confirmPassword: newPassword)
        
        try app
            .describe("Can Reset Password")
            .post(adminPath(for: "resetPassword"))
            .body(resetData)
            .cookie(cookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
            }
            .test()
        
        let editData = CreateUserData(
            name: "Luke Sky",
            username: "lukessky",
            password: "somePasswordSky",
            confirmPassword: "somePasswordSky",
            email: "lukeSky@lukes.com",
            resetPasswordOnLogin: false
        )
        
        try app
            .describe("Update the Newly created User Successfully")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let updatedUsers = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // First is user created in setup, final is one just created
        XCTAssertEqual(updatedUsers.count, 2)
        let updatedUser = try XCTUnwrap(updatedUsers.last)
        XCTAssertEqual(updatedUser.id, user.id)
        XCTAssertEqual(updatedUser.username, editData.username.lowercased())
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertEqual(updatedUser.email, editData.email)
        
        XCTAssertTrue(updatedUser.resetPasswordRequired)
        
        try app
            .describe("Assert Login Required When Accessing")
            .get(adminPath(for: ""))
            .cookie(cookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "resetPassword/"))
            }
            .test()
    }
    
    func testWhenEditingUserResetPasswordFlagSetIfRequired() async throws {
        let createData = CreateUserData(
            name: "Luke",
            username: "lukes",
            password: "somePassword",
            confirmPassword: "somePassword",
            email: "luke@lukes.com"
        )
        
        try app
            .describe("New User Can be Created Successfully")
            .post(adminPath(for: "members/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let users = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // First is user created in setup, final is one just created
        XCTAssertEqual(users.count, 2)
        let user = try XCTUnwrap(users.last)
        
        var cookie: HTTPCookies = HTTPCookies()
        let loginData = LoginData(email: createData.email, password: createData.password!)
        
        try app
            .describe("User Can login Successfully")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = response.headers.setCookie!
            }
            .test()
        
        let newPassword = "NewSP@Password"
        let resetData = ResetPasswordData(password: newPassword, confirmPassword: newPassword)
        
        try app
            .describe("Can Reset Password")
            .post(adminPath(for: "resetPassword"))
            .body(resetData)
            .cookie(cookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
            }
            .test()
        
        let editData = CreateUserData(
            name: "Luke Sky",
            username: "lukessky",
            email: "lukeSky@lukes.com",
            resetPasswordOnLogin: true
        )
        
        try app
            .describe("Update the Newly created User Successfully")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let updatedUsers = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // First is user created in setup, final is one just created
        XCTAssertEqual(updatedUsers.count, 2)
        let updatedUser = try XCTUnwrap(updatedUsers.last)
        XCTAssertEqual(updatedUser.id, user.id)
        XCTAssertEqual(updatedUser.username, editData.username.lowercased())
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertEqual(updatedUser.email, editData.email)
        XCTAssertEqual(updatedUser.resetPasswordRequired, editData.resetPasswordOnLogin)
        
        XCTAssertTrue(updatedUser.resetPasswordRequired)
        
        try app
            .describe("Assert Reset Required When Accessing Admin")
            .get(adminPath(for: ""))
            .cookie(cookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "resetPassword/"))
            }
            .test()
    }
    
    func testWhenEditingUserResetPasswordFlagNotSetIfSetToFalse() async throws {
        let createData = CreateUserData(
            name: "Luke",
            username: "lukes",
            password: "somePassword",
            confirmPassword: "somePassword",
            email: "luke@lukes.com"
        )
        
        try app
            .describe("New User Can be Created Successfully")
            .post(adminPath(for: "members/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let users = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // First is user created in setup, final is one just created
        XCTAssertEqual(users.count, 2)
        let user = try XCTUnwrap(users.last)
        
        var cookie: HTTPCookies = HTTPCookies()
        let loginData = LoginData(email: createData.email, password: createData.password!)
        
        try app
            .describe("User Can login Successfully")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = response.headers.setCookie!
            }
            .test()
        
        let newPassword = "NewSP@Password"
        let resetData = ResetPasswordData(password: newPassword, confirmPassword: newPassword)
        
        try app
            .describe("Can Reset Password")
            .post(adminPath(for: "resetPassword"))
            .body(resetData)
            .cookie(cookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
            }
            .test()
        
        let editData = CreateUserData(
            name: "Luke Sky",
            username: "lukessky",
            email: "lukeSky@lukes.com",
            resetPasswordOnLogin: false
        )
        
        try app
            .describe("Update the Newly created User Successfully")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let updatedUsers = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // First is user created in setup, final is one just created
        XCTAssertEqual(updatedUsers.count, 2)
        let updatedUser = try XCTUnwrap(updatedUsers.last)
        XCTAssertEqual(updatedUser.id, user.id)
        XCTAssertEqual(updatedUser.username, editData.username.lowercased())
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertEqual(updatedUser.email, editData.email)
        XCTAssertEqual(updatedUser.resetPasswordRequired, editData.resetPasswordOnLogin)
        
        XCTAssertFalse(updatedUser.resetPasswordRequired)
        
        try app
            .describe("Assert Reset Not Required When Accessing Admin Page")
            .get(adminPath(for: ""))
            .cookie(cookie)
            .expect(.ok)
            .test()
    }
    
    func testUserCannotBeUpdatedWithRequiredFieldsMissingOrWhitespace() async throws {
        let user = try await createAndReturnUser()
        
        let editData = CreateUserData(
            name: "",
            username: "",
            email: "  ", // whitespace character
            profilePicture: "https://static.brokenhands.io/images/cat.png",
            tagline: "awesomest",
            biography: "bio bio bio",
            twitterHandle: "lukes",
            resetPasswordOnLogin: true
        )
        
        try app
            .describe("Cannot Be Updated With Required Fields Missing or Whitespace")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("You must specify a name"))
        XCTAssertTrue(errors.contains("You must specify a username"))
        XCTAssertTrue(errors.contains("You must specify an email"))
    }
    
    func testUserCannotBeUpdatedWithShortOrMismatchingPasswords() async throws {
        let user = try await createAndReturnUser()
        
        let editData = CreateUserData(
            name: "Luke",
            username: "lukes",
            password: "123",
            confirmPassword: "321",
            email: "luke@lukes.com",
            profilePicture: "https://static.brokenhands.io/images/cat.png",
            tagline: "awesomest",
            biography: "bio bio bio",
            twitterHandle: "lukes",
            resetPasswordOnLogin: false
        )
        
        try app
            .describe("User Cannot Be Updated With Short or Mismatching Passwords")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("Your password must be at least 8 characters long"))
        XCTAssertTrue(errors.contains("Your passwords must match"))
    }
    
    func testUserCannotBeUpdatedWithAnInvalidUsername() async throws {
        let user = try await createAndReturnUser()
        
        let editData = CreateUserData(
            name: "Luke",
            username: "lukes/luka!",
            password: "somePassword",
            confirmPassword: "somePassword",
            email: "luke@lukes.com",
            profilePicture: "https://static.brokenhands.io/images/cat.png",
            tagline: "awesomest",
            biography: "bio bio bio",
            twitterHandle: "lukes",
            resetPasswordOnLogin: false
        )
        
        try app
            .describe("User Cannot Be Updated With An Invalid Username")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("The username provided is not valid"))
    }
    
    func testUserCannotBeUpdatedWithUsernameThatAlreadyExists() async throws {
        let user = try await createAndReturnUser()
        
        let editData = CreateUserData(
            name: "Luke",
            username: owner.name.replacingOccurrences(of: " ", with: "").lowercased(),
            password: "somePassword",
            confirmPassword: "somePassword",
            email: "luke@lukes.com",
            profilePicture: "https://static.brokenhands.io/images/cat.png",
            tagline: "awesomest",
            biography: "bio bio bio",
            twitterHandle: "lukes",
            resetPasswordOnLogin: false
        )
        
        try app
            .describe("User Cannot Be Updated With Username That Already Exists")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("Sorry that username has already been taken"))
    }
    
    func testUserCannotBeUpdatedWithUsernameThatAlreadyExistsIgnoringCase() async throws {
        let user = try await createAndReturnUser()
        
        let editData = CreateUserData(
            name: "Luke",
            username: owner.name.replacingOccurrences(of: " ", with: ""),
            password: "somePassword",
            confirmPassword: "somePassword",
            email: "luke@lukes.com",
            profilePicture: "https://static.brokenhands.io/images/cat.png",
            tagline: "awesomest",
            biography: "bio bio bio",
            twitterHandle: "lukes",
            resetPasswordOnLogin: false
        )
        
        try app
            .describe("User Cannot Be Updated With Username That Already Exists Ignoring Case")
            .post(adminPath(for: "members/\(user.id!)"))
            .body(editData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("Sorry that username has already been taken"))
    }
    
    // MARK: - Helpers
    
    private func createAndReturnUser() async throws -> BlogUser {
        let createData = CreateUserData(
            name: "Luke",
            username: "lukes",
            password: "somePassword",
            confirmPassword: "somePassword",
            email: "luke@lukes.com",
            profilePicture: "https://static.brokenhands.io/images/cat.png",
            tagline: "awesomest",
            biography: "bio bio bio",
            twitterHandle: "lukes",
            resetPasswordOnLogin: true
        )
        
        try app
            .describe("New User Can be Created Successfully")
            .post(adminPath(for: "members/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let users = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // First is user created in setup, final is one just created
        XCTAssertEqual(users.count, 2)
        let user = try XCTUnwrap(users.last)
        return user
    }
    
    private func createAndLoginOwner() throws -> HTTPCookies {
        var cookie: HTTPCookies = HTTPCookies()
        try app
            .describe("App should create and log in user")
            .post(adminPath(for: "createOwner"))
            .body(owner)
            .expect(.seeOther)
            .expect { response in
                cookie = response.headers.setCookie!
            }
            .test()
        return cookie
    }
    
    private func adminPath(for path: String) -> String {
        return "/\(blogIndexPath)/steampress/\(path)"
    }
}




//    func testPasswordIsActuallyHashedWhenEditingAUser() throws {
//        try testWorld.shutdown()
//        testWorld = try TestWorld.create(passwordHasherToUse: .reversed)
//        let usersPassword = "password"
//        let hashedPassword = String(usersPassword.reversed())
//        user = testWorld.createUser(name: "Leia", username: "leia", password: hashedPassword)
//
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Darth Vader"
//            let username = "darth_vader"
//            let password = "somenewpassword"
//            let confirmPassword = "somenewpassword"
//        }
//
//        let editData = EditUserData()
//        _ = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user, passwordToLoginWith: usersPassword)
//
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertEqual(updatedUser.password, String(editData.password.reversed()))
//    }

//
//    // MARK: - Delete users
//
//    func testCanDeleteUser() throws {
//        let user2 = testWorld.createUser(name: "Han", username: "han")
//
//        let response = try testWorld.getResponse(to: "/admin/users/\(user2.id!)/delete", body: EmptyContent(), loggedInUser: user)
//
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/admin/")
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        XCTAssertNotEqual(testWorld.context.repository.users.last?.name, "Han")
//    }
//
//    func testCannotDeleteSelf() throws {
//        let user2 = testWorld.createUser(name: "Han", username: "han")
//        let testData = try testWorld.createPost(author: user2)
//
//        _ = try testWorld.getResponse(to: "/admin/users/\(user2.id!)/delete", body: EmptyContent(), loggedInUser: user2)
//
//        let viewErrors = try XCTUnwrap(presenter.adminViewErrors)
//        XCTAssertTrue(viewErrors.contains("You cannot delete yourself whilst logged in"))
//        XCTAssertEqual(testWorld.context.repository.users.count, 2)
//
//        XCTAssertEqual(presenter.adminViewPosts?.count, 1)
//        XCTAssertEqual(presenter.adminViewPosts?.first?.title, testData.post.title)
//        XCTAssertEqual(presenter.adminViewUsers?.count, 2)
//        XCTAssertEqual(presenter.adminViewUsers?.last?.username, user2.username)
//    }
//
//    func testCannotDeleteLastUser() throws {
//        try testWorld.shutdown()
//        testWorld = try TestWorld.create()
//        let adminUser = testWorld.createUser(name: "Admin", username: "admin")
//        let testData = try testWorld.createPost(author: adminUser)
//        _ = try testWorld.getResponse(to: "/admin/users/\(adminUser.id!)/delete", body: EmptyContent(), loggedInUser: adminUser)
//
//        let viewErrors = try XCTUnwrap(presenter.adminViewErrors)
//        XCTAssertTrue(viewErrors.contains("You cannot delete the last user"))
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//
//        XCTAssertEqual(presenter.adminViewPosts?.count, 1)
//        XCTAssertEqual(presenter.adminViewPosts?.first?.title, testData.post.title)
//        XCTAssertEqual(presenter.adminViewUsers?.count, 1)
//        XCTAssertEqual(presenter.adminViewUsers?.first?.username, adminUser.username)
//    }
//
//}
