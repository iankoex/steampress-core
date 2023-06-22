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
