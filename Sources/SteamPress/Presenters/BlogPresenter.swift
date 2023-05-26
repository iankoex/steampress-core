import Vapor

protocol BlogPresenter {
    func `for`(_ request: Request) -> BlogPresenter
    func indexView(posts: [BlogPost], tags: [BlogTag], authors: [BlogUser], tagsForPosts: [Int: [BlogTag]], pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func postView(post: BlogPost, author: BlogUser, tags: [BlogTag], pageInformation: BlogGlobalPageInformation) async throws -> View
    func allAuthorsView(authors: [BlogUser], authorPostCounts: [Int: Int], pageInformation: BlogGlobalPageInformation) async throws -> View
    func authorView(author: BlogUser, posts: [BlogPost], postCount: Int, tagsForPosts: [Int: [BlogTag]], pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func allTagsView(tags: [BlogTag], tagPostCounts: [Int: Int], pageInformation: BlogGlobalPageInformation) async throws -> View
    func tagView(tag: BlogTag, posts: [BlogPost], authors: [BlogUser], totalPosts: Int, pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func searchView(totalResults: Int, posts: [BlogPost], authors: [BlogUser], searchTerm: String?, tagsForPosts: [Int: [BlogTag]], pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func loginView(loginWarning: Bool, errors: [String]?, username: String?, usernameError: Bool, passwordError: Bool, rememberMe: Bool, pageInformation: BlogGlobalPageInformation) async throws -> View
}

extension ViewBlogPresenter {
    func `for`(_ request: Request) -> BlogPresenter {
        return ViewBlogPresenter(viewRenderer: request.view, longDateFormatter: LongPostDateFormatter(), numericDateFormatter: NumericPostDateFormatter())
    }
}
