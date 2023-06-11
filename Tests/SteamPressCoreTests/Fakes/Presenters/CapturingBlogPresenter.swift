@testable import SteamPressCore
import Vapor

import Foundation

class CapturingBlogPresenter: BlogPresenter {
    
    let eventLoop: EventLoop
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }
    
    func `for`(_ request: Request) -> BlogPresenter {
        return self
    }

    // MARK: - BlogPresenter
    private(set) var indexPosts: [BlogPost]?
    private(set) var indexTags: [BlogTag]?
    private(set) var indexAuthors: [BlogUser]?
    private(set) var indexsite: GlobalWebsiteInformation?
    private(set) var indexPaginationTagInfo: PaginationTagInformation?
    private(set) var indexTagsForPosts: [UUID: [BlogTag]]?
    func indexView(posts: [BlogPost], tags: [BlogTag], authors: [BlogUser], tagsForPosts: [UUID : [BlogTag]], site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) -> View {
        self.indexPosts = posts
        self.indexTags = tags
        self.indexAuthors = authors
        self.indexsite = site
        self.indexPaginationTagInfo = paginationTagInfo
        self.indexTagsForPosts = tagsForPosts
        return TestDataBuilder.createFutureView()
    }

    private(set) var post: BlogPost?
    private(set) var postAuthor: BlogUser?
    private(set) var postsite: GlobalWebsiteInformation?
    private(set) var postPageTags: [BlogTag]?
    func postView(post: BlogPost, author: BlogUser, tags: [BlogTag], site: GlobalWebsiteInformation) -> View {
        self.post = post
        self.postAuthor = author
        self.postsite = site
        self.postPageTags = tags
        return TestDataBuilder.createFutureView()
    }

    private(set) var allAuthors: [BlogUser]?
    private(set) var allAuthorsPostCount: [UUID: Int]?
    private(set) var allAuthorssite: GlobalWebsiteInformation?
    func allAuthorsView(authors: [BlogUser], authorPostCounts: [UUID: Int], site: GlobalWebsiteInformation) -> View {
        self.allAuthors = authors
        self.allAuthorsPostCount = authorPostCounts
        self.allAuthorssite = site
        return TestDataBuilder.createFutureView()
    }

    private(set) var author: BlogUser?
    private(set) var authorPosts: [BlogPost]?
    private(set) var authorPostCount: Int?
    private(set) var authorsite: GlobalWebsiteInformation?
    private(set) var authorPaginationTagInfo: PaginationTagInformation?
    private(set) var authorPageTagsForPost: [UUID: [BlogTag]]?
    func authorView(author: BlogUser, posts: [BlogPost], postCount: Int, tagsForPosts: [UUID : [BlogTag]], site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) -> View {
        self.author = author
        self.authorPosts = posts
        self.authorPostCount = postCount
        self.authorsite = site
        self.authorPaginationTagInfo = paginationTagInfo
        self.authorPageTagsForPost = tagsForPosts
        return TestDataBuilder.createFutureView()
    }

    private(set) var allTagsPageTags: [BlogTag]?
    private(set) var allTagsPagePostCount: [UUID: Int]?
    private(set) var allTagssite: GlobalWebsiteInformation?
    func allTagsView(tags: [BlogTag], tagPostCounts: [UUID: Int], site: GlobalWebsiteInformation) -> View {
        self.allTagsPageTags = tags
        self.allTagsPagePostCount = tagPostCounts
        self.allTagssite = site
        return TestDataBuilder.createFutureView()
    }

    private(set) var tag: BlogTag?
    private(set) var tagPosts: [BlogPost]?
    private(set) var tagsite: GlobalWebsiteInformation?
    private(set) var tagPaginationTagInfo: PaginationTagInformation?
    private(set) var tagPageTotalPosts: Int?
    private(set) var tagPageAuthors: [BlogUser]?
    func tagView(tag: BlogTag, posts: [BlogPost], authors: [BlogUser], totalPosts: Int, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) -> View {
        self.tag = tag
        self.tagPosts = posts
        self.tagsite = site
        self.tagPaginationTagInfo = paginationTagInfo
        self.tagPageTotalPosts = totalPosts
        self.tagPageAuthors = authors
        return TestDataBuilder.createFutureView()
    }

    private(set) var searchPosts: [BlogPost]?
    private(set) var searchAuthors: [BlogUser]?
    private(set) var searchTerm: String?
    private(set) var searchTotalResults: Int?
    private(set) var searchsite: GlobalWebsiteInformation?
    private(set) var searchPaginationTagInfo: PaginationTagInformation?
    private(set) var searchPageTagsForPost: [UUID: [BlogTag]]?
    func searchView(totalResults: Int, posts: [BlogPost], authors: [BlogUser], searchTerm: String?, tagsForPosts: [UUID : [BlogTag]], site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) -> View {
        self.searchPosts = posts
        self.searchTerm = searchTerm
        self.searchsite = site
        self.searchTotalResults = totalResults
        self.searchAuthors = authors
        self.searchPaginationTagInfo = paginationTagInfo
        self.searchPageTagsForPost = tagsForPosts
        return TestDataBuilder.createFutureView()
    }

    private(set) var loginWarning: Bool?
    private(set) var loginErrors: [String]?
    private(set) var loginUsername: String?
    private(set) var loginUsernameError: Bool?
    private(set) var loginPasswordError: Bool?
    private(set) var loginsite: GlobalWebsiteInformation?
    private(set) var loginPageRememberMe: Bool?
    func loginView(loginWarning: Bool, errors: [String]?, username: String?, usernameError: Bool, passwordError: Bool, rememberMe: Bool, site: GlobalWebsiteInformation) -> View {
        self.loginWarning = loginWarning
        self.loginErrors = errors
        self.loginUsername = username
        self.loginUsernameError = usernameError
        self.loginPasswordError = passwordError
        self.loginsite = site
        self.loginPageRememberMe = rememberMe
        return TestDataBuilder.createFutureView()
    }
}
