import Vapor

struct BlogAdminController: RouteCollection {

    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        let adminRoutes = routes.grouped("steampress")
        
        adminRoutes.post("createOwner", use: createOwnerPostHandler)

        let redirectMiddleware = BlogLoginRedirectAuthMiddleware()
        let adminProtectedRoutes = adminRoutes.grouped(redirectMiddleware)
        adminProtectedRoutes.get(use: adminHandler)
        adminProtectedRoutes.get("explore", use: exploreHandler)
        adminProtectedRoutes.get("posts", use: postsHandler)
        adminProtectedRoutes.get("pages", use: pagesHandler)
        
        let loginController = LoginController()
        try adminRoutes.register(collection: loginController)
        let postsController = PostsAdminController()
        try adminProtectedRoutes.register(collection: postsController)
        let usersController = UsersAdminController()
        try adminProtectedRoutes.register(collection: usersController)
        let tagsController = TagsAdminController()
        try adminProtectedRoutes.register(collection: tagsController)
    }
    
    func createOwnerPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreateOwnerData.self)
        guard !data.name.isEmpty, !data.password.isEmpty, !data.email.isEmpty else {
            throw Abort(.custom(code: 500, reasonPhrase: "name password or email cannot be empty"))
        }
        let hashedPassword = try await req.password.async.hash(data.password)
        let username = data.name.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces)
        print(username)
        let owner = BlogUser(
            name: data.name,
            username: username,
            email: data.email,
            password: hashedPassword,
            type: .owner,
            profilePicture: nil,
            twitterHandle: nil,
            biography: nil,
            tagline: nil
        )
        try await req.repositories.blogUser.save(owner)
        owner.authenticateSession(on: req)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress"))
    }

    // MARK: Admin Handler
    func adminHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createIndexView(usersCount: usersCount, errors: nil, site: req.siteInformation())
    }
    
    func exploreHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createExploreView(usersCount: usersCount, errors: nil, site: req.siteInformation())
    }
    
    func postsHandler(_ req: Request) async throws -> View {
        var posts: [BlogPost] = []
        let queryType = try? req.query.get(String.self, at: "type")
        if queryType == "draft" {
            posts = try await req.repositories.blogPost.getAllDraftsPostsSortedByPublishDate()
        } else if queryType == "published" {
            posts = try await req.repositories.blogPost.getAllPostsSortedByPublishDate(includeDrafts: false)
        } else if queryType == "scheduled" {
            posts = []
        } else {
            posts = try await req.repositories.blogPost.getAllPostsSortedByPublishDate(includeDrafts: true)
        }
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createPostsView(posts: posts, usersCount: usersCount, site: req.siteInformation())
    }
    
    func pagesHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createPagesView(usersCount: usersCount, errors: nil, site: req.siteInformation())
    }
}
