@testable import SteamPressCore
import Vapor

import Foundation

class CapturingBlogPresenter: BlogPresenter {
    required init(_ req: Request) {
        
    }
    
    func `for`(_ request: Request) -> BlogPresenter {
        return self
    }

    // MARK: - BlogPresenter
    private(set) var indexPosts: [BlogPost]?
    private(set) var indexsite: GlobalWebsiteInformation?
    func indexView(posts: [BlogPost], site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View {
        self.indexPosts = posts
        self.indexsite = site
        return TestDataBuilder.createView()
    }

    private(set) var post: BlogPost?
    private(set) var postsite: GlobalWebsiteInformation?
    func postView(post: BlogPost, site: GlobalWebsiteInformation) async throws -> View {
        self.post = post
        self.postsite = site
        return TestDataBuilder.createView()
    }

    private(set) var allAuthors: [BlogUser.Public]?
    private(set) var allAuthorsPostCount: [UUID: Int]?
    private(set) var allAuthorssite: GlobalWebsiteInformation?
    func allAuthorsView(authors: [BlogUser.Public], authorPostCounts: [UUID : Int], site: GlobalWebsiteInformation) async throws -> View {
        self.allAuthors = authors
        self.allAuthorsPostCount = authorPostCounts
        self.allAuthorssite = site
        return TestDataBuilder.createView()
    }

    private(set) var author: BlogUser.Public?
    private(set) var authorPosts: [BlogPost]?
    private(set) var authorPostCount: Int?
    private(set) var authorsite: GlobalWebsiteInformation?
    private(set) var authorPaginationTagInfo: PaginationTagInformation?
    func authorView(author: BlogUser.Public, posts: [BlogPost], postCount: Int, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View {
        self.author = author
        self.authorPosts = posts
        self.authorPostCount = postCount
        self.authorsite = site
        self.authorPaginationTagInfo = paginationTagInfo
        return TestDataBuilder.createView()
    }
    
    private(set) var allTagsPageTags: [BlogTag]?
    private(set) var allTagsPagePostCount: [UUID: Int]?
    private(set) var allTagssite: GlobalWebsiteInformation?
    func allTagsView(tags: [BlogTag], tagPostCounts: [UUID : Int], site: GlobalWebsiteInformation) async throws -> View {
        self.allTagsPageTags = tags
        self.allTagsPagePostCount = tagPostCounts
        self.allTagssite = site
        return TestDataBuilder.createView()
    }

    private(set) var tag: BlogTag?
    private(set) var tagPosts: [BlogPost]?
    private(set) var tagsite: GlobalWebsiteInformation?
    private(set) var tagPaginationTagInfo: PaginationTagInformation?
    private(set) var tagPageTotalPosts: Int?
    private(set) var tagPageAuthors: [BlogUser.Public]?
    func tagView(tag: BlogTag, posts: [BlogPost], authors: [BlogUser.Public], totalPosts: Int, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View {
        self.tag = tag
        self.tagPosts = posts
        self.tagsite = site
        self.tagPaginationTagInfo = paginationTagInfo
        self.tagPageTotalPosts = totalPosts
        self.tagPageAuthors = authors
        return TestDataBuilder.createView()
    }

    private(set) var searchPosts: [BlogPost]?
    private(set) var searchAuthors: [BlogUser.Public]?
    private(set) var searchTerm: String?
    private(set) var searchTotalResults: Int?
    private(set) var searchsite: GlobalWebsiteInformation?
    private(set) var searchPaginationTagInfo: PaginationTagInformation?
    private(set) var searchPageTags: [BlogTag]?
    func searchView(totalResults: Int, posts: [BlogPost], authors: [BlogUser.Public], tags: [BlogTag], searchTerm: String?, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View {
        self.searchPosts = posts
        self.searchTerm = searchTerm
        self.searchsite = site
        self.searchTotalResults = totalResults
        self.searchAuthors = authors
        self.searchPaginationTagInfo = paginationTagInfo
        self.searchPageTags = tags
        return TestDataBuilder.createView()
    }
}
