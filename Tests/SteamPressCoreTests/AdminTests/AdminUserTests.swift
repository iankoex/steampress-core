import XCTest
import Vapor
@testable import SteamPressCore

class AdminUserTests: XCTestCase {
    
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
    
    // MARK: - User Creation
    
    func testPresenterGetsCorrectValuesForMembersPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for Members Page")
            .get(adminPath(for: "members"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createMembersViewUsers)
        XCTAssertNotNil(CapturingAdminPresenter.createMembersViewSite)
        XCTAssertEqual(CapturingAdminPresenter.createMembersViewUsersCount, 1)
        XCTAssertEqual(CapturingAdminPresenter.createMembersViewSite?.loggedInUser?.name, owner.name)
        XCTAssertEqual(CapturingAdminPresenter.createMembersViewSite?.loggedInUser?.email, owner.email)
        XCTAssertEqual(CapturingAdminPresenter.createMembersViewSite?.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(CapturingAdminPresenter.createMembersViewSite?.currentPageURL, "\(websiteURL)\(adminPath(for: "members"))/")
    }
    
    func testPresenterGetsCorrectValuesForNewMembersPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for New Members Page")
            .get(adminPath(for: "members/new"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewSite)
        XCTAssertEqual(CapturingAdminPresenter.createCreateMembersViewUsersCount, 1)
        XCTAssertEqual(CapturingAdminPresenter.createCreateMembersViewSite?.loggedInUser?.name, owner.name)
        XCTAssertEqual(CapturingAdminPresenter.createCreateMembersViewSite?.loggedInUser?.email, owner.email)
        XCTAssertEqual(CapturingAdminPresenter.createCreateMembersViewSite?.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(CapturingAdminPresenter.createCreateMembersViewSite?.currentPageURL, "\(websiteURL)\(adminPath(for: "members/new"))/")
    }
    
    func testUserCanBeCreatedSuccessfully() async throws {
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
        XCTAssertEqual(user.username, createData.username)
        XCTAssertEqual(user.name, createData.name)
        XCTAssertEqual(user.email, createData.email)
        XCTAssertEqual(user.profilePicture, createData.profilePicture)
        XCTAssertEqual(user.tagline, createData.tagline)
        XCTAssertEqual(user.biography, createData.biography)
        XCTAssertEqual(user.twitterHandle, createData.twitterHandle)
    }
    
    func testUserHasNoAdditionalInfoIfEmptyStringsSent() async throws {
        let createData = CreateUserData(
            name: "Luke",
            username: "lukes",
            password: "somePassword",
            confirmPassword: "somePassword",
            email: "luke@lukes.com",
            profilePicture: nil,
            tagline: nil,
            biography: nil,
            twitterHandle: nil,
            resetPasswordOnLogin: nil
        )
        
        try app
            .describe("New User Can be Created Successfully With Optionals Missing")
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
        XCTAssertEqual(user.username, createData.username)
        XCTAssertEqual(user.name, createData.name)
        XCTAssertEqual(user.email, createData.email)
        XCTAssertNil(user.profilePicture)
        XCTAssertNil(user.tagline)
        XCTAssertNil(user.biography)
        XCTAssertNil(user.twitterHandle)
    }
    
    func testUserMustResetPasswordAfterCreatingUserEvenIfWasSetToFalse() async throws {
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
            resetPasswordOnLogin: false
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
        XCTAssertEqual(user.email, createData.email)
        XCTAssertTrue(user.resetPasswordRequired)
    }
    
    func testUserCannotBeCreatedWithRequiredFieldsMissingOrWhitespace() throws {
        let createData = CreateUserData(
            name: "",
            username: "",
            password: "",
            confirmPassword: "",
            email: "  ", // whitespace character
            profilePicture: "https://static.brokenhands.io/images/cat.png",
            tagline: "awesomest",
            biography: "bio bio bio",
            twitterHandle: "lukes",
            resetPasswordOnLogin: true
        )
        
        try app
            .describe("New Cannot Be Created With Required Fields Missing or Whitespace")
            .post(adminPath(for: "members/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("You must specify a name"))
        XCTAssertTrue(errors.contains("You must specify a username"))
        XCTAssertTrue(errors.contains("You must specify an email"))
        XCTAssertTrue(errors.contains("You must specify a password"))
        XCTAssertTrue(errors.contains("You must confirm your password"))
    }
    
    func testUserCannotBeCreatedWithShortOrMismatchingPasswords() throws {
        let createData = CreateUserData(
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
            .describe("New User Cannot Be Created With Short or Mismatching Passwords")
            .post(adminPath(for: "members/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("Your password must be at least 8 characters long"))
        XCTAssertTrue(errors.contains("Your passwords must match"))
    }
    
    func testUserCannotBeCreatedWithAnInvalidUsername() throws {
        let createData = CreateUserData(
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
            .describe("New User Cannot Be Created With An Invalid Username")
            .post(adminPath(for: "members/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("The username provided is not valid"))
    }
    
    func testUserCannotBeCreatedWithUsernameThatAlreadyExists() throws {
        let createData = CreateUserData(
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
            .describe("New User Cannot Be Created With Username That Already Exists")
            .post(adminPath(for: "members/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("Sorry that username has already been taken"))
    }
    
    func testUserCannotBeCreatedWithUsernameThatAlreadyExistsIgnoringCase() throws {
        let createData = CreateUserData(
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
            .describe("New User Cannot Be Created With Username That Already Exists Ignoring Case")
            .post(adminPath(for: "members/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("Sorry that username has already been taken"))
    }
    
    func testPasswordIsActuallyHashedWhenCreatingAUser() async throws {
        let userPassword = "somePassword"
        let hashedPassword = try await testWorld.context.req.password.async.hash(userPassword)
        
        let createData = CreateUserData(
            name: "Luke",
            username: "lukes",
            password: userPassword,
            confirmPassword: userPassword,
            email: "luke@lukes.com",
            profilePicture: "https://static.brokenhands.io/images/cat.png",
            tagline: "awesomest",
            biography: "bio bio bio",
            twitterHandle: "lukes",
            resetPasswordOnLogin: false
        )
        
        try testWorld.context.app
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
        XCTAssertNotEqual(user.password, userPassword)
        XCTAssertTrue(try testWorld.context.req.password.verify(userPassword, created: user.password))
//        XCTAssertEqual(user.password, hashedPassword)
    }
    
    // MARK: - Edit Users
    
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
    
    
    // MARK: - Helpers
    
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

//
//    func testUserCanBeUpdated() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Darth Vader"
//            let username = "darth_vader"
//        }
//
//        let editData = EditUserData()
//        let response = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertEqual(updatedUser.username, editData.username)
//        XCTAssertEqual(updatedUser.name, editData.name)
//        XCTAssertEqual(updatedUser.id, user.id)
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/admin/")
//    }
//    
//    func testUserCanBeUpdatedWithSameUsername() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Leia Organa"
//            let username = "leia"
//        }
//
//        let editData = EditUserData()
//        let response = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertEqual(updatedUser.username, editData.username)
//        XCTAssertEqual(updatedUser.name, editData.name)
//        XCTAssertEqual(updatedUser.id, user.id)
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/admin/")
//    }
//
//    func testUserCanBeUpdatedWithAllInformation() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Darth Vader"
//            let username = "darth_vader"
//            let twitterHandle = "darthVader"
//            let profilePicture = "https://deathstar.org/pictures/dv.jpg"
//            let tagline = "The Sith Lord formally known as Anakin"
//            let biography = "Father of one, part cyborg, Sith Lord. Something something dark side."
//        }
//
//        let editData = EditUserData()
//        let response = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertEqual(updatedUser.username, editData.username)
//        XCTAssertEqual(updatedUser.name, editData.name)
//        XCTAssertEqual(updatedUser.twitterHandle, editData.twitterHandle)
//        XCTAssertEqual(updatedUser.profilePicture, editData.profilePicture)
//        XCTAssertEqual(updatedUser.tagline, editData.tagline)
//        XCTAssertEqual(updatedUser.biography, editData.biography)
//        XCTAssertEqual(updatedUser.id, user.id)
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/admin/")
//    }
//    
//    func testOptionalInfoDoesntGetUpdatedWhenEditingUsernameAndSendingEmptyValuesIfSomeAlreadySet() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Darth Vader"
//            let username = "darth_vader"
//            let twitterHandle = ""
//            let profilePicture = ""
//            let tagline = ""
//            let biography = ""
//        }
//        
//        user.profilePicture = nil
//        user.twitterHandle = nil
//        user.tagline = nil
//        user.biography = nil
//
//        let editData = EditUserData()
//        _ = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertEqual(updatedUser.username, editData.username)
//        XCTAssertEqual(updatedUser.name, editData.name)
//        XCTAssertNil(updatedUser.twitterHandle)
//        XCTAssertNil(updatedUser.profilePicture)
//        XCTAssertNil(updatedUser.tagline)
//        XCTAssertNil(updatedUser.biography)
//        XCTAssertEqual(updatedUser.id, user.id)
//    }
//    
//    func testUpdatingOptionalInfoToEmptyValuesWhenValueOriginallySetSetsItToNil() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Darth Vader"
//            let username = "darth_vader"
//            let twitterHandle = ""
//            let profilePicture = ""
//            let tagline = ""
//            let biography = ""
//        }
//
//        user.profilePicture = "https://static.brokenhands.io/picture.png"
//        user.tagline = "Tagline"
//        user.biography = "Biography"
//        user.twitterHandle = "darthVader"
//        let editData = EditUserData()
//        _ = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertEqual(updatedUser.username, editData.username)
//        XCTAssertEqual(updatedUser.name, editData.name)
//        XCTAssertNil(updatedUser.twitterHandle)
//        XCTAssertNil(updatedUser.profilePicture)
//        XCTAssertNil(updatedUser.tagline)
//        XCTAssertNil(updatedUser.biography)
//        XCTAssertEqual(updatedUser.id, user.id)
//    }
//
//    func testWhenEditingUserResetPasswordFlagSetIfRequired() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Luke"
//            let username = "lukes"
//            let resetPasswordOnLogin = true
//        }
//
//        let editData = EditUserData()
//        let response = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertTrue(updatedUser.resetPasswordRequired)
//        XCTAssertEqual(updatedUser.id, user.id)
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/admin/")
//    }
//
//    func testWhenEditingUserResetPasswordFlagNotSetIfSetToFalse() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Luke"
//            let username = "lukes"
//            let resetPasswordOnLogin = false
//        }
//
//        let editData = EditUserData()
//        let response = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertFalse(updatedUser.resetPasswordRequired)
//        XCTAssertEqual(updatedUser.id, user.id)
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/admin/")
//    }
//
//    func testPasswordIsUpdatedWhenNewPasswordProvidedWhenEditingUser() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Luke"
//            let username = "lukes"
//            let password = "anewpassword"
//            let confirmPassword = "anewpassword"
//        }
//
//        let editData = EditUserData()
//        let response = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertEqual(updatedUser.password, editData.password)
//        XCTAssertEqual(updatedUser.id, user.id)
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/admin/")
//    }
//    
//    func testPasswordIsNotUpdatedWhenEmptyPasswordProvidedWhenEditingUser() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Luke"
//            let username = "lukes"
//            let password = ""
//            let confirmPassword = ""
//        }
//
//        let oldPassword = user.password
//        let editData = EditUserData()
//        let response = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.users.count, 1)
//        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
//        XCTAssertEqual(updatedUser.password, oldPassword)
//        XCTAssertEqual(updatedUser.id, user.id)
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/admin/")
//    }
//
//    func testErrorShownWhenUpdatingUsersPasswordWithNonMatchingPasswords() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Luke"
//            let username = "lukes"
//            let password = "anewpassword"
//            let confirmPassword = "someotherpassword"
//        }
//
//        let editData = EditUserData()
//        _ = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
//        XCTAssertTrue(viewErrors.contains("Your passwords must match"))
//        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
//        let confirmPasswordError = try XCTUnwrap(presenter.createUserConfirmPasswordError)
//        XCTAssertEqual(presenter.createUserUserID, user.id)
//        XCTAssertTrue(passwordError)
//        XCTAssertTrue(confirmPasswordError)
//    }
//
//    func testErrorShownWhenChangingUsersPasswordWithShortPassword() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Luke"
//            let username = "lukes"
//            let password = "a"
//            let confirmPassword = "a"
//        }
//
//        let editData = EditUserData()
//        _ = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
//        XCTAssertTrue(viewErrors.contains("Your password must be at least 10 characters long"))
//        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
//        XCTAssertTrue(passwordError)
//    }
//
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
//    func testNameMustBeSetWhenEditingAUser() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = ""
//            let username = "darth_vader"
//            let password = "somenewpassword"
//            let confirmPassword = "somenewpassword"
//        }
//
//        let editData = EditUserData()
//        _ = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        let editErrors = try XCTUnwrap(presenter.createUserErrors)
//        XCTAssertTrue(editErrors.contains("You must specify a name"))
//        let nameError = try XCTUnwrap(presenter.createUserNameError)
//        XCTAssertTrue(nameError)
//    }
//
//    func testUsernameMustBeSetWhenEditingAUser() throws {
//        struct EditUserData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let name = "Darth Vader"
//            let username = ""
//            let password = "somenewpassword"
//            let confirmPassword = "somenewpassword"
//        }
//
//        let editData = EditUserData()
//        _ = try testWorld.getResponse(to: "/admin/users/\(user.id!)/edit", body: editData, loggedInUser: user)
//
//        let editErrors = try XCTUnwrap(presenter.createUserErrors)
//        XCTAssertTrue(editErrors.contains("You must specify a username"))
//        let usernameError = try XCTUnwrap(presenter.createUserUsernameError)
//        XCTAssertTrue(usernameError)
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
