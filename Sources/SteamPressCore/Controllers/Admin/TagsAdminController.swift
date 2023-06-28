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
        return try await req.presenters.admin.createTagView(errors: nil, tag: nil, usersCount: usersCount, site: req.siteInformation())
    }
    
    func createNewTagHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreateTagData.self)
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        guard !data.name.isEmptyOrWhitespace() else {
            let errors = ["You must specify a tag name"]
            return try await req.presenters.admin.createTagView(errors: errors, tag: nil, usersCount: usersCount, site: req.siteInformation()).encodeResponse(for: req)
        }
        let existingTag = try await req.repositories.blogTag.getTag(data.name)
        guard existingTag == nil else {
            let errors = ["Sorry that tag name already exists"]
            return try await req.presenters.admin.createTagView(errors: errors, tag: nil, usersCount: usersCount, site: req.siteInformation()).encodeResponse(for: req)
        }
        let slug = BlogTag.generateUniqueSlugURL(from: data.name)
        let tag = BlogTag(name: data.name, visibility: data.visibility, slugURL: slug)
        try await req.repositories.blogTag.save(tag)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress/tags"))
    }
    
    func tagHandler(_ req: Request) async throws -> View {
        let tag = try await req.parameters.findTag(on: req)
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createTagView(errors: nil, tag: tag, usersCount: usersCount, site: req.siteInformation())
    }
    
    func updateTagHandler(_ req: Request) async throws -> Response {
        let tag = try await req.parameters.findTag(on: req)
        let data = try req.content.decode(CreateTagData.self)
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        guard !data.name.isEmptyOrWhitespace() else {
            let errors = ["You must specify a tag name"]
            return try await req.presenters.admin.createTagView(errors: errors, tag: tag, usersCount: usersCount, site: req.siteInformation()).encodeResponse(for: req)
        }
        let existingTag = try await req.repositories.blogTag.getTag(data.name)
        if let existingTag = existingTag, existingTag.name != tag.name {
            let errors = ["Sorry that tag name already exists"]
            return try await req.presenters.admin.createTagView(errors: errors, tag: tag, usersCount: usersCount, site: req.siteInformation()).encodeResponse(for: req)
        }
        tag.name = data.name
        tag.visibility = data.visibility
        try await req.repositories.blogTag.update(tag)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress/tags"))
    }
    
    func deleteTagHandler(_ req: Request) async throws -> Response {
        let tag = try await req.parameters.findTag(on: req)
        try await req.repositories.blogTag.delete(tag)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress/tags"))
    }
}
