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
        adminProtectedRoutes.get("tags", use: tagsHandler)
        adminProtectedRoutes.get("tags", "new", use: createTagHandler)
        adminProtectedRoutes.post("tags", "new", use: createNewTagHandler)
        adminProtectedRoutes.get("tags", BlogTag.parameter, use: tagHandler)
        adminProtectedRoutes.post("tags", BlogTag.parameter, use: updateTagHandler)
        adminProtectedRoutes.get("tags", BlogTag.parameter, "delete", use: deleteTagHandler)

        let loginController = LoginController()
        try adminRoutes.register(collection: loginController)
        let postController = PostAdminController()
        try adminProtectedRoutes.register(collection: postController)
        let userController = UserAdminController()
        try adminProtectedRoutes.register(collection: userController)
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
    
    func tagsHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        let tags = try await req.repositories.blogTag.getAllTags()
        return try await req.presenters.admin.createTagsView(tags: tags, usersCount: usersCount, site: req.siteInformation())
    }
    
    func createTagHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createCreateTagView(usersCount: usersCount, site: req.siteInformation())
    }
    
    func createNewTagHandler(_ req: Request) async throws -> View {
        let data = try req.content.decode(CreateTagData.self)
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        guard !data.name.isEmpty else {
            let tags = try await req.repositories.blogTag.getAllTags()
            return try await req.presenters.admin.createTagsView(tags: tags, usersCount: usersCount, site: req.siteInformation())
        }
        var tag = BlogTag(name: data.name, visibility: .public)
        if data.name.contains(where: { $0 == "#" }) {
            tag.visibility = .private
        }
        tag.name = data.name.replacingOccurrences(of: "#", with: "")
        try await req.repositories.blogTag.save(tag)
        let tags = try await req.repositories.blogTag.getAllTags()
        return try await req.presenters.admin.createTagsView(tags: tags, usersCount: usersCount, site: req.siteInformation())
    }
    
    func tagHandler(_ req: Request) async throws -> View {
        let tag = try await req.parameters.findTag(on: req)
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createEditTagView(tag: tag, usersCount: usersCount, site: req.siteInformation())
    }
    
    func updateTagHandler(_ req: Request) async throws -> View {
        let tag = try await req.parameters.findTag(on: req)
        let data = try req.content.decode(CreateTagData.self)
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        guard !data.name.isEmpty else {
            let tags = try await req.repositories.blogTag.getAllTags()
            return try await req.presenters.admin.createTagsView(tags: tags, usersCount: usersCount, site: req.siteInformation())
        }
        if data.name.contains(where: { $0 == "#" }) {
            tag.visibility = .private
        }
        tag.name = data.name.replacingOccurrences(of: "#", with: "")
        try await req.repositories.blogTag.update(tag)
        let tags = try await req.repositories.blogTag.getAllTags()
        return try await req.presenters.admin.createTagsView(tags: tags, usersCount: usersCount, site: req.siteInformation())
    }
    
    func deleteTagHandler(_ req: Request) async throws -> Response {
        let tag = try await req.parameters.findTag(on: req)
        try await req.repositories.blogTag.delete(tag)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress/tags"))
    }
}
