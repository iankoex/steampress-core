//import XCTest
//import SteamPressCore
//import Vapor
//import Foundation
//
//class PostTests: XCTestCase {
//
//    // MARK: - Properties
//    var testWorld: TestWorld!
//    var firstData: TestData!
//    private let blogPostPath = "/posts/test-path"
//
//    var presenter: CapturingBlogPresenter {
//        return testWorld.context.blogPresenter
//    }
//
//    // MARK: - Overrides
//
//    override func setUpWithError() throws {
//        testWorld = try TestWorld.create(url: "/")
//        firstData = try testWorld.createPost(title: "Test Path", slugURL: "test-path")
//    }
//    
//    override func tearDownWithError() throws {
//        try testWorld.shutdown()
//    }
//
//    // MARK: - Tests
//
//    func testBlogPostRetrievedCorrectlyFromSlugUrl() throws {
//        _ = try testWorld.getResponse(to: blogPostPath)
//
//        XCTAssertEqual(presenter.post?.title, firstData.post.title)
//        XCTAssertEqual(presenter.post?.contents, firstData.post.contents)
//        XCTAssertEqual(presenter.postAuthor?.name, firstData.author.name)
//        XCTAssertEqual(presenter.postAuthor?.username, firstData.author.username)
//    }
//    
//    func testPostPageGetsCorrectsite() throws {
//        _ = try testWorld.getResponse(to: blogPostPath)
//        XCTAssertNil(presenter.postsite?.disqusName)
//        XCTAssertNil(presenter.postsite?.googleAnalyticsIdentifier)
//        XCTAssertNil(presenter.postsite?.twitterHandle)
//        XCTAssertNil(presenter.postsite?.loggedInUser)
//        XCTAssertEqual(presenter.postsite?.currentPageURL.absoluteString, blogPostPath)
//        XCTAssertEqual(presenter.postsite?.url.absoluteString, "/")
//    }
//    
//    func testPostsiteGetsLoggedInUser() throws {
//        _ = try testWorld.getResponse(to: blogPostPath, loggedInUser: firstData.author)
//        XCTAssertEqual(presenter.postsite?.loggedInUser?.username, firstData.author.username)
//    }
//    
//    func testSettingEnvVarsWithsite() throws {
//        let googleAnalytics = "ABDJIODJWOIJIWO"
//        let twitterHandle = "3483209fheihgifffe"
//        let disqusName = "34829u48932fgvfbrtewerg"
//        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
//        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
//        setenv("BLOG_DISQUS_NAME", disqusName, 1)
//        _ = try testWorld.getResponse(to: blogPostPath)
//        XCTAssertEqual(presenter.postsite?.disqusName, disqusName)
//        XCTAssertEqual(presenter.postsite?.googleAnalyticsIdentifier, googleAnalytics)
//        XCTAssertEqual(presenter.postsite?.twitterHandle, twitterHandle)
//    }
//    
//    func testPostPageGetsTags() throws {
//        let tag1Name = "Something"
//        let tag2Name = "Something else"
//        _ = try testWorld.createTag(tag1Name, on: firstData.post)
//        _ = try testWorld.createTag(tag2Name, on: firstData.post)
//        
//        _ = try testWorld.getResponse(to: blogPostPath)
//        
//        let tags = try XCTUnwrap(presenter.postPageTags)
//        XCTAssertEqual(tags.count, 2)
//        XCTAssertEqual(tags.first?.name, tag1Name)
//        XCTAssertEqual(tags.last?.name, tag2Name)
//    }
//    
////    func testExtraInitialiserWorks() throws {
////        let post = BlogPost(title: "title", contents: "contents", author: 1, creationDate: Date(), slugURL: "slug-url", published: true)
////        XCTAssertEqual(post.blogID, 1)
////    }
//}
