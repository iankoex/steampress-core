import Vapor

struct PostsAdminController: RouteCollection {

    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("createPost", use: createPostHandler)
        routes.post("createPost", use: createPostPostHandler)
        routes.get("posts", BlogPost.parameter, use: editPostHandler)
//        routes.post("posts", BlogPost.parameter, use: editPostPostHandler)
        routes.post("posts", BlogPost.parameter, "delete", use: deletePostHandler)
    }

    // MARK: - Route handlers
    func createPostHandler(_ req: Request) async throws -> View {
        let tags = try await req.repositories.blogTag.getAllTags()
        return try await req.presenters.admin.createPostView(errors: nil, tags: tags, post: nil, site: req.siteInformation())
    }

    func createPostPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreatePostData.self)
        let author = try req.auth.require(BlogUser.self)

        if let createPostErrors = validatePostCreation(data) {
            let tags = try await req.repositories.blogTag.getAllTags()
            // will result in the loss of data
            let view = try await req.presenters.admin.createPostView(errors: createPostErrors, tags: tags, post: nil, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }

        let uniqueSlug = try await BlogPost.generateUniqueSlugURL(from: data.title, on: req)
        let newPost = BlogPost(
            title: data.title,
            contents: data.contents,
            authorID: author.id ?? UUID(),
            slugUrl: uniqueSlug,
            published: !data.isDraft,
            creationDate: Date()
        )
        guard let tag = try await req.repositories.blogTag.getTag(data.tag) else {
            let tags = try await req.repositories.blogTag.getAllTags()
            var errors = ["Tag not found"]
            // will result in the loss of data
            let view = try await req.presenters.admin.createPostView(errors: errors, tags: tags, post: nil, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        try await req.repositories.blogPost.save(newPost)
        try await req.repositories.blogTag.add(tag, to: newPost)
        
        return req.redirect(to: BlogPathCreator.createPath(for: "streampress/posts"))
    }

    func deletePostHandler(_ req: Request) async throws -> Response {
        let post = try await req.parameters.findPost(on: req)
        try await req.repositories.blogTag.deleteTags(for: post)
        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "streampress/posts"))
        try await req.repositories.blogPost.delete(post)
        return redirect
    }

    func editPostHandler(_ req: Request) async throws -> View {
        let post = try await req.parameters.findPost(on: req)
        let tags = try await req.repositories.blogTag.getAllTags()
        return try await req.presenters.admin.createPostView(errors: nil, tags: tags, post: post, site: req.siteInformation())
    }

//    func editPostPostHandler(_ req: Request) async throws -> Response {
//        let data = try req.content.decode(CreatePostData.self)
//        let post = try await req.parameters.findPost(on: req)
//        if let errors = self.validatePostCreation(data) {
//            return try await req.presenters.admin.createPostView(errors: errors.errors, title: data.title, contents: data.contents, slugURL: post.slugUrl, tags: data.tags, isEditing: true, post: post, isDraft: !post.published, titleError: errors.titleError, contentsError: errors.contentsError, site: req.siteInformation()).encodeResponse(for: req)
//        }
//
//        guard let title = data.title, let contents = data.contents else {
//            throw Abort(.internalServerError)
//        }
//
//        post.title = title
//        post.contents = contents
//
//        let slugURL: String
//        if let updateSlugURL = data.updateSlugURL, updateSlugURL {
//            slugURL = try await BlogPost.generateUniqueSlugURL(from: title, on: req)
//        } else {
//            slugURL = post.slugUrl
//        }
//
//        post.slugUrl = slugURL
//        if post.published {
//            post.lastEdited = Date()
//        } else {
//            post.created = Date()
//            if let publish = data.publish, publish {
//                post.published = true
//            }
//        }
//
//        let existingTags = try await req.repositories.blogTag.getTags(for: post)
//        let allTags = try await req.repositories.blogTag.getAllTags()
//        let tagsToUnlink = existingTags.filter { (anExistingTag) -> Bool in
//            for tagName in data.tags {
//                if anExistingTag.name == tagName {
//                    return false
//                }
//            }
//            return true
//        }
////        var removeTagLinkResults = [EventLoopFuture<Void>]()
//        for tagToUnlink in tagsToUnlink {
//            try await req.repositories.blogTag.remove(tagToUnlink, from: post)
//        }
//
//        let newTagsNames = data.tags.filter { (tagName) -> Bool in
//            !existingTags.contains { (existingTag) -> Bool in
//                existingTag.name == tagName
//            }
//        }
//
//        var tagCreateSaves: [BlogTag] = []
//        for newTagName in newTagsNames {
//            let foundInAllTags = allTags.filter { $0.name == newTagName }.first
//            if let existingTag = foundInAllTags {
//                tagCreateSaves.append(existingTag)
//            } else {
//                let newTag = BlogTag(name: newTagName, visibility: .public)
//                try await req.repositories.blogTag.save(newTag)
//                tagCreateSaves.append(newTag)
//            }
//        }
//        let newTags = tagCreateSaves
//
//        for tag in newTags {
//            try await req.repositories.blogTag.add(tag, to: post)
//        }
//        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "posts/\(post.slugUrl)"))
//        let _ = try await req.repositories.blogPost.save(post)
//        return redirect
//    }

    // MARK: - Validators
    private func validatePostCreation(_ data: CreatePostData) -> [String]? {
        var createPostErrors: [String] = []

        if data.title.isEmptyOrWhitespace() {
            createPostErrors.append("You must specify a blog post title")
        }

        if data.contents.isEmptyOrWhitespace() {
            createPostErrors.append("You must have some content in your blog post")
        }

        if createPostErrors.count == 0 {
            return nil
        }
        return createPostErrors
    }
}
