import XCTest
import SteamPress
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
    
    func testCorrectwebsiteForSearch() throws {
        _ = try testWorld.getResponse(to: "/search?term=Test")
        XCTAssertNil(presenter.searchwebsite?.disqusName)
        XCTAssertNil(presenter.searchwebsite?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.searchwebsite?.twitterHandle)
        XCTAssertNil(presenter.searchwebsite?.loggedInUser)
        XCTAssertEqual(presenter.searchwebsite?.currentPageURL.absoluteString, "/search")
        XCTAssertEqual(presenter.searchwebsite?.url.absoluteString, "/")
    }
    
    func testwebsiteGetsLoggedInUserForSearch() throws {
        _ = try testWorld.getResponse(to: "/search?term=Test", loggedInUser: firstData.author)
        XCTAssertEqual(presenter.searchwebsite?.loggedInUser?.username, firstData.author.username)
    }
    
    func testSettingEnvVarsWithwebsiteForSearch() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: "/search?term=Test")
        XCTAssertEqual(presenter.searchwebsite?.disqusName, disqusName)
        XCTAssertEqual(presenter.searchwebsite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.searchwebsite?.twitterHandle, twitterHandle)
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
