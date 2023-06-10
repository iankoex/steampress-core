import XCTest
import Vapor
import Foundation

class IndexTests: XCTestCase {

    // MARK: - Properties
    var testWorld: TestWorld!
    var firstData: TestData!
    let blogIndexPath = "/"
    let postsPerPage = 10

    var presenter: CapturingBlogPresenter {
        return testWorld.context.blogPresenter
    }

    // MARK: - Overrides

    override func setUpWithError() throws {
        testWorld = try TestWorld.create(postsPerPage: postsPerPage, url: "/")
        firstData = try testWorld.createPost(title: "Test Path", slugUrl: "test-path")
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }

    // MARK: - Tests

    func testBlogIndexGetsPostsInReverseOrder() throws {
        let secondData = try testWorld.createPost(title: "A New Post")

        _ = try testWorld.getResponse(to: blogIndexPath)

        XCTAssertEqual(presenter.indexPosts?.count, 2)
        XCTAssertEqual(presenter.indexPosts?[0].title, secondData.post.title)
        XCTAssertEqual(presenter.indexPosts?[1].title, firstData.post.title)

    }

    func testBlogIndexGetsAllTags() throws {
        let tag = try testWorld.context.repository.addTag(name: "tatooine")

        _ = try testWorld.getResponse(to: blogIndexPath)

        XCTAssertEqual(presenter.indexTags?.count, 1)
        XCTAssertEqual(presenter.indexTags?.first?.name, tag.name)
    }
    
    func testBlogIndexGetsAllTagsForPosts() throws {
        let tag1 = "Testing"
        let tag2 = "Engineering"
        _ = try testWorld.createTag(tag1, on: firstData.post)
        _ = try testWorld.createTag(tag2, on: firstData.post)
        let post2 = try testWorld.createPost(title: "Something else", author: firstData.author).post
        _ = try testWorld.getResponse(to: blogIndexPath)
        
        let tagForPostInformation = try XCTUnwrap(presenter.indexTagsForPosts)
        XCTAssertEqual(tagForPostInformation[firstData.post.id!]?.count, 2)
        XCTAssertEqual(tagForPostInformation[firstData.post.id!]?.first?.name, tag1)
        XCTAssertEqual(tagForPostInformation[firstData.post.id!]?.last?.name, tag2)
        XCTAssertNil(tagForPostInformation[post2.id!])
    }

    func testBlogIndexGetsAllAuthors() throws {
        _ = try testWorld.getResponse(to: blogIndexPath)

        XCTAssertEqual(presenter.indexAuthors?.count, 1)
        XCTAssertEqual(presenter.indexAuthors?.first?.name, firstData.author.name)
    }

    func testThatAccessingPathsRouteRedirectsToBlogIndex() throws {
        let response = try testWorld.getResponse(to: "/posts/")
        XCTAssertEqual(response.status, .movedPermanently)
        XCTAssertEqual(response.headers[.location].first, "/")
    }

    func testThatAccessingPathsRouteRedirectsToBlogIndexWithCustomPath() throws {
        try testWorld.shutdown()
        testWorld = try TestWorld.create(path: "blog")
        let response = try testWorld.getResponse(to: "/blog/posts/")
        XCTAssertEqual(response.status, .movedPermanently)
        XCTAssertEqual(response.headers[.location].first, "/blog/")
    }

    // MARK: - Pagination Tests
    func testIndexOnlyGetsTheSpecifiedNumberOfPosts() throws {
        try testWorld.createPosts(count: 15, author: firstData.author)
        _ = try testWorld.getResponse(to: blogIndexPath)
        XCTAssertEqual(presenter.indexPosts?.count, postsPerPage)
    }

    func testIndexGetsCorrectPostsForPage() throws {
        try testWorld.createPosts(count: 15, author: firstData.author)
        _ = try testWorld.getResponse(to: "/?page=2")
        XCTAssertEqual(presenter.indexPosts?.count, 6)
    }

    // This is a bit of a dummy test since it should be handled by the DB
    func testIndexHandlesIncorrectPageCorrectly() throws {
        try testWorld.createPosts(count: 15, author: firstData.author)
        _ = try testWorld.getResponse(to: "/?page=3")
        XCTAssertEqual(presenter.indexPosts?.count, 0)
    }

    func testIndexHandlesNegativePageCorrectly() throws {
        try testWorld.createPosts(count: 15, author: firstData.author)
        _ = try testWorld.getResponse(to: "/?page=-3")
        XCTAssertEqual(presenter.indexPosts?.count, postsPerPage)
    }

    func testIndexHandlesPageAsStringSafely() throws {
        try testWorld.createPosts(count: 15, author: firstData.author)
        _ = try testWorld.getResponse(to: "/?page=three")
        XCTAssertEqual(presenter.indexPosts?.count, postsPerPage)
    }
    
    func testPaginationInfoSetCorrectly() throws {
        try testWorld.createPosts(count: 15, author: firstData.author)
        _ = try testWorld.getResponse(to: "/?page=2")
        XCTAssertEqual(presenter.indexPaginationTagInfo?.currentPage, 2)
        XCTAssertEqual(presenter.indexPaginationTagInfo?.totalPages, 2)
        XCTAssertEqual(presenter.indexPaginationTagInfo?.currentQuery, "page=2")
    }
    
    // MARK: - Page Information
    
    func testIndexGetsCorrectsite() throws {
        _ = try testWorld.getResponse(to: blogIndexPath)
        XCTAssertNil(presenter.indexsite?.disqusName)
        XCTAssertNil(presenter.indexsite?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.indexsite?.twitterHandle)
        XCTAssertNil(presenter.indexsite?.loggedInUser)
        XCTAssertEqual(presenter.indexsite?.currentPageURL.absoluteString, "/")
        XCTAssertEqual(presenter.indexsite?.url.absoluteString, "/")
    }
    
    func testIndexPageCurrentPageWhenAtSubPath() throws {
        try testWorld.shutdown()
        testWorld = try TestWorld.create(path: "blog", url: "/")
        _ = try testWorld.getResponse(to: "/blog")
        XCTAssertEqual(presenter.indexsite?.currentPageURL.absoluteString, "/blog")
        XCTAssertEqual(presenter.indexsite?.url.absoluteString, "/")
    }
    
    func testIndexsiteGetsLoggedInUser() throws {
        _ = try testWorld.getResponse(to: blogIndexPath, loggedInUser: firstData.author)
        XCTAssertEqual(presenter.indexsite?.loggedInUser?.username, firstData.author.username)
    }
    
    func testSettingEnvVarsWithsite() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: blogIndexPath)
        XCTAssertEqual(presenter.indexsite?.disqusName, disqusName)
        XCTAssertEqual(presenter.indexsite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.indexsite?.twitterHandle, twitterHandle)
    }
}
