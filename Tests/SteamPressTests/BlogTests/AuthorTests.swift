import XCTest
import Vapor
import SteamPress

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
    
    func testAuthorPageGetsCorrectwebsite() throws {
        _ = try testWorld.getResponse(to: authorsRequestPath)
        XCTAssertNil(presenter.authorwebsite?.disqusName)
        XCTAssertNil(presenter.authorwebsite?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.authorwebsite?.twitterHandle)
        XCTAssertNil(presenter.authorwebsite?.loggedInUser)
        XCTAssertEqual(presenter.authorwebsite?.currentPageURL.absoluteString, authorsRequestPath)
        XCTAssertEqual(presenter.authorwebsite?.url.absoluteString, "/")
    }
    
    func testAuthorwebsiteGetsLoggedInUser() throws {
        let user = testWorld.createUser()
        _ = try testWorld.getResponse(to: authorsRequestPath, loggedInUser: user)
        XCTAssertEqual(presenter.authorwebsite?.loggedInUser?.username, user.username)
    }
    
    func testSettingEnvVarsWithwebsite() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: authorsRequestPath)
        XCTAssertEqual(presenter.authorwebsite?.disqusName, disqusName)
        XCTAssertEqual(presenter.authorwebsite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.authorwebsite?.twitterHandle, twitterHandle)
    }
    
    func testCorrectwebsiteForAllAuthors() throws {
        _ = try testWorld.getResponse(to: allAuthorsRequestPath)
        XCTAssertNil(presenter.allAuthorswebsite?.disqusName)
        XCTAssertNil(presenter.allAuthorswebsite?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.allAuthorswebsite?.twitterHandle)
        XCTAssertNil(presenter.allAuthorswebsite?.loggedInUser)
        XCTAssertEqual(presenter.allAuthorswebsite?.currentPageURL.absoluteString, allAuthorsRequestPath)
        XCTAssertEqual(presenter.allAuthorswebsite?.url.absoluteString, "/")
    }
    
    func testwebsiteGetsLoggedInUserForAllAuthors() throws {
        let user = testWorld.createUser()
        _ = try testWorld.getResponse(to: allAuthorsRequestPath, loggedInUser: user)
        XCTAssertEqual(presenter.allAuthorswebsite?.loggedInUser?.username, user.username)
    }
    
    func testSettingEnvVarsWithwebsiteForAllAuthors() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: allAuthorsRequestPath)
        XCTAssertEqual(presenter.allAuthorswebsite?.disqusName, disqusName)
        XCTAssertEqual(presenter.allAuthorswebsite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.allAuthorswebsite?.twitterHandle, twitterHandle)
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
