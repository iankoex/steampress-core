import XCTest
import Vapor
import Spec
import SteamPressCore

class AccessAllowedTests: XCTestCase {
    
    // MARK: - Properties
    
    private var testWorld: TestWorld!
    private var user: BlogUser?
    private let blogIndexPath = "blog"
    private var sessionCookie: HTTPCookies!
    private var testData: TestData?
    
    var app: Application {
        testWorld.context.app
    }
    
    // MARK: - Overrides
    
    override func setUpWithError() throws {
        testWorld = try TestWorld.create(path: "\(blogIndexPath)")
        sessionCookie = try createAndLoginOwner()
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }
    
    // MARK: - Access Allowed Tests
    
    func testCanAccessAdminPageWhenLoggedIn() async throws {
        try assertCanAccess(path: "", method: .GET)
    }
    
    func testCanAccessCreatePostPageWhenLoggedIn() async throws {
        try assertCanAccess(path: "posts/new", method: .GET)
    }
    
    func testCanAccessPostCreatePostPageWhenLoggedIn() async throws {
        let testData = try await getTestData()
        let body = CreatePostData(title: "q", contents: "q", snippet: "q", isDraft: false, tags: [testData.tag.name])
        try assertCanAccess(path: "posts/new", method: .POST, body: body, expectStatus: .seeOther)
    }
    
    func testCanAccessEditPostPageWhenLoggedIn() async throws {
        let testData = try await getTestData()
        try assertCanAccess(path: "posts/\(testData.post.id!)", method: .GET)
    }
    
    func testCanAccessAPostEditPostPageWhenLoggedIn() async throws {
        let testData = try await getTestData()
        let body = CreatePostData(title: "q", contents: "q", snippet: "q", isDraft: false, tags: [testData.tag.name])
        try assertCanAccess(path: "posts/\(testData.post.id!)", method: .POST, body: body, expectStatus: .seeOther)
    }
    
    func testCanAccessDeletePostWhenLoggedIn() async throws {
        let testData = try await getTestData()
        try assertCanAccess(path: "posts/\(testData.post.id!)/delete", method: .GET, expectStatus: .seeOther)
    }
    
    func testCanAccessMembersPageWhenLoggedIn() async throws {
        try assertCanAccess(path: "members", method: .GET)
    }
    
    func testCanAccessCreateMemberPageWhenLoggedIn() async throws {
        try assertCanAccess(path: "members/new", method: .GET)
    }
    
    func testCanAccessPostCreateMemberPageWhenLoggedIn() async throws {
        let body = CreateUserData(name: "q", username: "q", password: "q8characters", confirmPassword: "q8characters", email: "q@q.q")
        try assertCanAccess(path: "members/new", method: .POST, body: body, expectStatus: .seeOther)
    }
    
    func testCanAccessEditMemberPageWhenLoggedIn() async throws {
        let testData = try await getTestData()
        try assertCanAccess(path: "members/\(testData.author.id!)", method: .GET)
    }
    
    func testCanAccessPostEditMemberPageWhenLoggedIn() async throws {
        let testData = try await getTestData()
        let body = CreateUserData(name: "q", username: "q", password: "q8characters", confirmPassword: "q8characters", email: "q@q.q")
        try assertCanAccess(path: "members/\(testData.author.id!)", method: .POST, body: body, expectStatus: .seeOther)
    }
    
    func testCanAccessDeleteMemberWhenLoggedIn() async throws {
        let testData = try await getTestData()
        try assertCanAccess(path: "members/\(testData.author.id!)/delete", method: .GET)
    }
    
    func testCanAccessTagsPageWhenLoggedIn() async throws {
        try assertCanAccess(path: "tags", method: .GET)
    }
    
    func testCanAccessCreateTagPageWhenLoggedIn() async throws {
        try assertCanAccess(path: "tags/new", method: .GET)
    }
    
    func testCanAccessPostCreateTagPageWhenLoggedIn() async throws {
        let body = CreateTagData(name: "some")
        try assertCanAccess(path: "tags/new", method: .POST, body: body, expectStatus: .seeOther)
    }
    
    func testCanAccessEditTagPageWhenLoggedIn() async throws {
        let testData = try await getTestData()
        try assertCanAccess(path: "tags/\(testData.tag.slugURL)", method: .GET)
    }
    
    func testCanAccessPostEditTagPageWhenLoggedIn() async throws {
        let testData = try await getTestData()
        let body = CreateTagData(name: "some")
        try assertCanAccess(path: "tags/\(testData.tag.slugURL)", method: .POST, body: body, expectStatus: .seeOther)
    }
    
    func testCanAccessDeleteTagWhenLoggedIn() async throws {
        let testData = try await getTestData()
        try assertCanAccess(path: "tags/\(testData.tag.slugURL)/delete", method: .GET, expectStatus: .seeOther)
    }
    
    func testCanAccessResetPasswordPage() async throws {
        try assertCanAccess(path: "resetPassword", method: .GET)
    }
    
    // MARK: - Helpers
    
    private func assertCanAccess(path: String, method: HTTPMethod, expectStatus: HTTPStatus = .ok) throws {
        try assertCanAccess(path: path, method: method, body: EmptyContent(), expectStatus: expectStatus)
    }
    
    private func assertCanAccess<V: Content>(path: String, method: HTTPMethod, body: V, expectStatus: HTTPStatus = .ok) throws {
        try app
            .describe("Assert Can Access \(path) using method: \(method)")
            .on(method, adminPath(for: path))
            .body(body)
            .cookie(sessionCookie)
            .expect(expectStatus)
            .test()
    }
    
    private func createAndLoginOwner() throws -> HTTPCookies {
        var cookie: HTTPCookies = HTTPCookies()
        let owner = CreateOwnerData(name: "Steam Press Owner", password: "SP@Password", email: "admin@steampress.io")
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
    
    private func getTestData() async throws -> TestData {
        if let data = testData {
            return data
        }
        testData = try await testWorld.createPost()
        return try await getTestData()
    }
    
    private func adminPath(for path: String) -> String {
        return "/\(blogIndexPath)/steampress/\(path)"
    }
}
