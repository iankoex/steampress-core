@testable import SteamPress
import XCTest
import Vapor

class BlogPresenterTests: XCTestCase {

    // MARK: - Properties
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var presenter: ViewBlogPresenter!
    var viewRenderer: CapturingViewRenderer!
    var testTag: BlogTag!

    private let allTagsURL = URL(string: "https://brokenhands.io/tags")!
    private let allAuthorsURL = URL(string: "https://brokenhands.io/authors")!
    private let tagURL = URL(string: "https://brokenhands.io/tags/tattoine")!
    private let blogIndexURL = URL(string: "https://brokenhands.io/blog")!
    private let authorURL = URL(string: "https://brokenhands.io/authors/luke")!
    private let loginURL = URL(string: "https://brokenhands.io/admin/login")!
    private let url = URL(string: "https://brokenhands.io")!
    private let searchURL = URL(string: "https://brokenhands.io/search?term=vapor")!
    private let uuidZero = UUID()
    private let uuidOne = UUID()
    private let uuidTwo = UUID()
    private let uuidThree = UUID()

    private static let twitterHandle = "brokenhandsio"
    private static let disqusName = "steampress"
    private static let googleAnalyticsIdentifier = "UA-12345678-1"
    // MARK: - Overrides

    override func setUp() {
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        viewRenderer = CapturingViewRenderer(eventLoop: eventLoopGroup.next())
        presenter = ViewBlogPresenter(viewRenderer: viewRenderer, longDateFormatter: LongPostDateFormatter(), numericDateFormatter: NumericPostDateFormatter())
        testTag = BlogTag(id: uuidOne, name: "Tattoine")
    }
    
    override func tearDownWithError() throws {
        try eventLoopGroup.syncShutdownGracefully()
    }

    // MARK: - Tests

    // MARK: - All Tags Page

    func testParametersAreSetCorrectlyOnAllTagsPage() async throws {
        let tags = [BlogTag(id: uuidZero, name: "tag1"), BlogTag(id: uuidOne, name: "tag2")]

        let site = buildsite(currentPageURL: allTagsURL)
        _ = try await presenter.allTagsView(tags: tags, tagPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllTagsPageContext)

        XCTAssertEqual(context.tags.count, 2)
        XCTAssertEqual(context.tags.first?.name, "tag1")
        XCTAssertEqual(context.tags[1].name, "tag2")
        XCTAssertEqual(context.title, "All Tags")
        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/tags")
        XCTAssertEqual(context.site.twitterHandle, BlogPresenterTests.twitterHandle)
        XCTAssertEqual(context.site.disqusName, BlogPresenterTests.disqusName)
        XCTAssertEqual(context.site.googleAnalyticsIdentifier, BlogPresenterTests.googleAnalyticsIdentifier)
        XCTAssertNil(context.site.loggedInUser)
        XCTAssertEqual(viewRenderer.templatePath, "blog/tags")
    }

    func testTagsPageGetsPassedTagsSortedByPostCount() async throws {
        let tag1 = BlogTag(id: uuidZero, name: "Engineering")
        let tag2 = BlogTag(id: uuidOne, name: "Tech")
        let tags = [tag1, tag2]
        let tagPostCount = [uuidZero: 5, uuidOne: 20]
        let site = buildsite(currentPageURL: allTagsURL)
        _ = try await presenter.allTagsView(tags: tags, tagPostCounts: tagPostCount, site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllTagsPageContext)
        XCTAssertEqual(context.tags.first?.postCount, 20)
        XCTAssertEqual(context.tags.first?.id, uuidOne)
        XCTAssertEqual(context.tags[1].id, uuidZero)
        XCTAssertEqual(context.tags[1].postCount, 5)
    }

    func testTagsPageHandlesNoPostsForTagsCorrectly() async throws {
        let tag1 = BlogTag(id: uuidZero, name: "Engineering")
        let tag2 = BlogTag(id: uuidOne, name: "Tech")
        let tags = [tag1, tag2]
        let tagPostCount = [uuidZero: 0, uuidOne: 20]
        let site = buildsite(currentPageURL: allTagsURL)
        _ = try await presenter.allTagsView(tags: tags, tagPostCounts: tagPostCount, site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllTagsPageContext)
        XCTAssertEqual(context.tags[1].id, uuidZero)
        XCTAssertEqual(context.tags[1].postCount, 0)
    }

    func testTwitterHandleNotSetOnAllTagsPageIfNotGiven() async throws {
        let tags = [BlogTag(id: uuidZero, name: "tag1"), BlogTag(id: uuidOne, name: "tag2")]
        let site = buildsite(currentPageURL: allTagsURL, twitterHandle: nil)
        _ = try await presenter.allTagsView(tags: tags, tagPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllTagsPageContext)
        XCTAssertNil(context.site.twitterHandle)
    }

    func testDisqusNameNotSetOnAllTagsPageIfNotGiven() async throws {
        let tags = [BlogTag(id: uuidZero, name: "tag1"), BlogTag(id: uuidOne, name: "tag2")]
        let site = buildsite(currentPageURL: allTagsURL, disqusName: nil)
        _ = try await presenter.allTagsView(tags: tags, tagPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllTagsPageContext)
        XCTAssertNil(context.site.disqusName)
    }

    func testGAIdentifierNotSetOnAllTagsPageIfNotGiven() async throws {
        let tags = [BlogTag(id: uuidZero, name: "tag1"), BlogTag(id: uuidOne, name: "tag2")]
        let site = buildsite(currentPageURL: allTagsURL, googleAnalyticsIdentifier: nil)
        _ = try await presenter.allTagsView(tags: tags, tagPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllTagsPageContext)
        XCTAssertNil(context.site.googleAnalyticsIdentifier)
    }

    func testLoggedInUserSetOnAllTagsPageIfPassedIn() async throws {
        let tags = [BlogTag(id: uuidZero, name: "tag1"), BlogTag(id: uuidOne, name: "tag2")]
        let user = TestDataBuilder.anyUser()
        let site = buildsite(currentPageURL: allTagsURL, user: user)
        _ = try await presenter.allTagsView(tags: tags, tagPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllTagsPageContext)
        XCTAssertEqual(context.site.loggedInUser?.name, user.name)
        XCTAssertEqual(context.site.loggedInUser?.username, user.username)
    }

    // MARK: - All authors

    func testParametersAreSetCorrectlyOnAllAuthorsPage() async throws {
        let user1 = TestDataBuilder.anyUser(id: uuidZero)
        let user2 = TestDataBuilder.anyUser(id: uuidOne, name: "Han", username: "han")
        let authors = [user1, user2]
        let site = buildsite(currentPageURL: allAuthorsURL)
        _ = try await presenter.allAuthorsView(authors: authors, authorPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllAuthorsPageContext)
        XCTAssertEqual(context.authors.count, 2)
        XCTAssertEqual(context.authors.first?.name, "Luke")
        XCTAssertEqual(context.authors[1].name, "Han")
        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/authors")
        XCTAssertEqual(context.site.twitterHandle, BlogPresenterTests.twitterHandle)
        XCTAssertEqual(context.site.disqusName, BlogPresenterTests.disqusName)
        XCTAssertEqual(context.site.googleAnalyticsIdentifier, BlogPresenterTests.googleAnalyticsIdentifier)
        XCTAssertNil(context.site.loggedInUser)
        XCTAssertEqual(viewRenderer.templatePath, "blog/authors")
    }

    func testAuthorsPageGetsPassedAuthorsSortedByPostCount() async throws {
        let user1 = TestDataBuilder.anyUser(id: uuidZero)
        let user2 = TestDataBuilder.anyUser(id: uuidOne, name: "Han", username: "han")
        let authors = [user1, user2]
        let authorPostCount = [uuidZero: 1, uuidOne: 20]
        let site = buildsite(currentPageURL: allAuthorsURL)
        _ = try await presenter.allAuthorsView(authors: authors, authorPostCounts: authorPostCount, site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllAuthorsPageContext)
        XCTAssertEqual(context.authors.first?.postCount, 20)
        XCTAssertEqual(context.authors.first?.userID, uuidOne)
        XCTAssertEqual(context.authors[1].userID, uuidZero)
        XCTAssertEqual(context.authors[1].postCount, 1)
    }

    func testAuthorsPageHandlesNoPostsForAuthorCorrectly() async throws {
        let user1 = TestDataBuilder.anyUser(id: uuidZero)
        let user2 = TestDataBuilder.anyUser(id: uuidOne, name: "Han", username: "han")
        let authors = [user1, user2]
        let authorPostCount = [uuidZero: 0, uuidOne: 20]
        let site = buildsite(currentPageURL: allAuthorsURL)
        _ = try await presenter.allAuthorsView(authors: authors, authorPostCounts: authorPostCount, site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllAuthorsPageContext)
        XCTAssertEqual(context.authors[1].userID, uuidZero)
        XCTAssertEqual(context.authors[1].postCount, 0)
    }

    func testTwitterHandleNotSetOnAllAuthorsPageIfNotProvided() async throws {
        let site = buildsite(currentPageURL: allAuthorsURL, twitterHandle: nil)
        _ = try await presenter.allAuthorsView(authors: [], authorPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllAuthorsPageContext)
        XCTAssertNil(context.site.twitterHandle)
    }

    func testDisqusNameNotSetOnAllAuthorsPageIfNotProvided() async throws {
        let site = buildsite(currentPageURL: allAuthorsURL, disqusName: nil)
        _ = try await presenter.allAuthorsView(authors: [], authorPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllAuthorsPageContext)
        XCTAssertNil(context.site.disqusName)
    }

    func testGAIdentifierNotSetOnAllAuthorsPageIfNotProvided() async throws {
        let site = buildsite(currentPageURL: allAuthorsURL, googleAnalyticsIdentifier: nil)
        _ = try await presenter.allAuthorsView(authors: [], authorPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllAuthorsPageContext)
        XCTAssertNil(context.site.googleAnalyticsIdentifier)
    }

    func testLoggedInUserPassedToAllAuthorsPageIfProvided() async throws {
        let user = TestDataBuilder.anyUser()
        let site = buildsite(currentPageURL: allAuthorsURL, user: user)
        _ = try await presenter.allAuthorsView(authors: [], authorPostCounts: [:], site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AllAuthorsPageContext)
        XCTAssertEqual(context.site.loggedInUser?.name, user.name)
        XCTAssertEqual(context.site.loggedInUser?.username, user.username)
    }

    // MARK: - Tag page

    func testTagPageGetsTagWithCorrectParamsAndPostCount() async throws {
        let user = TestDataBuilder.anyUser(id: uuidThree)
        let post1 = try TestDataBuilder.anyPost(author: user)
        post1.id = uuidOne
        let post2 = try TestDataBuilder.anyPost(author: user)
        post2.id = uuidTwo
        let posts = [post1, post2]
        let site = buildsite(currentPageURL: tagURL, user: user)
        let currentPage = 2
        let totalPages = 10
        let currentQuery = "?page=2"

        _ = try await presenter.tagView(tag: testTag, posts: posts, authors: [user], totalPosts: 3, site: site, paginationTagInfo: buildPaginationInformation(currentPage: currentPage, totalPages: totalPages, currentQuery: currentQuery))

        let context = try XCTUnwrap(viewRenderer.capturedContext as? TagPageContext)
        XCTAssertEqual(context.tag.name, testTag.name)
        XCTAssertEqual(context.posts.count, 2)
        XCTAssertEqual(context.posts.first?.title, post1.title)
        XCTAssertEqual(context.posts.first?.blogID, post1.id)
        XCTAssertEqual(context.posts.last?.title, post2.title)
        XCTAssertEqual(context.posts.last?.blogID, post2.id)
        XCTAssertTrue(context.tagPage)
        XCTAssertEqual(context.site.loggedInUser?.name, user.name)
        XCTAssertEqual(context.site.loggedInUser?.username, user.username)
        XCTAssertEqual(context.site.googleAnalyticsIdentifier, BlogPresenterTests.googleAnalyticsIdentifier)
        XCTAssertEqual(context.site.twitterHandle, BlogPresenterTests.twitterHandle)
        XCTAssertEqual(context.site.disqusName, BlogPresenterTests.disqusName)
        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/tags/tattoine")
        XCTAssertEqual(viewRenderer.templatePath, "blog/tag")
        XCTAssertEqual(context.paginationTagInformation.currentPage, currentPage)
        XCTAssertEqual(context.paginationTagInformation.totalPages, totalPages)
        XCTAssertEqual(context.paginationTagInformation.currentQuery, currentQuery)
        XCTAssertEqual(context.postCount, 3)
        XCTAssertEqual(context.posts.first?.authorUsername, user.username)
        XCTAssertEqual(context.posts.first?.authorName, user.name)
    }

    func testNoLoggedInUserPassedToTagPageIfNoneProvided() async throws {
        let site = buildsite(currentPageURL: tagURL)
        _ = try await presenter.tagView(tag: testTag, posts: [], authors: [], totalPosts: 0, site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? TagPageContext)
        XCTAssertNil(context.site.loggedInUser)
    }

    func testDisqusNameNotPassedToTagPageIfNotSet() async throws {
        let site = buildsite(currentPageURL: tagURL, disqusName: nil)
        _ = try await presenter.tagView(tag: testTag, posts: [], authors: [], totalPosts: 0, site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? TagPageContext)
        XCTAssertNil(context.site.disqusName)
    }

    func testTwitterHandleNotPassedToTagPageIfNotSet() async throws {
        let site = buildsite(currentPageURL: tagURL, twitterHandle: nil)
        _ = try await presenter.tagView(tag: testTag, posts: [], authors: [], totalPosts: 0, site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? TagPageContext)
        XCTAssertNil(context.site.twitterHandle)
    }

    func testGAIdentifierNotPassedToTagPageIfNotSet() async throws {
        let site = buildsite(currentPageURL: tagURL, googleAnalyticsIdentifier: nil)
        _ = try await presenter.tagView(tag: testTag, posts: [], authors: [], totalPosts: 0, site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? TagPageContext)
        XCTAssertNil(context.site.googleAnalyticsIdentifier)
    }

    // MARK: - Blog Index

    func testBlogIndexPageGivenCorrectParameters() async throws {
        let createdDate = Date(timeIntervalSince1970: 1584714638)
        let lastEditedDate = Date(timeIntervalSince1970: 1584981458)
        
        let author1 = TestDataBuilder.anyUser(id: uuidZero)
        let author2 = TestDataBuilder.anyUser(id: uuidOne, username: "darth")
        let post = try TestDataBuilder.anyPost(author: author1, contents: TestDataBuilder.longContents, creationDate: createdDate, lastEditedDate: lastEditedDate)
        post.id = uuidOne
        let post2 = try TestDataBuilder.anyPost(author: author2, title: "Another Title")
        post2.id = uuidTwo
        let tag1 = BlogTag(id: uuidOne, name: "Engineering Stuff")
        let tag2 = BlogTag(id: uuidTwo, name: "Fun")
        let tags = [tag1, tag2]
        let currentPage = 2
        let totalPages = 10
        let currentQuery = "?page=2"

        let site = buildsite(currentPageURL: blogIndexURL)
        _ = try await presenter.indexView(posts: [post, post2], tags: tags, authors: [author1, author2], tagsForPosts: [uuidOne: [tag1, tag2], uuidTwo: [tag1]], site: site, paginationTagInfo: buildPaginationInformation(currentPage: currentPage, totalPages: totalPages, currentQuery: currentQuery))

        let context = try XCTUnwrap(viewRenderer.capturedContext as? BlogIndexPageContext)
        XCTAssertEqual(context.title, "Blog")
        XCTAssertEqual(context.posts.count, 2)
        XCTAssertEqual(context.posts.first?.title, post.title)
        XCTAssertEqual(context.posts.first?.authorName, author1.name)
        XCTAssertEqual(context.posts.first?.authorUsername, author1.username)
        XCTAssertEqual(context.posts.first?.tags.count, 2)
        XCTAssertEqual(context.posts.first?.tags.first?.name, tag1.name)
        let expectedDescription = "Welcome to SteamPress! SteamPress started out as an idea - after all, I was porting sites and backends over to Swift and would like to have a blog as well. Being early days for Server-Side Swift, and embracing Vapor, there wasn't anything available to put a blog on my site, so I did what any self-respecting engineer would do - I made one! Besides, what better way to learn a framework than build a blog!"
        XCTAssertEqual(context.posts.first?.description.trimmingCharacters(in: .whitespacesAndNewlines), expectedDescription)
        XCTAssertEqual(context.posts.first?.postImage, "https://user-images.githubusercontent.com/9938337/29742058-ed41dcc0-8a6f-11e7-9cfc-680501cdfb97.png")
        XCTAssertEqual(context.posts.first?.postImageAlt, "SteamPress Logo")
        let expectedSnippet = "Welcome to SteamPress!\nSteamPress started out as an idea - after all, I was porting sites and backends over to Swift and would like to have a blog as well. Being early days for Server-Side Swift, and embracing Vapor, there wasn\'t anything available to put a blog on my site, so I did what any self-respecting engineer would do - I made one! Besides, what better way to learn a framework than build a blog!\nI plan to put some more posts up going into how I actually wrote SteamPress, going into some Vapor basics like Authentication and other popular #help topics on [Slack](qutheory.slack.com) (I probably need to rewrite a lot of it properly first!) either on here or on https://geeks.brokenhands.io, which will be the engineering site for Broken Hands, which is what a lot of future projects I have planned will be under. \n![SteamPress Logo](https://user-images.githubusercontent.com/9938337/29742058-ed41dcc0-8a6f-11e7-9cfc-680501cdfb97.png)\n"
        XCTAssertEqual(context.posts.first?.longSnippet, expectedSnippet)
        XCTAssertEqual(context.posts.first?.createdDateLong, "Friday, Mar 20, 2020")
        XCTAssertEqual(context.posts.first?.createdDateNumeric, "2020-03-20T14:30:38.000Z")
        XCTAssertEqual(context.posts.first?.lastEditedDateLong, "Monday, Mar 23, 2020")
        XCTAssertEqual(context.posts.first?.lastEditedDateNumeric, "2020-03-23T16:37:38.000Z")
        XCTAssertEqual(context.posts.last?.title, post2.title)
        XCTAssertEqual(context.tags.count, 2)
        XCTAssertEqual(context.tags.first?.name, tag1.name)
        XCTAssertEqual(context.tags.first?.urlEncodedName, "Engineering%20Stuff")
        XCTAssertEqual(context.tags.last?.name, tag2.name)
        XCTAssertEqual(context.authors.count, 2)
        XCTAssertEqual(context.authors.first?.username, author1.username)
        XCTAssertEqual(context.authors.last?.username, author2.username)
        XCTAssertTrue(context.blogIndexPage)
        XCTAssertEqual(viewRenderer.templatePath, "blog/blog")
        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/blog")
        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
        XCTAssertEqual(context.site.googleAnalyticsIdentifier, BlogPresenterTests.googleAnalyticsIdentifier)
        XCTAssertEqual(context.site.twitterHandle, BlogPresenterTests.twitterHandle)
        XCTAssertEqual(context.site.disqusName, BlogPresenterTests.disqusName)
        XCTAssertNil(context.site.loggedInUser)
        XCTAssertEqual(context.paginationTagInformation.currentPage, currentPage)
        XCTAssertEqual(context.paginationTagInformation.totalPages, totalPages)
        XCTAssertEqual(context.paginationTagInformation.currentQuery, currentQuery)
        XCTAssertEqual(context.posts.first?.tags.count, 2)
        XCTAssertEqual(context.posts.first?.tags.first?.name, tag1.name)
        XCTAssertEqual(context.posts.last?.tags.count, 1)
    }

    func testUserPassedToBlogIndexIfUserPassedIn() async throws {
        let user = TestDataBuilder.anyUser()
        let site = buildsite(currentPageURL: blogIndexURL, user: user)
        _ = try await presenter.indexView(posts: [], tags: [], authors: [], tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? BlogIndexPageContext)
        XCTAssertEqual(context.site.loggedInUser?.name, user.name)
        XCTAssertEqual(context.site.loggedInUser?.username, user.username)
    }

    func testDisqusNameNotPassedToBlogIndexIfNotPassedIn() async throws {
        let site = buildsite(currentPageURL: blogIndexURL, disqusName: nil)
        _ = try await presenter.indexView(posts: [], tags: [], authors: [], tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? BlogIndexPageContext)
        XCTAssertNil(context.site.disqusName)
    }

    func testTwitterHandleNotPassedToBlogIndexIfNotPassedIn() async throws {
        let site = buildsite(currentPageURL: blogIndexURL, twitterHandle: nil)
        _ = try await presenter.indexView(posts: [], tags: [], authors: [], tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? BlogIndexPageContext)
        XCTAssertNil(context.site.twitterHandle)
    }

    func testGAIdentifierNotPassedToBlogIndexIfNotPassedIn() async throws {
        let site = buildsite(currentPageURL: blogIndexURL, googleAnalyticsIdentifier: nil)
        _ = try await presenter.indexView(posts: [], tags: [], authors: [], tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? BlogIndexPageContext)
        XCTAssertNil(context.site.googleAnalyticsIdentifier)
    }

    // MARK: - Author page

    func testAuthorViewHasCorrectParametersSet() async throws {
        let author = TestDataBuilder.anyUser(id: uuidZero)
        let post1 = try TestDataBuilder.anyPost(author: author)
        post1.id = uuidOne
        let post2 = try TestDataBuilder.anyPost(author: author, title: "Another Post", slugUrl: "another-post")
        post2.id = uuidTwo
        let page = 2
        let totalPages = 10
        let query = "page=2"

        let site = buildsite(currentPageURL: authorURL)
        _ = try await presenter.authorView(author: author, posts: [post1, post2], postCount: 2, tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation(currentPage: page, totalPages: totalPages, currentQuery: query))

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AuthorPageContext)
        XCTAssertEqual(context.author.name, author.name)
        XCTAssertEqual(context.author.tagline, author.tagline)
        XCTAssertEqual(context.author.twitterHandle, author.twitterHandle)
        XCTAssertEqual(context.author.profilePicture, author.profilePicture)
        XCTAssertEqual(context.author.biography, author.biography)
        XCTAssertEqual(context.posts.count, 2)
        XCTAssertEqual(context.posts.first?.title, post1.title)
        XCTAssertEqual(context.posts.last?.title, post2.title)
        XCTAssertFalse(context.myProfile)
        XCTAssertTrue(context.profilePage)
        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/authors/luke")
        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
        XCTAssertNil(context.site.loggedInUser)
        XCTAssertEqual(context.site.disqusName, BlogPresenterTests.disqusName)
        XCTAssertEqual(context.site.googleAnalyticsIdentifier, BlogPresenterTests.googleAnalyticsIdentifier)
        XCTAssertEqual(context.site.twitterHandle, BlogPresenterTests.twitterHandle)
        XCTAssertEqual(viewRenderer.templatePath, "blog/profile")
        XCTAssertEqual(context.paginationTagInformation.currentPage, page)
        XCTAssertEqual(context.paginationTagInformation.totalPages, totalPages)
        XCTAssertEqual(context.paginationTagInformation.currentQuery, query)
    }

    func testAuthorViewGetsLoggedInUserIfProvider() async throws {
        let author = TestDataBuilder.anyUser(id: uuidZero)
        let user = TestDataBuilder.anyUser(id: uuidOne, username: "hans")
        let site = buildsite(currentPageURL: authorURL, user: user)
        _ = try await presenter.authorView(author: author, posts: [], postCount: 0, tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AuthorPageContext)
        XCTAssertEqual(context.site.loggedInUser?.id, user.id)
        XCTAssertEqual(context.site.loggedInUser?.username, user.username)
    }

    func testMyProfileFlagSetIfLoggedInUserIsTheSameAsAuthorOnAuthorView() async throws {
        let author = TestDataBuilder.anyUser(id: uuidZero)
        let site = buildsite(currentPageURL: authorURL, user: author)
        _ = try await presenter.authorView(author: author, posts: [], postCount: 0, tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AuthorPageContext)
        XCTAssertTrue(context.myProfile)
    }

    func testAuthorViewDoesNotGetDisqusNameIfNotProvided() async throws {
        let author = TestDataBuilder.anyUser()
        let site = buildsite(currentPageURL: authorURL, disqusName: nil)
        _ = try await presenter.authorView(author: author, posts: [], postCount: 0, tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AuthorPageContext)
        XCTAssertNil(context.site.disqusName)
    }

    func testAuthorViewDoesNotGetTwitterHandleIfNotProvided() async throws {
        let author = TestDataBuilder.anyUser()
        let site = buildsite(currentPageURL: authorURL, twitterHandle: nil)
        _ = try await presenter.authorView(author: author, posts: [], postCount: 0, tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AuthorPageContext)
        XCTAssertNil(context.site.twitterHandle)
    }

    func testAuthorViewDoesNotGetGAIdentifierIfNotProvided() async throws {
        let author = TestDataBuilder.anyUser()
        let site = buildsite(currentPageURL: authorURL, googleAnalyticsIdentifier: nil)
        _ = try await presenter.authorView(author: author, posts: [], postCount: 0, tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AuthorPageContext)
        XCTAssertNil(context.site.googleAnalyticsIdentifier)
    }

    func testAuthorViewGetsPostCount() async throws {
        let author = TestDataBuilder.anyUser(id: uuidZero)
        let post1 = try TestDataBuilder.anyPost(author: author)
        post1.id = uuidOne
        let post2 = try TestDataBuilder.anyPost(author: author)
        post2.id = uuidTwo
        let post3 = try TestDataBuilder.anyPost(author: author)
        post3.id = uuidThree
        let site = buildsite(currentPageURL: authorURL)
        _ = try await presenter.authorView(author: author, posts: [post1, post2, post3], postCount: 3, tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AuthorPageContext)
        XCTAssertEqual(context.postCount, 3)
    }

    func testAuthorViewGetsLongSnippetForPosts() async throws {
        let author = TestDataBuilder.anyUser(id: uuidZero)
        let post1 = try TestDataBuilder.anyPost(author: author, contents: TestDataBuilder.longContents)
        post1.id = uuidOne
        let site = buildsite(currentPageURL: authorURL)
        _ = try await presenter.authorView(author: author, posts: [post1], postCount: 1, tagsForPosts: [:], site: site, paginationTagInfo: buildPaginationInformation())

        let context = try XCTUnwrap(viewRenderer.capturedContext as? AuthorPageContext)
        let characterCount = try XCTUnwrap(context.posts.first?.longSnippet.count)
        XCTAssertGreaterThan(characterCount, 900)
    }

    func testLoginViewGetsCorrectParameters() async throws {
        let site = buildsite(currentPageURL: loginURL)
        _ = try await presenter.loginView(loginWarning: false, errors: nil, username: nil, usernameError: false, passwordError: false, rememberMe: false, site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? LoginPageContext)
        XCTAssertNil(context.errors)
        XCTAssertFalse(context.loginWarning)
        XCTAssertNil(context.username)
        XCTAssertFalse(context.usernameError)
        XCTAssertFalse(context.passwordError)
        XCTAssertEqual(context.title, "Log In")
        XCTAssertFalse(context.rememberMe)
        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/admin/login")
        XCTAssertEqual(viewRenderer.templatePath, "blog/admin/login")
    }

    func testLoginViewWhenErrored() async throws {
        let expectedError = "Username/password incorrect"
        let site = buildsite(currentPageURL: loginURL)
        _ = try await presenter.loginView(loginWarning: true, errors: [expectedError], username: "tim", usernameError: true, passwordError: true, rememberMe: true, site: site)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? LoginPageContext)
        XCTAssertEqual(context.errors?.count, 1)
        XCTAssertEqual(context.errors?.first, expectedError)
        XCTAssertTrue(context.loginWarning)
        XCTAssertEqual(context.username, "tim")
        XCTAssertTrue(context.usernameError)
        XCTAssertTrue(context.passwordError)
        XCTAssertTrue(context.rememberMe)
    }

    func testSearchPageGetsCorrectParameters() async throws {
        let author = TestDataBuilder.anyUser(id: uuidZero)
        let post1 = try TestDataBuilder.anyPost(author: author, title: "Vapor 1")
        post1.id = uuidOne
        let post2 = try TestDataBuilder.anyPost(author: author, title: "Vapor 2")
        post2.id = uuidTwo
        let site = buildsite(currentPageURL: searchURL)
        let paginationInformation = PaginationTagInformation(currentPage: 1, totalPages: 3, currentQuery: "?term=vapor")

        _ = try await presenter.searchView(totalResults: 2, posts: [post1, post2], authors: [author], searchTerm: "vapor", tagsForPosts: [:], site: site, paginationTagInfo: paginationInformation)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? SearchPageContext)
        XCTAssertEqual(context.title, "Search Blog")
        XCTAssertEqual(context.searchTerm, "vapor")
        XCTAssertEqual(context.posts.count, 2)
        XCTAssertEqual(context.posts.first?.title, "Vapor 1")
        XCTAssertEqual(context.posts.last?.title, "Vapor 2")
        XCTAssertEqual(context.posts.first?.authorName, author.name)

        XCTAssertEqual(viewRenderer.templatePath, "blog/search")
        XCTAssertEqual(context.site.disqusName, BlogPresenterTests.disqusName)
        XCTAssertEqual(context.site.googleAnalyticsIdentifier, BlogPresenterTests.googleAnalyticsIdentifier)
        XCTAssertEqual(context.site.twitterHandle, BlogPresenterTests.twitterHandle)
        XCTAssertNil(context.site.loggedInUser)
        XCTAssertEqual(context.site.url.absoluteString, "https://brokenhands.io")
        XCTAssertEqual(context.site.currentPageURL.absoluteString, "https://brokenhands.io/search?term=vapor")
        XCTAssertEqual(context.paginationTagInformation.currentPage, 1)
        XCTAssertEqual(context.paginationTagInformation.totalPages, 3)
        XCTAssertEqual(context.paginationTagInformation.currentQuery, "?term=vapor")
        XCTAssertEqual(context.totalResults, 2)
    }

    func testSearchPageGetsNilIfNoSearchTermProvided() async throws {
        let site = buildsite(currentPageURL: searchURL)
        let paginationInformation = PaginationTagInformation(currentPage: 0, totalPages: 0, currentQuery: nil)
        _ = try await presenter.searchView(totalResults: 0, posts: [], authors: [], searchTerm: nil, tagsForPosts: [:], site: site, paginationTagInfo: paginationInformation)

        let context = try XCTUnwrap(viewRenderer.capturedContext as? SearchPageContext)
        XCTAssertNil(context.searchTerm)
    }

    // MARK: - Helpers

    private func buildsite(currentPageURL: URL, twitterHandle: String? = BlogPresenterTests.twitterHandle, disqusName: String? = BlogPresenterTests.disqusName, googleAnalyticsIdentifier: String? = BlogPresenterTests.googleAnalyticsIdentifier, user: BlogUser? = nil) -> GlobalWebsiteInformation {
        return GlobalWebsiteInformation(disqusName: disqusName, twitterHandle: twitterHandle, googleAnalyticsIdentifier: googleAnalyticsIdentifier, loggedInUser: user, url: url, currentPageURL: currentPageURL, currentPageEncodedURL: currentPageURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
    }
    
    private func buildPaginationInformation(currentPage: Int = 1, totalPages: Int = 5, currentQuery: String? = nil) -> PaginationTagInformation {
        return PaginationTagInformation(currentPage: currentPage, totalPages: totalPages, currentQuery: currentQuery)
    }

}
