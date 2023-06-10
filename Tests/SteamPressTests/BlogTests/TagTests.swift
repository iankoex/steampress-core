import XCTest
import Vapor
import SteamPress

class TagTests: XCTestCase {

    // MARK: - Properties
    var app: Application!
    var testWorld: TestWorld!
    let allTagsRequestPath = "/tags"
    let tagRequestPath = "/tags/Tatooine"
    let tagName = "Tatooine"
    var postData: TestData!
    var tag: BlogTag!
    var presenter: CapturingBlogPresenter {
        return testWorld.context.blogPresenter
    }
    let postsPerPage = 7

    // MARK: - Overrides

    override func setUpWithError() throws {
        testWorld = try TestWorld.create(postsPerPage: postsPerPage, url: "/")
        postData = try testWorld.createPost()
        tag = try testWorld.createTag(tagName, on: postData.post)
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }

    // MARK: - Tests

    func testAllTagsPageGetsAllTags() throws {
        let secondPost = try testWorld.createPost()
        let thirdPost = try testWorld.createPost()
        let secondTag = try testWorld.createTag("AnotherTag", on: secondPost.post)
        try testWorld.context.repository.internalAdd(secondTag, to: thirdPost.post)
        _ = try testWorld.getResponse(to: allTagsRequestPath)

        XCTAssertEqual(presenter.allTagsPageTags?.count, 2)
        XCTAssertEqual(presenter.allTagsPageTags?.first?.name, tag.name)
        XCTAssertEqual(presenter.allTagsPagePostCount?[tag.id!], 1)
        XCTAssertEqual(presenter.allTagsPagePostCount?[secondTag.id!], 2)
    }

    func testTagPageGetsOnlyPublishedPostsInDescendingOrder() throws {
        let secondPostData = try testWorld.createPost(title: "A later post", author: postData.author)
        let draftPost = try testWorld.createPost(published: false)
        testWorld.context.repository.addTag(tag, to: secondPostData.post)
        testWorld.context.repository.addTag(tag, to: draftPost.post)

        _ = try testWorld.getResponse(to: tagRequestPath)

        XCTAssertEqual(presenter.tagPosts?.count, 2)
        XCTAssertEqual(presenter.tagPosts?.first?.title, secondPostData.post.title)
    }

    func testTagView() throws {
        _ = try testWorld.getResponse(to: tagRequestPath)

        XCTAssertEqual(presenter.tagPosts?.count, 1)
        XCTAssertEqual(presenter.tagPosts?.first?.title, postData.post.title)
        XCTAssertEqual(presenter.tag?.name, tag.name)
    }
    
    func testTagPageGetsCorrectsite() throws {
        _ = try testWorld.getResponse(to: tagRequestPath)
        XCTAssertNil(presenter.tagsite?.disqusName)
        XCTAssertNil(presenter.tagsite?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.tagsite?.twitterHandle)
        XCTAssertNil(presenter.tagsite?.loggedInUser)
        XCTAssertEqual(presenter.tagsite?.currentPageURL.absoluteString, tagRequestPath)
        XCTAssertEqual(presenter.tagsite?.url.absoluteString, "/")
    }
    
    func testRequestToURLEncodedTag() throws {
        _ = try testWorld.createTag("Some tag")
        let response = try testWorld.getResponse(to: "/tags/Some%20tag")
        XCTAssertEqual(response.status, .ok)
    }
    
    func testTagsiteGetsLoggedInUser() throws {
        _ = try testWorld.getResponse(to: tagRequestPath, loggedInUser: postData.author)
        XCTAssertEqual(presenter.tagsite?.loggedInUser?.username, postData.author.username)
    }
    
    func testSettingEnvVarsWithsite() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: tagRequestPath)
        XCTAssertEqual(presenter.tagsite?.disqusName, disqusName)
        XCTAssertEqual(presenter.tagsite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.tagsite?.twitterHandle, twitterHandle)
    }
    
    func testCorrectsiteForAllTags() throws {
        _ = try testWorld.getResponse(to: allTagsRequestPath)
        XCTAssertNil(presenter.allTagssite?.disqusName)
        XCTAssertNil(presenter.allTagssite?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.allTagssite?.twitterHandle)
        XCTAssertNil(presenter.allTagssite?.loggedInUser)
        XCTAssertEqual(presenter.allTagssite?.currentPageURL.absoluteString, allTagsRequestPath)
        XCTAssertEqual(presenter.allTagssite?.url.absoluteString, "/")
    }
    
    func testsiteGetsLoggedInUserForAllTags() throws {
        _ = try testWorld.getResponse(to: allTagsRequestPath, loggedInUser: postData.author)
        XCTAssertEqual(presenter.allTagssite?.loggedInUser?.username, postData.author.username)
    }
    
    func testSettingEnvVarsWithsiteForAllTags() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: allTagsRequestPath)
        XCTAssertEqual(presenter.allTagssite?.disqusName, disqusName)
        XCTAssertEqual(presenter.allTagssite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.allTagssite?.twitterHandle, twitterHandle)
    }

    // MARK: - Pagination Tests
    func testTagViewOnlyGetsTheSpecifiedNumberOfPosts() throws {
        try testWorld.createPosts(count: 15, author: postData.author, tag: tag)
        _ = try testWorld.getResponse(to: tagRequestPath)
        XCTAssertEqual(presenter.tagPosts?.count, postsPerPage)
    }

    func testTagViewGetsCorrectPostsForPage() throws {
        try testWorld.createPosts(count: 15, author: postData.author, tag: tag)
        _ = try testWorld.getResponse(to: "\(tagRequestPath)?page=3")
        XCTAssertEqual(presenter.tagPosts?.count, 2)
        XCTAssertEqual(presenter.tagPaginationTagInfo?.currentQuery, "page=3")
    }
    
    func testPaginationInfoSetCorrectly() throws {
        try testWorld.createPosts(count: 15, author: postData.author, tag: tag)
        _ = try testWorld.getResponse(to: tagRequestPath)
        XCTAssertEqual(presenter.tagPaginationTagInfo?.currentPage, 1)
        XCTAssertEqual(presenter.tagPaginationTagInfo?.totalPages, 3)
        XCTAssertNil(presenter.tagPaginationTagInfo?.currentQuery)
    }
    
    func testPageAuthorsSetCorrectly() throws {
        _ = try testWorld.getResponse(to: tagRequestPath)
        XCTAssertEqual(presenter.tagPageAuthors?.count, 1)
        XCTAssertEqual(presenter.tagPageAuthors?.first?.name, postData.author.name)
    }
}
