import XCTest
import SteamPressCore
import Vapor
import Foundation

class SearchTests: XCTestCase {

    // MARK: - Properties
    var testWorld: TestWorld!
    var firstData: TestData!

    var presenter: CapturingBlogPresenter {
        return testWorld.context.blogPresenter
    }

    // MARK: - Overrides

    override func setUpWithError() throws {
        testWorld = try TestWorld.create(url: "/")
        firstData = try testWorld.createPost(title: "Test Path", slugUrl: "test-path")
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }

    // MARK: - Tests

    func testBlogPassedToSearchPageCorrectly() throws {
        let response = try testWorld.getResponse(to: "/search?term=Test")

        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(presenter.searchTerm, "Test")
        XCTAssertEqual(presenter.searchTotalResults, 1)
        XCTAssertEqual(presenter.searchPosts?.first?.title, firstData.post.title)
    }

    func testThatSearchTermNilIfEmptySearch() throws {
        let response = try testWorld.getResponse(to: "/search?term=")

        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(presenter.searchPosts?.count, 0)
        XCTAssertNil(presenter.searchTerm)
    }

    func testThatSearchTermNilIfNoSearchTerm() throws {
        let response = try testWorld.getResponse(to: "/search")

        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(presenter.searchPosts?.count, 0)
        XCTAssertNil(presenter.searchTerm)
    }
    
    func testCorrectsiteForSearch() throws {
        _ = try testWorld.getResponse(to: "/search?term=Test")
        XCTAssertNil(presenter.searchsite?.disqusName)
        XCTAssertNil(presenter.searchsite?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.searchsite?.twitterHandle)
        XCTAssertNil(presenter.searchsite?.loggedInUser)
        XCTAssertEqual(presenter.searchsite?.currentPageURL.absoluteString, "/search")
        XCTAssertEqual(presenter.searchsite?.url.absoluteString, "/")
    }
    
    func testsiteGetsLoggedInUserForSearch() throws {
        _ = try testWorld.getResponse(to: "/search?term=Test", loggedInUser: firstData.author)
        XCTAssertEqual(presenter.searchsite?.loggedInUser?.username, firstData.author.username)
    }
    
    func testSettingEnvVarsWithsiteForSearch() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: "/search?term=Test")
        XCTAssertEqual(presenter.searchsite?.disqusName, disqusName)
        XCTAssertEqual(presenter.searchsite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.searchsite?.twitterHandle, twitterHandle)
    }
    
    func testPaginationInfoSetCorrectly() throws {
        try testWorld.createPosts(count: 15, author: firstData.author)
        _ = try testWorld.getResponse(to: "/search?term=Test&page=1")
        XCTAssertEqual(presenter.searchPaginationTagInfo?.currentPage, 1)
        XCTAssertEqual(presenter.searchPaginationTagInfo?.totalPages, 1)
        XCTAssertEqual(presenter.searchPaginationTagInfo?.currentQuery, "term=Test&page=1")
    }
    
    func testTagsForSearchPostsSetCorrectly() throws {
        let post2 = try testWorld.createPost(title: "Test Search", author: firstData.author)
        let post3 = try testWorld.createPost(title: "Test Tags", author: firstData.author)
        let tag1Name = "Testing"
        let tag2Name = "Search"
        let tag1 = try testWorld.createTag(tag1Name, on: post2.post)
        _ = try testWorld.createTag(tag2Name, on: firstData.post)
        try testWorld.context.repository.internalAdd(tag1, to: firstData.post)
        
        _ = try testWorld.getResponse(to: "/search?term=Test")
        let tagsForPosts = try XCTUnwrap(presenter.searchPageTagsForPost)
        XCTAssertNil(tagsForPosts[post3.post.id!])
        XCTAssertEqual(tagsForPosts[post2.post.id!]?.count, 1)
        XCTAssertEqual(tagsForPosts[post2.post.id!]?.first?.name, tag1Name)
        XCTAssertEqual(tagsForPosts[firstData.post.id!]?.count, 2)
        XCTAssertEqual(tagsForPosts[firstData.post.id!]?.first?.name, tag1Name)
        XCTAssertEqual(tagsForPosts[firstData.post.id!]?.last?.name, tag2Name)
    }
}
