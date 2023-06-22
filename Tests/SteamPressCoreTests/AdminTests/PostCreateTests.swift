import XCTest
import Vapor
@testable import SteamPressCore

class PostCreateTests: XCTestCase {
    
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

//
//    // MARK: - Post Creation
//
//    func testPostCanBeCreated() throws {
//        struct CreatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//            let publish = true
//        }
//        let createData = CreatePostData()
//        let response = try testWorld.getResponse(to: createPostPath, body: createData, loggedInUser: user)
//
//        let post = try XCTUnwrap(testWorld.context.repository.posts.first)
//        XCTAssertEqual(testWorld.context.repository.posts.count, 1)
//        XCTAssertEqual(post.title, createData.title)
//        XCTAssertEqual(post.slugURL, "post-title")
//        XCTAssertTrue(post.published)
//        XCTAssertEqual(post.created.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.1)
//        XCTAssertTrue(post.created < Date())
//
//        XCTAssertEqual(testWorld.context.repository.tags.count, 2)
//        let firstid = testWorld.context.repository.tags[0].id!
//        let secondid = testWorld.context.repository.tags[1].id!
//        XCTAssertTrue(testWorld.context.repository.postTagLinks
//            .contains { $0.postID == post.id! && $0.tagID == firstid })
//        XCTAssertTrue(testWorld.context.repository.postTagLinks
//            .contains { $0.postID == post.id! && $0.tagID == secondid })
//
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/posts/post-title/")
//    }
//
//    func testCreatingPostWithNonUniqueSlugFromSameTitle() throws {
//        let randomNumber = 345
//        try testWorld.shutdown()
//        testWorld = try TestWorld.create(randomNumberGenerator: StubbedRandomNumberGenerator(numberToReturn: randomNumber))
//        let initialPostData = try testWorld.createPost(title: "Post Title", slugURL: "post-title")
//
//        struct CreatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//            let publish = true
//        }
//        let createData = CreatePostData()
//        let response = try testWorld.getResponse(to: createPostPath, body: createData, loggedInUser: initialPostData.author)
//
//        XCTAssertEqual(testWorld.context.repository.posts.count, 2)
//        let post = try XCTUnwrap(testWorld.context.repository.posts.last)
//        XCTAssertEqual(post.slugURL, "post-title-\(randomNumber)")
//        XCTAssertEqual(response.headers[.location].first, "/posts/post-title-\(randomNumber)/")
//    }
//
//    func testPostCreationPageGetsBasicInfo() throws {
//        _ = try testWorld.getResponse(to: createPostPath, loggedInUser: user)
//
//        let isEditing = try XCTUnwrap(presenter.createPostIsEditing)
//        let titleError = try XCTUnwrap(presenter.createPostTitleError)
//        let contentsError = try XCTUnwrap(presenter.createPostContentsError)
//        XCTAssertNil(presenter.createPostErrors)
//        XCTAssertNil(presenter.createPostTitle)
//        XCTAssertNil(presenter.createPostContents)
//        XCTAssertNil(presenter.createPostSlugURL)
//        XCTAssertNil(presenter.createPostTags)
//        XCTAssertFalse(isEditing)
//        XCTAssertNil(presenter.createPostPost)
//        XCTAssertNil(presenter.createPostDraft)
//        XCTAssertFalse(titleError)
//        XCTAssertFalse(contentsError)
//        XCTAssertEqual(presenter.createPostsite?.loggedInUser.username, user.username)
//        XCTAssertEqual(presenter.createPostsite?.currentPageURL.absoluteString, "/admin/createPost/")
//        XCTAssertEqual(presenter.createPostsite?.url.absoluteString, "/")
//    }
//
//    func testPostCannotBeCreatedIfDraftAndPublishNotSet() throws {
//        struct CreatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//        }
//        let createData = CreatePostData()
//
//        let response = try testWorld.getResponse(to: createPostPath, body: createData, loggedInUser: user)
//
//        XCTAssertEqual(response.status, .badRequest)
//    }
//
//    func testCreatePostMustIncludeTitle() throws {
//        struct CreatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//            let publish = true
//        }
//        let createData = CreatePostData()
//        _ = try testWorld.getResponse(to: createPostPath, body: createData, loggedInUser: user)
//
//        let createPostErrors = try XCTUnwrap(presenter.createPostErrors)
//        let titleError = try XCTUnwrap(presenter.createPostTitleError)
//        let contentsError = try XCTUnwrap(presenter.createPostContentsError)
//        XCTAssertTrue(createPostErrors.contains("You must specify a blog post title"))
//        XCTAssertTrue(titleError)
//        XCTAssertFalse(contentsError)
//        XCTAssertEqual(presenter.createPostsite?.loggedInUser.username, user.username)
//        XCTAssertEqual(presenter.createPostsite?.currentPageURL.absoluteString, "/admin/createPost/")
//        XCTAssertEqual(presenter.createPostsite?.url.absoluteString, "/")
//    }
//
//    func testCreatePostMustIncludeContents() throws {
//        struct CreatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let tags = ["First Tag", "Second Tag"]
//            let publish = true
//        }
//        let createData = CreatePostData()
//        _ = try testWorld.getResponse(to: createPostPath, body: createData, loggedInUser: user)
//
//        let createPostErrors = try XCTUnwrap(presenter.createPostErrors)
//        let titleError = try XCTUnwrap(presenter.createPostTitleError)
//        let contentsError = try XCTUnwrap(presenter.createPostContentsError)
//        XCTAssertTrue(createPostErrors.contains("You must have some content in your blog post"))
//        XCTAssertFalse(titleError)
//        XCTAssertTrue(contentsError)
//    }
//
//    func testPresenterGetsDataIfValidationOfDataFails() throws {
//        struct CreatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let tags = ["First Tag", "Second Tag"]
//            let publish = true
//            let contents = ""
//        }
//        let createData = CreatePostData()
//        _ = try testWorld.getResponse(to: createPostPath, body: createData, loggedInUser: user)
//
//        let createPostErrors = try XCTUnwrap(presenter.createPostErrors)
//        let titleError = try XCTUnwrap(presenter.createPostTitleError)
//        let contentsError = try XCTUnwrap(presenter.createPostContentsError)
//        XCTAssertTrue(createPostErrors.contains("You must have some content in your blog post"))
//        XCTAssertEqual(presenter.createPostTags, createData.tags)
//        XCTAssertEqual(presenter.createPostContents, createData.contents)
//        XCTAssertEqual(presenter.createPostTitle, createData.title)
//        XCTAssertFalse(titleError)
//        XCTAssertTrue(contentsError)
//    }
//
//    func testCreatePostWithDraftDoesNotPublishPost() throws {
//        struct CreatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//            let draft = true
//        }
//        let createData = CreatePostData()
//        _ = try testWorld.getResponse(to: createPostPath, body: createData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.posts.count, 1)
//        let post = try XCTUnwrap(testWorld.context.repository.posts.first)
//        XCTAssertEqual(post.title, createData.title)
//        XCTAssertFalse(post.published)
//    }
//
//    func testCreatingPostWithExistingTagsDoesntDuplicateTag() throws {
//        let existingPost = try testWorld.createPost()
//        let existingTagName = "First Tag"
//        let existingTag = try testWorld.createTag(existingTagName, on: existingPost.post)
//
//        struct CreatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//            let publish = true
//        }
//        let createData = CreatePostData()
//        _ = try testWorld.getResponse(to: createPostPath, body: createData, loggedInUser: user)
//
//        let newid = testWorld.context.repository.posts.last?.id!
//
//        XCTAssertNotEqual(existingPost.post.id, newid)
//        XCTAssertEqual(testWorld.context.repository.tags.count, 2)
//        XCTAssertTrue(testWorld.context.repository.postTagLinks
//            .contains { $0.postID == newid && $0.tagID == existingTag.id! })
//    }
//
//    // MARK: - Post editing
//
//    func testPostCanBeUpdated() throws {
//        struct UpdatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//        }
//
//        let testData = try testWorld.createPost(title: "Initial title", contents: "Some initial contents", slugURL: "initial-title")
//        let updateData = UpdatePostData()
//
//        let updatePostPath = "/admin/posts/\(testData.post.id!)/edit"
//        _ = try testWorld.getResponse(to: updatePostPath, body: updateData, loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.posts.count, 1)
//        let post = try XCTUnwrap(testWorld.context.repository.posts.first)
//        XCTAssertEqual(post.title, updateData.title)
//        XCTAssertEqual(post.contents, updateData.contents)
//        XCTAssertEqual(post.slugURL, testData.post.slugURL)
//        XCTAssertEqual(post.id, testData.post.id)
//        XCTAssertTrue(post.published)
//    }
//
//    func testPostCanBeUpdatedAndUpdateSlugURL() throws {
//        struct UpdatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//            let updateSlugURL = true
//        }
//
//        let testData = try testWorld.createPost(title: "Initial title", contents: "Some initial contents", slugURL: "initial-title")
//        let updateData = UpdatePostData()
//
//        let updatePostPath = "/admin/posts/\(testData.post.id!)/edit"
//        _ = try testWorld.getResponse(to: updatePostPath, body: updateData, loggedInUser: user)
//
//        let post = try XCTUnwrap(testWorld.context.repository.posts.first)
//        XCTAssertEqual(post.slugURL, "post-title")
//    }
//
//    func testEditPageGetsPostInfo() throws {
//        let post = try testWorld.createPost().post
//        let tag1Name = "Engineering"
//        let tag2Name = "SteamPress"
//        _ = try testWorld.createTag(tag1Name, on: post)
//        _ = try testWorld.createTag(tag2Name, on: post)
//        _ = try testWorld.getResponse(to: "/admin/posts/\(post.id!)/edit", loggedInUser: user)
//
//        XCTAssertEqual(presenter.createPostTitle, post.title)
//        XCTAssertEqual(presenter.createPostContents, post.contents)
//        XCTAssertEqual(presenter.createPostSlugURL, post.slugURL)
//        let isEditing = try XCTUnwrap(presenter.createPostIsEditing)
//        XCTAssertTrue(isEditing)
//        XCTAssertEqual(presenter.createPostPost?.id, post.id)
//        XCTAssertEqual(presenter.createPostDraft, !post.published)
//        XCTAssertEqual(presenter.createPostTags?.count, 2)
//        let postTags = try XCTUnwrap(presenter.createPostTags)
//        XCTAssertTrue(postTags.contains(tag1Name))
//        XCTAssertTrue(postTags.contains(tag2Name))
//        let titleError = try XCTUnwrap(presenter.createPostTitleError)
//        let contentsError = try XCTUnwrap(presenter.createPostContentsError)
//        XCTAssertFalse(titleError)
//        XCTAssertFalse(contentsError)
//        XCTAssertEqual(presenter.createPostsite?.loggedInUser.username, user.username)
//        XCTAssertEqual(presenter.createPostsite?.currentPageURL.absoluteString, "/admin/posts/1/edit")
//        XCTAssertEqual(presenter.createPostsite?.url.absoluteString, "/")
//    }
//
//    func testThatEditingPostGetsRedirectToPostPage() throws {
//        let testData = try testWorld.createPost()
//
//        struct UpdateData: Content {
//            let title: String
//            let contents = "Updated contents"
//            let tags = [String]()
//        }
//
//        let updateData = UpdateData(title: testData.post.title)
//        let response = try testWorld.getResponse(to: "/admin/posts/\(testData.post.id!)/edit", body: updateData, loggedInUser: user)
//
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/posts/\(testData.post.slugURL)/")
//    }
//
//    func testThatEditingPostGetsRedirectToPostPageWithNewSlugURL() throws {
//        let testData = try testWorld.createPost()
//
//        struct UpdateData: Content {
//            let title: String
//            let contents = "Updated contents"
//            let tags = [String]()
//            let updateSlugURL = true
//        }
//
//        let updateData = UpdateData(title: "Some New Title")
//        let response = try testWorld.getResponse(to: "/admin/posts/\(testData.post.id!)/edit", body: updateData, loggedInUser: user)
//
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/posts/some-new-title/")
//    }
//
//    func testEditingPostWithNewTagsRemovesOldLinksAndAddsNewLinks() throws {
//        let post = try testWorld.createPost(title: "Initial title", contents: "Some initial contents", slugURL: "initial-title").post
//        let firstTagName = "Some Tag"
//        let secondTagName = "Engineering"
//        let firstTag = try testWorld.createTag(firstTagName, on: post)
//        let secondTag = try testWorld.createTag(secondTagName, on: post)
//
//        let newTagName = "A New Tag"
//
//        struct UpdatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags: [String]
//        }
//
//        let updateData = UpdatePostData(tags: [firstTagName, newTagName])
//
//        let updatePostPath = "/admin/posts/\(post.id!)/edit"
//        _ = try testWorld.getResponse(to: updatePostPath, body: updateData, loggedInUser: user)
//
//        XCTAssertTrue(testWorld.context.repository.postTagLinks
//            .contains { $0.postID == post.id! && $0.tagID == firstTag.id! })
//        XCTAssertFalse(testWorld.context.repository.postTagLinks
//            .contains { $0.postID == post.id! && $0.tagID == secondTag.id! })
//        let newTag = try XCTUnwrap(testWorld.context.repository.tags.first { $0.name.removingPercentEncoding == newTagName })
//        XCTAssertTrue(testWorld.context.repository.postTagLinks
//            .contains { $0.postID == post.id! && $0.tagID == newTag.id! })
//        XCTAssertEqual(testWorld.context.repository.tags.filter { $0.name.removingPercentEncoding == firstTagName}.count, 1)
//    }
//
//    func testLastUpdatedTimeGetsChangedWhenEditingAPost() throws {
//        struct UpdatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//        }
//
//        let testData = try testWorld.createPost(title: "Initial title", contents: "Some initial contents", slugURL: "initial-title")
//
//        let updateData = UpdatePostData()
//
//        let updatePostPath = "/admin/posts/\(testData.post.id!)/edit"
//        _ = try testWorld.getResponse(to: updatePostPath, body: updateData, loggedInUser: user)
//
//        let post = try XCTUnwrap(testWorld.context.repository.posts.first)
//        let postLastEdited = try XCTUnwrap(post.lastEdited)
//        XCTAssertEqual(postLastEdited.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.1)
//        XCTAssertTrue(postLastEdited > post.created)
//    }
//
//    func testCreatedTimeSetWhenPublishingADraft() throws {
//        struct UpdatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//            let publish = true
//        }
//
//        let testData = try testWorld.createPost(title: "Initial title", contents: "Some initial contents", slugURL: "initial-title", published: false)
//
//        let updateData = UpdatePostData()
//
//        let updatePostPath = "/admin/posts/\(testData.post.id!)/edit"
//        _ = try testWorld.getResponse(to: updatePostPath, body: updateData, loggedInUser: user)
//
//        let post = try XCTUnwrap(testWorld.context.repository.posts.first)
//        XCTAssertEqual(post.created.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.1)
//        XCTAssertTrue(post.published)
//        XCTAssertNil(post.lastEdited)
//    }
//
//    func testCreatedTimeSetAndMarkedAsDraftWhenSavingADraft() throws {
//        struct UpdatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//            let draft = true
//        }
//
//        let testData = try testWorld.createPost(title: "Initial title", contents: "Some initial contents", slugURL: "initial-title", published: false)
//
//        let updateData = UpdatePostData()
//
//        let updatePostPath = "/admin/posts/\(testData.post.id!)/edit"
//        _ = try testWorld.getResponse(to: updatePostPath, body: updateData, loggedInUser: user)
//
//        let post = try XCTUnwrap(testWorld.context.repository.posts.first)
//        XCTAssertFalse(post.published)
//        XCTAssertNil(post.lastEdited)
//        XCTAssertEqual(post.created.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.1)
//    }
//
//    func testEditingPageWithInvalidDataPassesExistingDataToPresenter() throws {
//        struct UpdatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = ""
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//        }
//
//        let testData = try testWorld.createPost(title: "Initial title", contents: "Some initial contents", slugURL: "initial-title")
//        let updateData = UpdatePostData()
//
//        let updatePostPath = "/admin/posts/\(testData.post.id!)/edit"
//        _ = try testWorld.getResponse(to: updatePostPath, body: updateData, loggedInUser: user)
//
//        XCTAssertEqual(presenter.createPostTitle, "")
//        XCTAssertEqual(presenter.createPostPost?.id, testData.post.id)
//        XCTAssertEqual(presenter.createPostContents, updateData.contents)
//        XCTAssertEqual(presenter.createPostSlugURL, testData.post.slugURL)
//        XCTAssertEqual(presenter.createPostTags, updateData.tags)
//        XCTAssertEqual(presenter.createPostIsEditing, true)
//        XCTAssertEqual(presenter.createPostDraft, false)
//        let createPostErrors = try XCTUnwrap(presenter.createPostErrors)
//        XCTAssertTrue(createPostErrors.contains("You must specify a blog post title"))
//        let titleError = try XCTUnwrap(presenter.createPostTitleError)
//        let contentsError = try XCTUnwrap(presenter.createPostContentsError)
//        XCTAssertTrue(titleError)
//        XCTAssertFalse(contentsError)
//        XCTAssertEqual(presenter.createPostsite?.loggedInUser.username, user.username)
//        XCTAssertEqual(presenter.createPostsite?.currentPageURL.absoluteString, "/admin/posts/1/edit")
//        XCTAssertEqual(presenter.createPostsite?.url.absoluteString, "/")
//    }
//    
//    func testEditingPageWithInvalidContentsDataPassesExistingDataToPresenter() throws {
//        struct UpdatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "A new title"
//            let contents = ""
//            let tags = ["First Tag", "Second Tag"]
//        }
//
//        let testData = try testWorld.createPost(title: "Initial title", contents: "Some initial contents", slugURL: "initial-title")
//        let updateData = UpdatePostData()
//
//        let updatePostPath = "/admin/posts/\(testData.post.id!)/edit"
//        _ = try testWorld.getResponse(to: updatePostPath, body: updateData, loggedInUser: user)
//
//        let createPostErrors = try XCTUnwrap(presenter.createPostErrors)
//        XCTAssertTrue(createPostErrors.contains("You must have some content in your blog post"))
//        let titleError = try XCTUnwrap(presenter.createPostTitleError)
//        let contentsError = try XCTUnwrap(presenter.createPostContentsError)
//        XCTAssertTrue(contentsError)
//        XCTAssertFalse(titleError)
//    }
//
//    // MARK: - Post Deletion
//
//    func testCanDeleteBlogPost() throws {
//        let testData = try testWorld.createPost()
//        let response = try testWorld.getResponse(to: "/admin/posts/\(testData.post.id!)/delete", method: .POST, body: EmptyContent(), loggedInUser: user)
//
//        XCTAssertEqual(response.status, .seeOther)
//        XCTAssertEqual(response.headers[.location].first, "/admin/")
//        XCTAssertEqual(testWorld.context.repository.posts.count, 0)
//    }
//
//    func testDeletingBlogPostRemovesTagLinks() throws {
//        let testData = try testWorld.createPost()
//        _ = try testWorld.createTag(on: testData.post)
//        _ = try testWorld.createTag("SteamPress", on: testData.post)
//
//        XCTAssertEqual(testWorld.context.repository.postTagLinks.count, 2)
//
//        _ = try testWorld.getResponse(to: "/admin/posts/\(testData.post.id!)/delete", method: .POST, body: EmptyContent(), loggedInUser: user)
//
//        XCTAssertEqual(testWorld.context.repository.postTagLinks.count, 0)
//    }
//
//    // MARK: - Slug URL Generation
//
//    func testThatSlugUrlCalculatedCorrectlyForTitleWithSpaces() throws {
//        let title = "This is a title"
//        let expectedSlugUrl = "this-is-a-title"
//        let post = try createPostViaRequest(title: title)
//        XCTAssertEqual(post.slugURL, expectedSlugUrl)
//    }
//
//    func testThatSlugUrlCalculatedCorrectlyForTitleWithPunctuation() throws {
//        let title = "This is an awesome post!"
//        let expectedSlugUrl = "this-is-an-awesome-post"
//        let post = try createPostViaRequest(title: title)
//        XCTAssertEqual(expectedSlugUrl, post.slugURL)
//    }
//
//    func testThatSlugUrlStripsWhitespace() throws {
//        let title = "    Title  "
//        let expectedSlugUrl = "title"
//        let post = try createPostViaRequest(title: title)
//        XCTAssertEqual(expectedSlugUrl, post.slugURL)
//    }
//
//    func testNumbersRemainInUrl() throws {
//        let title = "The 2nd url"
//        let expectedSlugUrl = "the-2nd-url"
//        let post = try createPostViaRequest(title: title)
//        XCTAssertEqual(expectedSlugUrl, post.slugURL)
//    }
//
//    func testSlugUrlLowerCases() throws {
//        let title = "AN AMAZING POST"
//        let expectedSlugUrl = "an-amazing-post"
//        let post = try createPostViaRequest(title: title)
//        XCTAssertEqual(expectedSlugUrl, post.slugURL)
//    }
//
//    func testEverythingWithLotsOfCharacters() throws {
//        let title = " This should remove! \nalmost _all_ of the @ punctuation, but it doesn't?"
//        let expectedSlugUrl = "this-should-remove-almost-all-of-the-punctuation-but-it-doesnt"
//        let post = try createPostViaRequest(title: title)
//        XCTAssertEqual(expectedSlugUrl, post.slugURL)
//    }
//    
//    func testRandomStringHelperDoesntProduceTheSameStringKinda() throws {
//        let string1 = try String.random()
//        let string2 = try String.random()
//        XCTAssertNotEqual(string1, string2)
//    }
//    
//    func testAddingPostToExistingTagDoesntDuplicateTheTag() throws {
//        let existingTagName = "Engineering"
//        let post = try testWorld.createPost(title: "Initial title", contents: "Some initial contents", slugURL: "initial-title").post
//        let existingTag = try testWorld.createTag(existingTagName)
//
//        struct UpdatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title = "Post Title"
//            let contents = "# Post Title\n\nWe have a post"
//            let tags: [String]
//        }
//
//        let updateData = UpdatePostData(tags: [existingTagName])
//
//        XCTAssertEqual(testWorld.context.repository.tags.count, 1)
//        XCTAssertEqual(testWorld.context.repository.tags.first?.name, existingTagName)
//        
//        let updatePostPath = "/admin/posts/\(post.id!)/edit"
//        _ = try testWorld.getResponse(to: updatePostPath, body: updateData, loggedInUser: user)
//
//        XCTAssertTrue(testWorld.context.repository.postTagLinks
//            .contains { $0.postID == post.id! && $0.tagID == existingTag.id! })
//        XCTAssertEqual(testWorld.context.repository.tags.count, 1)
//    }
//    
//    func testsiteGetsurlAndPageURLFromEnvVar() throws {
//        let site = "https://www.steampress.io"
//        setenv("SP_WEBSITE_URL", site, 1)
//        _ = try testWorld.getResponse(to: createPostPath, loggedInUser: user)
//        XCTAssertEqual(presenter.createPostsite?.url.absoluteString, site)
//    }
//    
//    func testFailingURLFromEnvVar() throws {
//        let site = ""
//        setenv("SP_WEBSITE_URL", site, 1)
//        let response = try testWorld.getResponse(to: createPostPath, loggedInUser: user)
//        XCTAssertEqual(response.status, .internalServerError)
//    }
//
//    // MARK: - Helpers
//
//    private func createPostViaRequest(title: String) throws -> BlogPost {
//        struct CreatePostData: Content {
//            static let defaultContentType = HTTPMediaType.urlEncodedForm
//            let title: String
//            let contents = "# Post Title\n\nWe have a post"
//            let tags = ["First Tag", "Second Tag"]
//            let publish = true
//        }
//        let createData = CreatePostData(title: title)
//        _ = try testWorld.getResponse(to: createPostPath, body: createData, loggedInUser: user)
//
//        let post = try XCTUnwrap(testWorld.context.repository.posts.first)
//        return post
//    }
//
//}
