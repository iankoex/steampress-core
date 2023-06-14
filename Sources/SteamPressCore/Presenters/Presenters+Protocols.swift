import Vapor

public protocol SteamPressPresenter {
    init(_ req: Request)
}

public protocol BlogPresenter: SteamPressPresenter {
    func `for`(_ request: Request) -> BlogPresenter
    func indexView(posts: [BlogPost], site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func postView(post: BlogPost, site: GlobalWebsiteInformation) async throws -> View
    func allAuthorsView(authors: [BlogUser.Public], authorPostCounts: [UUID: Int], site: GlobalWebsiteInformation) async throws -> View
    func authorView(author: BlogUser.Public, posts: [BlogPost], postCount: Int, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func allTagsView(tags: [BlogTag], tagPostCounts: [UUID: Int], site: GlobalWebsiteInformation) async throws -> View
    func tagView(tag: BlogTag, posts: [BlogPost], authors: [BlogUser.Public], totalPosts: Int, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
    func searchView(totalResults: Int, posts: [BlogPost], authors: [BlogUser.Public], tags: [BlogTag], searchTerm: String?, site: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View
}

public protocol BlogAdminPresenter: SteamPressPresenter {
    func `for`(_ request: Request) -> BlogAdminPresenter
    func createIndexView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View
    func createExploreView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View
    func createPagesView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View
    func createTagsView(tags: [BlogTag], usersCount: Int, site: GlobalWebsiteInformation) async throws -> View
    func createCreateTagView(usersCount: Int, site: GlobalWebsiteInformation) async throws -> View
    func createEditTagView(tag: BlogTag, usersCount: Int, site: GlobalWebsiteInformation) async throws -> View
    func createPostsView(posts: [BlogPost], usersCount: Int, site: GlobalWebsiteInformation) async throws -> View
    func createPostView(errors: [String]?, tags: [BlogTag], post: BlogPost?, titleSupplied: String?, contentSupplied: String?, excerptSupplied: String?, site: GlobalWebsiteInformation) async throws -> View
    func createResetPasswordView(errors: [String]?, site: GlobalWebsiteInformation) async throws -> View
    func loginView(loginWarning: Bool, errors: [String]?, email: String?, rememberMe: Bool, requireName: Bool, site: GlobalWebsiteInformation) async throws -> View
    func createMembersView(users: [BlogUser.Public], usersCount: Int, site: GlobalWebsiteInformation) async throws -> View
    func createCreateMemberView(userData: CreateUserData?, errors: [String]?, usersCount: Int, site: GlobalWebsiteInformation) async throws -> View
}
