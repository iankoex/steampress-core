import Vapor

protocol BlogPresenter {
    func `for`(_ request: Request) -> BlogPresenter
    func indexView(posts: [BlogPost], site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func postView(post: BlogPost, site: GlobalWebsiteInformation) async throws -> View
    func allAuthorsView(authors: [BlogUser.Public], authorPostCounts: [UUID: Int], site: GlobalWebsiteInformation) async throws -> View
    func authorView(author: BlogUser.Public, posts: [BlogPost], postCount: Int, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func allTagsView(tags: [BlogTag], tagPostCounts: [UUID: Int], site: GlobalWebsiteInformation) async throws -> View
    func tagView(tag: BlogTag, posts: [BlogPost], authors: [BlogUser.Public], totalPosts: Int, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func searchView(totalResults: Int, posts: [BlogPost], authors: [BlogUser.Public], tags: [BlogTag], searchTerm: String?, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func loginView(loginWarning: Bool, errors: [String]?, username: String?, usernameError: Bool, passwordError: Bool, rememberMe: Bool, site: GlobalWebsiteInformation) async throws -> View
}

extension ViewBlogPresenter {
    func `for`(_ request: Request) -> BlogPresenter {
        return ViewBlogPresenter(viewRenderer: request.view)
    }
}
