import XCTest
import Vapor
@testable import SteamPressCore

class AdminPagesTests: XCTestCase {
    
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
