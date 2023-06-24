import XCTest
import Vapor
import Spec
import SteamPressCore

class AccessRestrictedTests: XCTestCase {

    // MARK: - Properties
    
    private var testWorld: TestWorld!
    private var user: BlogUser?
    private let blogIndexPath = "blog"
    
    var app: Application {
        testWorld.context.app
    }

    // MARK: - Overrides

    override func setUpWithError() throws {
        testWorld = try TestWorld.create(path: "\(blogIndexPath)")
    }

    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }

    // MARK: - Access Restricted tests

    func testCannotAccessAdminPageWithoutBeingLoggedIn() async throws {
        try assertLoginRequired(method: .GET, path: "")
    }

    func testCannotAccessPostsPageWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "posts")
    }
    
    func testCannotAccessCreateBlogPostPageWithoutBeingLoggedIn() async throws {
        try assertLoginRequired(method: .GET, path: "posts/new")
    }
    
    func testCannotSendCreateBlogPostPageWithoutBeingLoggedIn() async throws {
        try assertLoginRequired(method: .POST, path: "posts/new")
    }

    func testCannotAccessEditPostPageWithoutLogin() async throws {
        let testData = try await testWorld.createPost()
        try assertLoginRequired(method: .GET, path: "posts/\(testData.post.id!)")
    }

    func testCannotSendEditPostPageWithoutLogin() async throws {
        let testData = try await testWorld.createPost()
        try assertLoginRequired(method: .POST, path: "posts/\(testData.post.id!)")
    }

    func testCannotAccessDeletePostPageWithoutLogin() async throws {
        let testData = try await testWorld.createPost()
        try assertLoginRequired(method: .GET, path: "posts/\(testData.post.id!)/delete")
    }

    func testCannotAccessMembersPageWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "members")
    }

    func testCannotAccessCreateMemberPageWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "members/new")
    }

    func testCannotSendCreateMemberPageWithoutLogin() async throws {
        try assertLoginRequired(method: .POST, path: "members/new")
    }

    func testCannotAccessEditMemberPageWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "members/\(UUID())")
    }

    func testCannotSendEditMemberPageWithoutLogin() async throws {
        try assertLoginRequired(method: .POST, path: "members/\(UUID())")
    }

    func testCannotDeleteMemberWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "members/\(UUID())/delete")
    }

    func testCannotAccessTagsPageWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "tags")
    }

    func testCannotAccessCreateTagPageWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "tags/new")
    }

    func testCannotSendCreateTagPageWithoutLogin() async throws {
        try assertLoginRequired(method: .POST, path: "tags/new")
    }

    func testCannotAccessEditTagPageWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "tags/events")
    }

    func testCannotSendEditTagPageWithoutLogin() async throws {
        try assertLoginRequired(method: .POST, path: "tags/events")
    }

    func testCannotDeleteTagWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "tags/events/delete")
    }

    func testCannotAccessResetPasswordPageWithoutLogin() async throws {
        try assertLoginRequired(method: .GET, path: "resetPassword")
    }

    func testCannotSendResetPasswordPageWithoutLogin() async throws {
        try assertLoginRequired(method: .POST, path: "resetPassword")
    }
    
    // MARK: - Helpers

    private func assertLoginRequired(method: HTTPMethod, path: String) throws {
        try app
            .describe("Assert Login Required When Accessing \(path) using method: \(method)")
            .on(method, adminPath(for: path))
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "login?loginRequired=true"))
            }
            .test()
    }
    
    private func adminPath(for path: String) -> String {
        return "/\(blogIndexPath)/steampress/\(path)"
    }
}
