import XCTest
import Vapor
import SteamPressCore

class AccessControlTests: XCTestCase {

    // MARK: - Properties
    private var app: Application!
    private var testWorld: TestWorld!
    private var user: BlogUser?

    // MARK: - Overrides

    override func setUpWithError() throws {
        testWorld = try TestWorld.create(path: "blog")
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }

    // MARK: - Tests

    // MARK: - Access restriction tests

    func testCannotAccessAdminPageWithoutBeingLoggedIn() async throws {
        try await assertLoginRequired(method: .GET, path: "")
    }

    func testCannotAccessCreateBlogPostPageWithoutBeingLoggedIn() async throws {
        try await assertLoginRequired(method: .GET, path: "createPost")
    }

    func testCannotSendCreateBlogPostPageWithoutBeingLoggedIn() async throws {
        try await assertLoginRequired(method: .POST, path: "createPost")
    }

    func testCannotAccessPostsPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "posts")
    }

    func testCannotAccessEditPostPageWithoutLogin() async throws {
        let testData = try await testWorld.createPost()
        try await assertLoginRequired(method: .GET, path: "posts/\(testData.post.id!)")
    }

    func testCannotSendEditPostPageWithoutLogin() async throws {
        let testData = try await testWorld.createPost()
        try await assertLoginRequired(method: .POST, path: "posts/\(testData.post.id!)")
    }

    func testCannotAccessDeletePostPageWithoutLogin() async throws {
        let testData = try await testWorld.createPost()
        try await assertLoginRequired(method: .GET, path: "posts/\(testData.post.id!)/delete")
    }

    func testCannotAccessMembersPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "members")
    }

    func testCannotAccessCreateMemberPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "members/new")
    }

    func testCannotSendCreateMemberPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .POST, path: "members/new")
    }

    func testCannotAccessEditMemberPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "members/\(UUID())")
    }

    func testCannotSendEditMemberPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .POST, path: "members/\(UUID())")
    }

    func testCannotDeleteMemberWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "members/\(UUID())/delete")
    }
    
    func testCannotAccessTagsPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "tags")
    }
    
    func testCannotAccessCreateTagPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "tags/new")
    }
    
    func testCannotSendCreateTagPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .POST, path: "tags/new")
    }
    
    func testCannotAccessEditTagPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "tags/events")
    }
    
    func testCannotSendEditTagPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .POST, path: "tags/events")
    }
    
    func testCannotDeleteTagWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "tags/events/delete")
    }

    func testCannotAccessResetPasswordPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .GET, path: "resetPassword")
    }

    func testCannotSendResetPasswordPageWithoutLogin() async throws {
        try await assertLoginRequired(method: .POST, path: "resetPassword")
    }

    // MARK: - Access Success Tests

    func testCanAccessAdminPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessCreatePostPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/createPost", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessPostCreatePostPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/createPost", method: .POST, loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }

    func testCanAccessEditPostPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let testData = try await testWorld.createPost()
        let response = try await testWorld.getResponse(to: "/blog/steampress/posts/\(testData.post.id!)", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessPostEditPostPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let testData = try await testWorld.createPost()
        let response = try await testWorld.getResponse(to: "/blog/steampress/posts/\(testData.post.id!)", method: .POST, loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessDeletePostPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let testData = try await testWorld.createPost()
        let response = try await testWorld.getResponse(to: "/blog/steampress/posts/\(testData.post.id!)/delete", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
   
    func testCanAccessMembersPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/members", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessCreateMemberPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/members/new", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessPostCreateMemberPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/members/new", method: .POST, loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessEditMemberPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/members/\(user.id!)", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessPostEditMemberPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/members/\(user.id!)", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessDeleteMemberWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/members/\(user.id!)/delete", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessTagsPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/tags", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessCreateTagPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/tags/new", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessPostCreateTagPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/tags/new", method: .POST, loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessEditTagPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/tags/events", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessPostEditTagPageWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/tags/events", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testCanAccessDeleteTagWhenLoggedIn() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/tags/events/delete", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }

    func testCanAccessResetPasswordPage() async throws {
        let user = try await createUserIfNonExists()
        let response = try await testWorld.getResponse(to: "/blog/steampress/resetPassword", loggedInUser: user)
        XCTAssertEqual(response.status, .ok)
    }

    // MARK: - Helpers

    private func assertLoginRequired(method: HTTPMethod, path: String) async throws {
        let response = try await testWorld.getResponse(to: "/blog/steampress/\(path)", method: method)

        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/blog/steampress/login/?loginRequired")
    }

    private func createUserIfNonExists() async throws -> BlogUser {
        guard let user = user else {
            user = try await testWorld.createUser()
            return user!
        }
        return user
    }
}
