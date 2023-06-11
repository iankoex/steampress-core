import XCTest
import Vapor
import SteamPressCore

class AuthorTests: XCTestCase {

    // MARK: - Properties
    private var app: Application!
    private var testWorld: TestWorld!
    private let allAuthorsRequestPath = "/authors"
    private let authorsRequestPath = "/authors/leia"
    private var user: BlogUser!
    private var postData: TestData!
    private var presenter: CapturingBlogPresenter {
        return testWorld.context.blogPresenter
    }
    private var postsPerPage = 7

    // MARK: - Overrides
    
    override func setUpWithError() throws {
        testWorld = try TestWorld.create(postsPerPage: postsPerPage, url: "/")
        user = testWorld.createUser(username: "leia")
        postData = try testWorld.createPost(author: user)
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }

    // MARK: - Tests

    func testAllAuthorsPageGetAllAuthors() throws {
        let newAuthor = testWorld.createUser(username: "han")
        _ = try testWorld.createPost(author: newAuthor)
        _ = try testWorld.createPost(author: newAuthor)
        _ = try testWorld.getResponse(to: allAuthorsRequestPath)

        XCTAssertEqual(presenter.allAuthors?.count, 2)
        XCTAssertEqual(presenter.allAuthorsPostCount?[newAuthor.id!], 2)
        XCTAssertEqual(presenter.allAuthorsPostCount?[user.id!], 1)
        XCTAssertEqual(presenter.allAuthors?.last?.name, user.name)
    }

    func testAuthorPageGetsOnlyPublishedPostsInDescendingOrder() throws {
        let secondPostData = try testWorld.createPost(title: "A later post", author: user)
        _ = try testWorld.createPost(author: user, published: false)

        _ = try testWorld.getResponse(to: authorsRequestPath)

        XCTAssertEqual(presenter.authorPosts?.count, 2)
        XCTAssertEqual(presenter.authorPosts?.first?.title, secondPostData.post.title)
    }

    func testDisabledBlogAuthorsPath() throws {
        try testWorld.shutdown()
        testWorld = try TestWorld.create(enableAuthorPages: false)
        _ = testWorld.createUser(username: "leia")

        let authorResponse = try testWorld.getResponse(to: authorsRequestPath)
        let allAuthorsResponse = try testWorld.getResponse(to: allAuthorsRequestPath)

        XCTAssertEqual(authorResponse.status, .notFound)
        XCTAssertEqual(allAuthorsResponse.status, .notFound)
    }

    func testAuthorView() throws {
        _ = try testWorld.getResponse(to: authorsRequestPath)

        XCTAssertEqual(presenter.author?.username, user.username)
        XCTAssertEqual(presenter.authorPosts?.count, 1)
        XCTAssertEqual(presenter.authorPosts?.first?.title, postData.post.title)
        XCTAssertEqual(presenter.authorPosts?.first?.contents, postData.post.contents)
    }
    
    func testAuthorPageGetsCorrectsite() throws {
        _ = try testWorld.getResponse(to: authorsRequestPath)
        XCTAssertNil(presenter.authorsite?.disqusName)
        XCTAssertNil(presenter.authorsite?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.authorsite?.twitterHandle)
        XCTAssertNil(presenter.authorsite?.loggedInUser)
        XCTAssertEqual(presenter.authorsite?.currentPageURL.absoluteString, authorsRequestPath)
        XCTAssertEqual(presenter.authorsite?.url.absoluteString, "/")
    }
    
    func testAuthorsiteGetsLoggedInUser() throws {
        let user = testWorld.createUser()
        _ = try testWorld.getResponse(to: authorsRequestPath, loggedInUser: user)
        XCTAssertEqual(presenter.authorsite?.loggedInUser?.username, user.username)
    }
    
    func testSettingEnvVarsWithsite() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: authorsRequestPath)
        XCTAssertEqual(presenter.authorsite?.disqusName, disqusName)
        XCTAssertEqual(presenter.authorsite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.authorsite?.twitterHandle, twitterHandle)
    }
    
    func testCorrectsiteForAllAuthors() throws {
        _ = try testWorld.getResponse(to: allAuthorsRequestPath)
        XCTAssertNil(presenter.allAuthorssite?.disqusName)
        XCTAssertNil(presenter.allAuthorssite?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.allAuthorssite?.twitterHandle)
        XCTAssertNil(presenter.allAuthorssite?.loggedInUser)
        XCTAssertEqual(presenter.allAuthorssite?.currentPageURL.absoluteString, allAuthorsRequestPath)
        XCTAssertEqual(presenter.allAuthorssite?.url.absoluteString, "/")
    }
    
    func testsiteGetsLoggedInUserForAllAuthors() throws {
        let user = testWorld.createUser()
        _ = try testWorld.getResponse(to: allAuthorsRequestPath, loggedInUser: user)
        XCTAssertEqual(presenter.allAuthorssite?.loggedInUser?.username, user.username)
    }
    
    func testSettingEnvVarsWithsiteForAllAuthors() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: allAuthorsRequestPath)
        XCTAssertEqual(presenter.allAuthorssite?.disqusName, disqusName)
        XCTAssertEqual(presenter.allAuthorssite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.allAuthorssite?.twitterHandle, twitterHandle)
    }
    

    // MARK: - Pagination Tests
    func testAuthorViewOnlyGetsTheSpecifiedNumberOfPosts() throws {
        try testWorld.createPosts(count: 15, author: user)
        _ = try testWorld.getResponse(to: authorsRequestPath)
        XCTAssertEqual(presenter.authorPosts?.count, postsPerPage)
        XCTAssertEqual(presenter.authorPaginationTagInfo?.currentPage, 1)
        XCTAssertEqual(presenter.authorPaginationTagInfo?.totalPages, 3)
        XCTAssertNil(presenter.authorPaginationTagInfo?.currentQuery)
    }

    func testAuthorViewGetsCorrectPostsForPage() throws {
        try testWorld.createPosts(count: 15, author: user)
        _ = try testWorld.getResponse(to: "/authors/leia?page=3")
        XCTAssertEqual(presenter.authorPosts?.count, 2)
        XCTAssertEqual(presenter.authorPaginationTagInfo?.currentQuery, "page=3")
    }

    func testAuthorViewGetsAuthorsTotalPostsEvenIfPaginated() throws {
        let totalPosts = 15
        try testWorld.createPosts(count: totalPosts, author: user)
        _ = try testWorld.getResponse(to: authorsRequestPath)
        // One post created in setup
        XCTAssertEqual(presenter.authorPostCount, totalPosts + 1)
    }
    
    func testTagsForPostsSetCorrectly() throws {
        let post2 = try testWorld.createPost(title: "Test Search", author: user)
        let post3 = try testWorld.createPost(title: "Test Tags", author: user)
        let tag1Name = "Testing"
        let tag2Name = "Search"
        let tag1 = try testWorld.createTag(tag1Name, on: post2.post)
        _ = try testWorld.createTag(tag2Name, on: postData.post)
        try testWorld.context.repository.internalAdd(tag1, to: postData.post)
        
        _ = try testWorld.getResponse(to: "/authors/leia")
        let tagsForPosts = try XCTUnwrap(presenter.authorPageTagsForPost)
        XCTAssertNil(tagsForPosts[post3.post.id!])
        XCTAssertEqual(tagsForPosts[post2.post.id!]?.count, 1)
        XCTAssertEqual(tagsForPosts[post2.post.id!]?.first?.name, tag1Name)
        XCTAssertEqual(tagsForPosts[postData.post.id!]?.count, 2)
        XCTAssertEqual(tagsForPosts[postData.post.id!]?.first?.name, tag1Name)
        XCTAssertEqual(tagsForPosts[postData.post.id!]?.last?.name, tag2Name)
    }
    
}
