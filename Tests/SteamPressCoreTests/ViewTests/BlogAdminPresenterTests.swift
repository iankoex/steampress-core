//import XCTest
//@testable import SteamPressCore
//import Vapor
//
//class BlogAdminPresenterTests: XCTestCase {
//
//    // MARK: - Properties
//    var eventLoopGroup: MultiThreadedEventLoopGroup!
//    var presenter: ViewBlogAdminPresenter!
//    var viewRenderer: CapturingViewRenderer!
//
//    private let currentUser = TestDataBuilder.anyUser(id: UUID())
//    private let url = URL(string: "https://brokenhands.io")!
//    private let resetPasswordURL = URL(string: "https://brokenhands.io/blog/admin/resetPassword")!
//    private let adminPageURL = URL(string: "https://brokenhands.io/blog/admin")!
//    private let createUserPageURL = URL(string: "https://brokenhands.io/blog/admin/createUser")!
//    private let editUserPageURL = URL(string: "https://brokenhands.io/blog/admin/users/0/edit")!
//    private let createBlogPageURL = URL(string: "https://brokenhands.io/blog/admin/createPost")!
//    private let editPostPageURL = URL(string: "https://brokenhands.io/blog/admin/posts/0/edit")!
//
//    private static let twitterHandle = "brokenhandsio"
//    private static let disqusName = "steampress"
//    private static let googleAnalyticsIdentifier = "UA-12345678-1"
//    // MARK: - Overrides
//
//    override func setUp() {
//        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        viewRenderer = CapturingViewRenderer(eventLoop: eventLoopGroup.next())
//        presenter = ViewBlogAdminPresenter(BlogPathCreator: BlogPathCreator(blogPath: "blog"), viewRenderer: viewRenderer, longDateFormatter: LongPostDateFormatter(), numericDateFormatter: NumericPostDateFormatter())
//    }
//    
//    override func tearDownWithError() throws {
//        try eventLoopGroup.syncShutdownGracefully()
//    }
//
//    // MARK: - Tests
//
//    // MARK: - Reset Password
//
//    func testPasswordViewGivenCorrectParameters() async throws {
//        let site = buildsite(currentPageURL: resetPasswordURL)
//        _ = try await presenter.createResetPasswordView(errors: nil, passwordError: nil, confirmPasswordError: nil, site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? ResetPasswordPageContext)
//        XCTAssertNil(context.errors)
//        XCTAssertNil(context.passwordError)
//        XCTAssertNil(context.confirmPasswordError)
//        XCTAssertEqual(context.site.loggedInUser.username, currentUser.username)
//        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
//        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/blog/admin/resetPassword")
//        XCTAssertEqual(viewRenderer.templatePath, "blog/admin/resetPassword")
//    }
//
//    func testPasswordViewHasCorrectParametersWhenError() async throws {
//        let expectedError = "Passwords do not match"
//        let site = buildsite(currentPageURL: resetPasswordURL)
//        _ = try await presenter.createResetPasswordView(errors: [expectedError], passwordError: true, confirmPasswordError: true, site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? ResetPasswordPageContext)
//        XCTAssertEqual(context.errors?.count, 1)
//        XCTAssertEqual(context.errors?.first, expectedError)
//        let passwordError = try XCTUnwrap(context.passwordError)
//        let confirmPasswordError = try XCTUnwrap(context.confirmPasswordError)
//        XCTAssertTrue(passwordError)
//        XCTAssertTrue(confirmPasswordError)
//    }
//
//    // MARK: - Admin Page
//
//    func testBlogAdminViewGetsCorrectParameters() async throws {
//        let draftPost = try TestDataBuilder.anyPost(author: currentUser, title: "[DRAFT] This will be awesome", published: false)
//        let post = try TestDataBuilder.anyPost(author: currentUser)
//
//        let site = buildsite(currentPageURL: adminPageURL)
//        _ = try await presenter.createIndexView(posts: [draftPost, post], users: [currentUser], errors: nil, site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? AdminPageContext)
//
//        XCTAssertEqual(viewRenderer.templatePath, "blog/admin/index")
//        XCTAssertTrue(context.blogAdminPage)
//        XCTAssertEqual(context.title, "Blog Admin")
//        XCTAssertNil(context.errors)
//        XCTAssertEqual(context.publishedPosts.count, 1)
//        XCTAssertEqual(context.publishedPosts.first?.title, post.title)
//        XCTAssertEqual(context.draftPosts.count, 1)
//        XCTAssertEqual(context.draftPosts.first?.title, draftPost.title)
//        XCTAssertEqual(context.users.count, 1)
//        XCTAssertEqual(context.users.first?.name, currentUser.name)
//
//        XCTAssertEqual(context.site.loggedInUser.name, currentUser.name)
//        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/blog/admin")
//        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
//    }
//
//    func testAdminPageWithErrors() async throws {
//        let expectedError = "You cannot delete yourself!"
//        let site = buildsite(currentPageURL: adminPageURL)
//        _ = try await presenter.createIndexView(posts: [], users: [], errors: [expectedError], site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? AdminPageContext)
//        XCTAssertEqual(context.errors?.first, expectedError)
//    }
//
//    // MARK: - Create/Edit User Page
//
//    func testCreateUserViewGetsCorrectParameters() async throws {
//        let site = buildsite(currentPageURL: createUserPageURL)
//        _ = try await presenter.createUserView(editing: false, errors: nil, name: nil, nameError: false, username: nil, usernameErorr: false, passwordError: false, confirmPasswordError: false, resetPasswordOnLogin: false, userID: nil, profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil, site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? CreateUserPageContext)
//
//        XCTAssertEqual(context.title, "Create User")
//        XCTAssertFalse(context.editing)
//        XCTAssertNil(context.errors)
//        XCTAssertNil(context.nameSupplied)
//        XCTAssertFalse(context.nameError)
//        XCTAssertNil(context.usernameSupplied)
//        XCTAssertFalse(context.usernameError)
//        XCTAssertFalse(context.passwordError)
//        XCTAssertFalse(context.confirmPasswordError)
//        XCTAssertFalse(context.resetPasswordOnLoginSupplied)
//        XCTAssertNil(context.userID)
//        XCTAssertNil(context.twitterHandleSupplied)
//        XCTAssertNil(context.profilePictureSupplied)
//        XCTAssertNil(context.taglineSupplied)
//        XCTAssertNil(context.biographySupplied)
//        XCTAssertEqual(viewRenderer.templatePath, "blog/admin/createUser")
//
//        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/blog/admin/createUser")
//        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
//        XCTAssertEqual(context.site.loggedInUser.name, currentUser.name)
//    }
//
//    func testCreateUserViewWhenErrors() async throws {
//        let expectedError = "Not valid password"
//        let expectedName = "Luke"
//        let expectedUsername = "luke"
//        let expectedProfilePicture = "https://static.brokenhands.io/steampress/images/authors/luke.png"
//        let expectedTwitterHandler = "luke"
//        let expectedBiography = "The last Jedi in the Galaxy"
//        let expectedTagline = "A son without a father"
//        let site = buildsite(currentPageURL: createUserPageURL)
//
//        _ = try await presenter.createUserView(editing: false, errors: [expectedError], name: expectedName, nameError: false, username: expectedUsername, usernameErorr: false, passwordError: true, confirmPasswordError: true, resetPasswordOnLogin: true, userID: nil, profilePicture: expectedProfilePicture, twitterHandle: expectedTwitterHandler, biography: expectedBiography, tagline: expectedTagline, site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? CreateUserPageContext)
//        XCTAssertEqual(context.errors?.count, 1)
//        XCTAssertEqual(context.errors?.first, expectedError)
//        XCTAssertEqual(context.nameSupplied, expectedName)
//        XCTAssertFalse(context.nameError)
//        XCTAssertEqual(context.usernameSupplied, expectedUsername)
//        XCTAssertFalse(context.usernameError)
//        XCTAssertTrue(context.passwordError)
//        XCTAssertTrue(context.confirmPasswordError)
//        XCTAssertTrue(context.resetPasswordOnLoginSupplied)
//        XCTAssertEqual(context.profilePictureSupplied, expectedProfilePicture)
//        XCTAssertEqual(context.twitterHandleSupplied, expectedTwitterHandler)
//        XCTAssertEqual(context.taglineSupplied, expectedTagline)
//        XCTAssertEqual(context.biographySupplied, expectedBiography)
//    }
//
//    func testCreateUserViewWhenNoNameOrUsernameSupplied() async throws {
//        let expectedError = "No name supplied"
//        let site = buildsite(currentPageURL: createUserPageURL)
//
//        _ = try await presenter.createUserView(editing: false, errors: [expectedError], name: nil, nameError: true, username: nil, usernameErorr: true, passwordError: false, confirmPasswordError: false, resetPasswordOnLogin: true, userID: nil, profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil, site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? CreateUserPageContext)
//        XCTAssertNil(context.nameSupplied)
//        XCTAssertTrue(context.nameError)
//        XCTAssertNil(context.usernameSupplied)
//        XCTAssertTrue(context.usernameError)
//    }
//
//    func testCreateUserViewForEditing() async throws {
//        let site = buildsite(currentPageURL: editUserPageURL)
//        _ = try await presenter.createUserView(editing: true, errors: nil, name: currentUser.name, nameError: false, username: currentUser.username, usernameErorr: false, passwordError: false, confirmPasswordError: false, resetPasswordOnLogin: false, userID: currentUser.id, profilePicture: currentUser.profilePicture, twitterHandle: currentUser.twitterHandle, biography: currentUser.biography, tagline: currentUser.tagline, site: site)
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? CreateUserPageContext)
//        XCTAssertEqual(context.nameSupplied, currentUser.name)
//        XCTAssertFalse(context.nameError)
//        XCTAssertEqual(context.usernameSupplied, currentUser.username)
//        XCTAssertFalse(context.usernameError)
//        XCTAssertFalse(context.passwordError)
//        XCTAssertFalse(context.confirmPasswordError)
//        XCTAssertFalse(context.resetPasswordOnLoginSupplied)
//        XCTAssertEqual(context.profilePictureSupplied, currentUser.profilePicture)
//        XCTAssertEqual(context.twitterHandleSupplied, currentUser.twitterHandle)
//        XCTAssertEqual(context.taglineSupplied, currentUser.tagline)
//        XCTAssertEqual(context.biographySupplied, currentUser.biography)
//        XCTAssertEqual(context.userID, currentUser.id)
//        XCTAssertTrue(context.editing)
//
//        XCTAssertEqual(viewRenderer.templatePath, "blog/admin/createUser")
//        XCTAssertEqual(context.site.loggedInUser.name, currentUser.name)
//        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
//        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/blog/admin/users/0/edit")
//    }
//
//    func testCreateUserViewThrowsWhenTryingToEditWithoutUserId() async throws {
//        let site = buildsite(currentPageURL: editUserPageURL)
//        var errored = false
//
//        do {
//            _ = try await presenter.createUserView(editing: true, errors: [], name: currentUser.name, nameError: false, username: currentUser.username, usernameErorr: false, passwordError: false, confirmPasswordError: false, resetPasswordOnLogin: false, userID: nil, profilePicture: currentUser.profilePicture, twitterHandle: currentUser.twitterHandle, biography: currentUser.biography, tagline: currentUser.tagline, site: site)
//        } catch {
//            errored = true
//        }
//        XCTAssertTrue(errored)
//    }
//
//    // MARK: - Create/Edit Blog Post
//
//    func testCreateBlogPostViewGetsCorrectParameters() async throws {
//        let site = buildsite(currentPageURL: createBlogPageURL)
//        _ = try await presenter.createPostView(errors: nil, title: nil, contents: nil, slugURL: nil, tags: nil, isEditing: false, post: nil, isDraft: nil, titleError: false, contentsError: false, site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? CreatePostPageContext)
//
//        XCTAssertEqual(context.title, "Create Blog Post")
//        XCTAssertFalse(context.editing)
//        XCTAssertNil(context.post)
//        XCTAssertFalse(context.draft)
//        XCTAssertNil(context.tagsSupplied)
//        XCTAssertNil(context.errors)
//        XCTAssertNil(context.titleSupplied)
//        XCTAssertNil(context.contentsSupplied)
//        XCTAssertNil(context.slugURLSupplied)
//        XCTAssertFalse(context.titleError)
//        XCTAssertFalse(context.contentsError)
//        XCTAssertEqual(context.postPathPrefix, "https://brokenhands.io/blog/posts/")
//
//        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
//        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/blog/admin/createPost")
//        XCTAssertEqual(context.site.loggedInUser.name, currentUser.name)
//
//        XCTAssertEqual(viewRenderer.templatePath, "blog/admin/createPost")
//    }
//
//    func testCreateBlogPostViewWithErrorsAndNoTitleOrContentsSupplied() async throws {
//        let expectedError = "Please enter a title"
//
//        let site = buildsite(currentPageURL: createBlogPageURL)
//        _ = try await presenter.createPostView(errors: [expectedError], title: nil, contents: nil, slugURL: nil, tags: nil, isEditing: false, post: nil, isDraft: nil, titleError: true, contentsError: true, site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? CreatePostPageContext)
//
//        XCTAssertTrue(context.titleError)
//        XCTAssertTrue(context.contentsError)
//        XCTAssertEqual(context.errors?.count, 1)
//        XCTAssertEqual(context.errors?.first, expectedError)
//
//        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
//        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/blog/admin/createPost")
//        XCTAssertEqual(context.site.loggedInUser.name, currentUser.name)
//    }
//
//    func testCreateBlogPostViewWhenEditing() async throws {
//        let postToEdit = try TestDataBuilder.anyPost(author: currentUser)
//        let tag = "Engineering"
//        let site = buildsite(currentPageURL: editPostPageURL)
//
//        _ = try await presenter.createPostView(errors: nil, title: postToEdit.title, contents: postToEdit.contents, slugURL: postToEdit.slugURL, tags: [tag], isEditing: true, post: postToEdit, isDraft: false, titleError: false, contentsError: false, site: site)
//
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? CreatePostPageContext)
//
//        XCTAssertEqual(context.title, "Edit Blog Post")
//        XCTAssertTrue(context.editing)
//        XCTAssertEqual(context.titleSupplied, postToEdit.title)
//        XCTAssertEqual(context.contentsSupplied, postToEdit.contents)
//        XCTAssertEqual(context.slugURLSupplied, postToEdit.slugURL)
//        XCTAssertEqual(context.post?.title, postToEdit.title)
//        XCTAssertEqual(context.post?.id, postToEdit.id)
//        XCTAssertFalse(context.draft)
//        XCTAssertEqual(context.tagsSupplied?.count, 1)
//        XCTAssertEqual(context.tagsSupplied?.first, tag)
//        XCTAssertNil(context.errors)
//        XCTAssertFalse(context.titleError)
//        XCTAssertFalse(context.contentsError)
//        XCTAssertEqual(context.postPathPrefix, "https://brokenhands.io/blog/posts/")
//
//        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
//        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/blog/admin/posts/0/edit")
//        XCTAssertEqual(context.site.loggedInUser.name, currentUser.name)
//
//        XCTAssertEqual(viewRenderer.templatePath, "blog/admin/createPost")
//    }
//
//    func testEditBlogPostViewThrowsWithNoPostToEdit() async throws {
//        var errored = false
//        do {
//            let site = buildsite(currentPageURL: editPostPageURL)
//            _ = try await presenter.createPostView(errors: nil, title: nil, contents: nil, slugURL: nil, tags: nil, isEditing: true, post: nil, isDraft: nil, titleError: false, contentsError: false, site: site)
//        } catch {
//            errored = true
//        }
//
//        XCTAssertTrue(errored)
//    }
//
//    func testDraftPassedThroughWhenEditingABlogPostThatHasNotBeenPublished() async throws {
//        let draftPost = try TestDataBuilder.anyPost(author: currentUser, published: false)
//        let site = buildsite(currentPageURL: editPostPageURL)
//
//        _ = try await presenter.createPostView(errors: nil, title: draftPost.title, contents: draftPost.contents, slugURL: draftPost.slugURL, tags: nil, isEditing: true, post: draftPost, isDraft: true, titleError: false, contentsError: false, site: site)
//        let context = try XCTUnwrap(viewRenderer.capturedContext as? CreatePostPageContext)
//
//        XCTAssertTrue(context.draft)
//    }
//
//    // MARK: - Helpers
//
//    private func buildsite(currentPageURL: URL, user: BlogUser? = nil) -> GlobalWebsiteInformation {
//        let loggedInUser: BlogUser
//        if let user = user {
//            loggedInUser = user
//        } else {
//            loggedInUser = currentUser
//        }
//        return GlobalWebsiteInformation(loggedInUser: loggedInUser, url: url, currentPageURL: currentPageURL)
//    }
//}
