import XCTest
import Vapor
import Foundation
import SteamPressCore
import Spec

class IndexTests: XCTestCase {

    // MARK: - Properties
    var testWorld: TestWorld!
    var firstData: TestData?
    let blogIndexPath = "blog"
    let websiteURL = "https://www.steampress.io"
    let postsPerPage = 10
    
    var app: Application {
        testWorld.context.app
    }

    // MARK: - Overrides

    override func setUpWithError() throws {
        testWorld = try TestWorld.create(path: blogIndexPath, postsPerPage: postsPerPage, url: websiteURL)
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }

    // MARK: - Tests
    
    func testGetIndexReturnsOK() async throws {
        _ = try await getFirstData()
        
        try app
            .describe("Index Should Return .ok, HTML and 1 post")
            .get(blogIndexPath)
            .expect(.ok)
            .expect(.html)
            .test()
        
        XCTAssertEqual(CapturingBlogPresenter.indexPosts?.count, 1)
    }

    func testThatAccessingPathsRouteRedirectsToBlogIndex() async throws {
        try app
            .describe("Accessing /posts Should Redirrect to Index with Custom Path")
            .get("\(blogIndexPath)/posts")
            .expect(.movedPermanently)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, "/\(self.blogIndexPath)/")
            }
            .test()
    }

    // MARK: - Pagination Tests
    
    func testIndexOnlyGetsTheSpecifiedNumberOfPosts() async throws {
        let testWorld = try TestWorld.create(path: blogIndexPath, postsPerPage: postsPerPage, url: websiteURL)
        let firstData = try await testWorld.createPost(title: "Test Path", slugURL: "test-path")
        try await testWorld.createPosts(count: 15, author: firstData.author)
        
        try testWorld.context.app
            .describe("Index Should Return .ok, HTML and the specified number of posts")
            .get(blogIndexPath)
            .expect(.ok)
            .expect(.html)
            .test()
        
        XCTAssertEqual(CapturingBlogPresenter.indexPosts?.count, postsPerPage)
    }
    
//    func testIndexGetsCorrectPostsForPage() async throws {
//        try testWorld.createPosts(count: 15, author: firstData.author)
//        _ = try testWorld.getResponse(to: "/?page=2")
//        XCTAssertEqual(presenter.indexPosts?.count, 6)
//    }
//
//    // This is a bit of a dummy test since it should be handled by the DB
//    func testIndexHandlesIncorrectPageCorrectly() async throws {
//        try testWorld.createPosts(count: 15, author: firstData.author)
//        _ = try testWorld.getResponse(to: "/?page=3")
//        XCTAssertEqual(presenter.indexPosts?.count, 0)
//    }
//
//    func testIndexHandlesNegativePageCorrectly() async throws {
//        try testWorld.createPosts(count: 15, author: firstData.author)
//        _ = try testWorld.getResponse(to: "/?page=-3")
//        XCTAssertEqual(presenter.indexPosts?.count, postsPerPage)
//    }
//
//    func testIndexHandlesPageAsStringSafely() async throws {
//        try testWorld.createPosts(count: 15, author: firstData.author)
//        _ = try testWorld.getResponse(to: "/?page=three")
//        XCTAssertEqual(presenter.indexPosts?.count, postsPerPage)
//    }
//
//    func testPaginationInfoSetCorrectly() async throws {
//        try testWorld.createPosts(count: 15, author: firstData.author)
//        _ = try testWorld.getResponse(to: "/?page=2")
//        XCTAssertEqual(presenter.indexPaginationTagInfo?.currentPage, 2)
//        XCTAssertEqual(presenter.indexPaginationTagInfo?.totalPages, 2)
//        XCTAssertEqual(presenter.indexPaginationTagInfo?.currentQuery, "page=2")
//    }

    // MARK: - Page Information

    func testIndexGetsCorrectsite() async throws {
        try app
            .describe("Index Should Return .ok, HTML with correct site information")
            .get(blogIndexPath)
            .expect(.ok)
            .expect(.html)
            .test()
        
        XCTAssertNil(CapturingBlogPresenter.indexsite?.disqusName)
        XCTAssertNil(CapturingBlogPresenter.indexsite?.googleAnalyticsIdentifier)
        XCTAssertNil(CapturingBlogPresenter.indexsite?.twitterHandle)
        XCTAssertNil(CapturingBlogPresenter.indexsite?.loggedInUser)
        XCTAssertEqual(CapturingBlogPresenter.indexsite?.currentPageURL, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(CapturingBlogPresenter.indexsite?.url, "\(websiteURL)/\(blogIndexPath)/")
    }
    
    func testIndexPageCurrentPageWhenAtSubPath() async throws {
        let blogIndexPath = "blogger"
        let websiteURL = "https://www.steampress.io/community"
        let testWorld = try TestWorld.create(path: blogIndexPath, postsPerPage: postsPerPage, url: websiteURL)
        
        try testWorld.context.app
            .describe("Index Should Return .ok, HTML and the with correct site information")
            .get(blogIndexPath)
            .expect(.ok)
            .expect(.html)
            .test()
        
        XCTAssertEqual(CapturingBlogPresenter.indexsite?.currentPageURL, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(CapturingBlogPresenter.indexsite?.url, "\(websiteURL)/\(blogIndexPath)/")
    }

//    func testIndexsiteGetsLoggedInUser() async throws {
//        let owner = CreateOwnerData(name: "Steam Press", password: "SP@Password", email: "admin@steampress.io")
//
//        try app
//            .describe("App should create and log in user")
//            .post("\(blogIndexPath)/steampress/createOwner/")
//            .body(owner)
//            .expect(.seeOther)
//            .test()
//
//        try app
//            .describe("Index Should Return .ok, HTML and 1 post")
//            .get(blogIndexPath)
//            .expect(.ok)
//            .expect(.html)
//            .test()
//
//        XCTAssertEqual(CapturingBlogPresenter.indexsite?.loggedInUser?.email, owner.email)
//        XCTAssertEqual(CapturingBlogPresenter.indexsite?.loggedInUser?.name, owner.name)
//
//    }

    func testSettingEnvVarsWithsite() async throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        
        try testWorld.context.app
            .describe("Index Should Return .ok, HTML and the with correct site information")
            .get(blogIndexPath)
            .expect(.ok)
            .expect(.html)
            .test()
        
        XCTAssertEqual(CapturingBlogPresenter.indexsite?.disqusName, disqusName)
        XCTAssertEqual(CapturingBlogPresenter.indexsite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(CapturingBlogPresenter.indexsite?.twitterHandle, twitterHandle)
    }
    
    
    // MARK: - Helpers
    
    func getFirstData() async throws -> TestData {
        guard let data = firstData else {
            firstData = try await testWorld.createPost(title: "Test Path", slugURL: "test-path")
            return try await getFirstData()
        }
        return data
    }
}
