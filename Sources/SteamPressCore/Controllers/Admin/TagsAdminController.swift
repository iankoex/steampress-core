import Vapor

struct TagsAdminController: RouteCollection {
    
    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("tags", use: tagsHandler)
        routes.get("tags", "new", use: createTagHandler)
        routes.post("tags", "new", use: createNewTagHandler)
        routes.get("tags", BlogTag.parameter, use: tagHandler)
        routes.post("tags", BlogTag.parameter, use: updateTagHandler)
        routes.get("tags", BlogTag.parameter, "delete", use: deleteTagHandler)
    }
    
    // MARK: - Route handlers
    
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
