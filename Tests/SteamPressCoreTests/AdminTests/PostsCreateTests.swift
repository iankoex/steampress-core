import XCTest
import Vapor
@testable import SteamPressCore

class PostsCreateTests: XCTestCase {
    
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
    
    // MARK: - Post Create Tests
    
    func testPostCanBeCreatedSuccessfully() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreatePostData(
            title: "This is title",
            contents: "The contents of the post",
            snippet: "Short Snippet for SEO",
            isDraft: true,
            tags: [tag.name],
            updateSlugURL: false,
            imageURL: "https://static.brokenhands.io/images/cat.png",
            imageAlt: "image of a cat"
        )
        
        try app
            .describe("New Post Can be Created Successfully")
            .post(adminPath(for: "posts/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "posts/"))
            }
            .test()
        
        let posts = try await testWorld.context.req.repositories.blogPost.getAllPosts(includeDrafts: true)
        
        XCTAssertEqual(posts.count, 1)
        let post = try XCTUnwrap(posts.first)
        XCTAssertEqual(post.title, createData.title)
        XCTAssertEqual(post.contents, createData.contents)
        XCTAssertEqual(post.snippet, createData.snippet)
        XCTAssertEqual(post.published, !createData.isDraft)
        XCTAssertEqual(post.tags.first?.name, tag.name)
        XCTAssertEqual(post.imageURL, createData.imageURL)
        XCTAssertEqual(post.imageAlt, createData.imageAlt)
    }
    
    func testPostCanBeCreatedSuccessfullyWithOptionalInformationMissing() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreatePostData(
            title: "This is title",
            contents: "The contents of the post",
            snippet: "Short Snippet for SEO",
            isDraft: true,
            tags: [tag.name]
        )
        
        try app
            .describe("New Post Can be Created Successfully with Optional Information Missing")
            .post(adminPath(for: "posts/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "posts/"))
            }
            .test()
        
        let posts = try await testWorld.context.req.repositories.blogPost.getAllPosts(includeDrafts: true)
        
        XCTAssertEqual(posts.count, 1)
        let post = try XCTUnwrap(posts.first)
        XCTAssertEqual(post.title, createData.title)
        XCTAssertEqual(post.contents, createData.contents)
        XCTAssertEqual(post.snippet, createData.snippet)
        XCTAssertEqual(post.published, !createData.isDraft)
        XCTAssertEqual(post.tags.first?.name, tag.name)
        XCTAssertNil(post.imageURL)
        XCTAssertNil(post.imageAlt)
    }
    
    func testCreatePostWithDraftDoesNotPublishPost() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreatePostData(
            title: "This is title",
            contents: "The contents of the post",
            snippet: "Short Snippet for SEO",
            isDraft: true,
            tags: [tag.name]
        )
        
        try app
            .describe("New Post Created as Draft is not Published")
            .post(adminPath(for: "posts/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "posts/"))
            }
            .test()
        
        let posts = try await testWorld.context.req.repositories.blogPost.getAllPosts(includeDrafts: false)
        
        XCTAssertEqual(posts.count, 0)
    }
    
    func testPostCannotBeCreatedWithEmptyFields() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreatePostData(
            title: "",
            contents: "",
            snippet: "",
            isDraft: true,
            tags: [tag.name]
        )
        
        try app
            .describe("New Post Cannot be Created with Empty Fields")
            .post(adminPath(for: "posts/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createPostViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createPostViewErrors)
        XCTAssertTrue(errors.contains("You must specify a blog post title"))
        XCTAssertTrue(errors.contains("You must have some content in your blog post"))
    }
    
    func testPostCannotBeCreatedWithWhitespaceFields() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreatePostData(
            title: "     ",
            contents: "    ",
            snippet: "",
            isDraft: true,
            tags: [tag.name]
        )
        
        try app
            .describe("New Post Cannot be Created with Whitespace Fields")
            .post(adminPath(for: "posts/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createPostViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createPostViewErrors)
        XCTAssertTrue(errors.contains("You must specify a blog post title"))
        XCTAssertTrue(errors.contains("You must have some content in your blog post"))
    }
    
    func testPresenterGetsTheCorrectInfoWhenTitleIsMissing() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreatePostData(
            title: "",
            contents: "This is the content",
            snippet: "snippete",
            isDraft: true,
            tags: [tag.name]
        )
        
        try app
            .describe("New Post Cannot be Created with Whitespace Fields")
            .post(adminPath(for: "posts/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertEqual(CapturingAdminPresenter.createPostViewTitleSupplied, createData.title)
        XCTAssertEqual(CapturingAdminPresenter.createPostViewSnippetSupplied, createData.snippet)
        XCTAssertEqual(CapturingAdminPresenter.createPostViewContentSupplied, createData.contents)
        XCTAssertNotNil(CapturingAdminPresenter.createPostViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createPostViewErrors)
        XCTAssertTrue(errors.contains("You must specify a blog post title"))
    }
    
    func testPresenterGetsTheCorrectInfoWhenContentIsMissing() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreatePostData(
            title: "this is title",
            contents: "",
            snippet: "snippete",
            isDraft: true,
            tags: [tag.name]
        )
        
        try app
            .describe("New Post Cannot be Created with Whitespace Fields")
            .post(adminPath(for: "posts/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertEqual(CapturingAdminPresenter.createPostViewContentSupplied, createData.contents)
        XCTAssertEqual(CapturingAdminPresenter.createPostViewSnippetSupplied, createData.snippet)
        XCTAssertEqual(CapturingAdminPresenter.createPostViewContentSupplied, createData.contents)
        XCTAssertNotNil(CapturingAdminPresenter.createPostViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createPostViewErrors)
        XCTAssertTrue(errors.contains("You must have some content in your blog post"))
    }
    
    func testPostCannotBeCreatedWithNonExistantTag() async throws {
        let createData = CreatePostData(
            title: "title here",
            contents: "content goes brrr",
            snippet: "brrr",
            isDraft: false,
            tags: ["some tag"]
        )
        
        try app
            .describe("New Post Cannot be Created with Whitespace Fields")
            .post(adminPath(for: "posts/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createPostViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createPostViewErrors)
        XCTAssertTrue(errors.contains("Tag not found"))
    }
    
    // MARK: - Helpers
    
    private func createAndReturnTag(_ name: String = "Events") async  throws -> BlogTag {
        let createData = CreateTagData(name: name)
        
        try app
            .describe("New Tag Can be Created Successfully")
            .post(adminPath(for: "tags/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "tags/"))
            }
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        let tag = try XCTUnwrap(tags.first)
        XCTAssertEqual(tag.name, createData.name)
        XCTAssertEqual(tag.visibility, .public)
        XCTAssertNil(CapturingAdminPresenter.createCreateTagsViewErrors)
        return tag
    }
    
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
