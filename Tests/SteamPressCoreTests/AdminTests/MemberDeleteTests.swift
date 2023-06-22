import XCTest
import Vapor
@testable import SteamPressCore

class MemberDeleteTests: XCTestCase {
    
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
    
    // MARK: - Delete Member
  
    func testCanDeleteUser() async throws {
        let user = try await createAndReturnUser()
        
        try app
            .describe("Can Delete User")
            .get(adminPath(for: "members/\(user.id!)/delete"))
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "members/"))
            }
            .test()
        
        let users = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // Only owner remains
        XCTAssertEqual(users.count, 1)
    }
    
    func testOwnerCannotBeDeleted() async throws {
        let users = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        XCTAssertEqual(users.count, 1)
        let owner = try XCTUnwrap(users.first)
        
        try app
            .describe("Owner Cannot Be Deleted")
            .get(adminPath(for: "members/\(owner.id!)/delete"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        let users2 = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // Non was deleted so one remain
        XCTAssertEqual(users2.count, 1)
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("Owner cannot be deleted"))
        XCTAssertTrue(errors.contains("You cannot self delete"))
    }
    
    func testMemberOfTypeMemberCannotDeleteAnotherMember() async throws {
        let (user, cookie) = try await createAndLoginUser()
        
        try app
            .describe("Member of type=.member Cannot Delete Another Member or Self")
            .get(adminPath(for: "members/\(user.id!)/delete"))
            .cookie(cookie)
            .expect(.ok)
            .test()
        
        let users = try await testWorld.context.req.repositories.blogUser.getAllUsers()
        // Non was deleted so two remain
        XCTAssertEqual(users.count, 2)
        
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewUserData)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewErrors)
        XCTAssertTrue(errors.contains("You do not have permissions to delete a member"))
        XCTAssertTrue(errors.contains("You cannot self delete"))
    }
    
    // MARK: - Helpers
    
    private func createAndLoginUser() async throws -> (BlogUser, HTTPCookies) {
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
        
        return (user, cookie)
    }
    
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
