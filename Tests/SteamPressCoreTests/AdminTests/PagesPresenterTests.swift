import XCTest
import Vapor
@testable import SteamPressCore

class PagesPresenterTests: XCTestCase {
    
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
    
    // MARK: - Admin Pages Tests
    
    func testIndexPassesCorrectInformationToPresenter() throws {
        try app
            .describe("Correct Information is Passed to the Presenter at Index (Dashboard)")
            .get(adminPath(for: ""))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNil(CapturingAdminPresenter.indexViewErrors)
        XCTAssertEqual(CapturingAdminPresenter.indexViewUsersCount, 1)
        XCTAssertNotNil(CapturingAdminPresenter.indexViewSite)
        let site = try XCTUnwrap(CapturingAdminPresenter.indexViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: ""))")
    }
    
    func testExplorePassesCorrectInformationToPresenter() throws {
        try app
            .describe("Correct Information is Passed to the Presenter at Explore")
            .get(adminPath(for: "explore"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNil(CapturingAdminPresenter.exploreViewErrors)
        XCTAssertEqual(CapturingAdminPresenter.exploreViewUsersCount, 1)
        XCTAssertNotNil(CapturingAdminPresenter.exploreViewSite)
        let site = try XCTUnwrap(CapturingAdminPresenter.exploreViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "explore"))/")
    }
    
    func testPagesPassesCorrectInformationToPresenter() throws {
        try app
            .describe("Correct Information is Passed to the Presenter at Explore")
            .get(adminPath(for: "pages"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNil(CapturingAdminPresenter.pagesViewErrors)
        XCTAssertEqual(CapturingAdminPresenter.pagesViewUsersCount, 1)
        XCTAssertNotNil(CapturingAdminPresenter.pagesViewSite)
        let site = try XCTUnwrap(CapturingAdminPresenter.pagesViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "pages"))/")
    }
    
    // MARK: - Reset Password Page Tests
    
    func testPresenterGetsCorrectInformationForResetPasswordPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for ResetPassword Page")
            .get(adminPath(for: "resetPassword"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNil(CapturingAdminPresenter.resetPasswordErrors)
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.loggedInUser?.name, owner.name)
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.loggedInUser?.email, owner.email)
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.currentPageURL, "\(websiteURL)\(adminPath(for: "resetPassword"))/")
    }
    
    // MARK: - Members Page Tests
    
    func testPresenterGetsCorrectValuesForMembersPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for Members Page")
            .get(adminPath(for: "members"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createMembersViewUsers)
        XCTAssertEqual(CapturingAdminPresenter.createMembersViewUsersCount, 1)
        let site = try XCTUnwrap(CapturingAdminPresenter.createMembersViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "members"))/")
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
        XCTAssertEqual(CapturingAdminPresenter.createCreateMembersViewUsersCount, 1)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateMembersViewSite)
        let site = try XCTUnwrap(CapturingAdminPresenter.createCreateMembersViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "members/new"))/")
    }
    
    // MARK: - Tags Page Tests
    
    func testPresenterGetsCorrectValuesForTagsPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for Tags Page")
            .get(adminPath(for: "tags"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createTagsViewTags)
        XCTAssertEqual(CapturingAdminPresenter.createTagsViewTags?.count, 0)
        XCTAssertEqual(CapturingAdminPresenter.createTagsViewUsersCount, 1)
        let site = try XCTUnwrap(CapturingAdminPresenter.createTagsViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "tags"))/")
    }
    
    func testPresenterGetsCorrectValuesForNewTagPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for New Tags Page")
            .get(adminPath(for: "tags/new"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertEqual(CapturingAdminPresenter.createCreateTagsViewUsersCount, 1)
        let site = try XCTUnwrap(CapturingAdminPresenter.createCreateTagsViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "tags/new"))/")
    }
    
    // MARK: - Posts Page Tests
    
    func testPresenterGetsCorrectValuesForPostsPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for Posts Page")
            .get(adminPath(for: "posts"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createPostsViewPosts)
        XCTAssertEqual(CapturingAdminPresenter.createPostsViewPosts?.count, 0)
        XCTAssertEqual(CapturingAdminPresenter.createPostsViewUsersCount, 1)
        let site = try XCTUnwrap(CapturingAdminPresenter.createPostsViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "posts"))/")
    }
    
    func testPresenterGetsCorrectValuesForNewPostPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for New Posts Page")
            .get(adminPath(for: "posts/new"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNil(CapturingAdminPresenter.createPostViewErrors)
        XCTAssertNotNil(CapturingAdminPresenter.createPostViewTags)
        XCTAssertEqual(CapturingAdminPresenter.createPostViewTags?.count, 0)
        XCTAssertNil(CapturingAdminPresenter.createPostViewPost)
        XCTAssertNil(CapturingAdminPresenter.createPostViewTitleSupplied)
        XCTAssertNil(CapturingAdminPresenter.createPostViewContentSupplied)
        XCTAssertNil(CapturingAdminPresenter.createPostViewSnippetSupplied)
        let site = try XCTUnwrap(CapturingAdminPresenter.createPostViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "posts/new"))/")
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
