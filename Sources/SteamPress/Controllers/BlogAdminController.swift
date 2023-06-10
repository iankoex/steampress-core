import Vapor

struct BlogAdminController: RouteCollection {

    // MARK: - Properties
    fileprivate let pathCreator: BlogPathCreator

    // MARK: - Initialiser
    init(pathCreator: BlogPathCreator) {
        self.pathCreator = pathCreator
    }

    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        let adminRoutes = routes.grouped("admin")

        let redirectMiddleware = BlogLoginRedirectAuthMiddleware(pathCreator: pathCreator)
        let adminProtectedRoutes = adminRoutes.grouped(redirectMiddleware)
        adminProtectedRoutes.get(use: adminHandler)
        adminProtectedRoutes.get("explore", use: exploreHandler)
        adminProtectedRoutes.get("posts", use: postsHandler)
        adminProtectedRoutes.get("pages", use: pagesHandler)

        let loginController = LoginController(pathCreator: pathCreator)
        try adminRoutes.register(collection: loginController)
        let postController = PostAdminController(pathCreator: pathCreator)
        try adminProtectedRoutes.register(collection: postController)
        let userController = UserAdminController(pathCreator: pathCreator)
        try adminProtectedRoutes.register(collection: userController)
    }

    // MARK: Admin Handler
    func adminHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getAllUsers().count
        return try await req.adminPresenter.createIndexView(usersCount: usersCount, errors: nil, site: req.siteInformation())
    }
    
    func exploreHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getAllUsers().count
        return try await req.adminPresenter.createExploreView(usersCount: usersCount, errors: nil, site: req.siteInformation())
    }
    
    func postsHandler(_ req: Request) async throws -> View {
        var posts: [BlogPost] = []
        if let query = req.url.query {
            if query == "type=draft" {
                posts = try await req.repositories.blogPost.getAllDraftsPostsSortedByPublishDate()
            } else if query == "type=published" {
                posts = try await req.repositories.blogPost.getAllPostsSortedByPublishDate(includeDrafts: false)
            } else if query == "type=scheduled" {
                posts = []
            } else {
                posts = try await req.repositories.blogPost.getAllPostsSortedByPublishDate(includeDrafts: true)
            }
        } else {
            posts = try await req.repositories.blogPost.getAllPostsSortedByPublishDate(includeDrafts: true)
        }
        let usersCount = try await req.repositories.blogUser.getAllUsers().count
        return try await req.adminPresenter.createPostsView(posts: posts, usersCount: usersCount, site: req.siteInformation())
    }
    
    func pagesHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getAllUsers().count
        return try await req.adminPresenter.createPagesView(usersCount: usersCount, errors: nil, site: req.siteInformation())
    }
}
