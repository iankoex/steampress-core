import Vapor

protocol BlogPresenter {
    func `for`(_ request: Request) -> BlogPresenter
    func indexView(posts: [BlogPost], tags: [BlogTag], authors: [BlogUser.Public], tagsForPosts: [UUID: [BlogTag]], website: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func postView(post: BlogPost, author: BlogUser.Public, tags: [BlogTag], website: GlobalWebsiteInformation) async throws -> View
    func allAuthorsView(authors: [BlogUser.Public], authorPostCounts: [UUID: Int], website: GlobalWebsiteInformation) async throws -> View
    func authorView(author: BlogUser.Public, posts: [BlogPost], postCount: Int, tagsForPosts: [UUID: [BlogTag]], website: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func allTagsView(tags: [BlogTag], tagPostCounts: [UUID: Int], website: GlobalWebsiteInformation) async throws -> View
    func tagView(tag: BlogTag, posts: [BlogPost], authors: [BlogUser.Public], totalPosts: Int, website: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func searchView(totalResults: Int, posts: [BlogPost], authors: [BlogUser.Public], searchTerm: String?, tagsForPosts: [UUID: [BlogTag]], website: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func loginView(loginWarning: Bool, errors: [String]?, username: String?, usernameError: Bool, passwordError: Bool, rememberMe: Bool, website: GlobalWebsiteInformation) async throws -> View
}

extension ViewBlogPresenter {
    func `for`(_ request: Request) -> BlogPresenter {
        return ViewBlogPresenter(viewRenderer: request.view, longDateFormatter: LongPostDateFormatter(), numericDateFormatter: NumericPostDateFormatter())
    }
}
