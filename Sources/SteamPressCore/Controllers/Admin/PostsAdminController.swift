import Vapor

struct PostsAdminController: RouteCollection {

    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("createPost", use: createPostHandler)
        routes.post("createPost", use: createPostPostHandler)
        routes.get("posts", BlogPost.parameter, "edit", use: editPostHandler)
        routes.post("posts", BlogPost.parameter, "edit", use: editPostPostHandler)
        routes.post("posts", BlogPost.parameter, "delete", use: deletePostHandler)
    }

    // MARK: - Route handlers
    func createPostHandler(_ req: Request) async throws -> View {
        return try await req.presenters.admin.createPostView(errors: nil, title: nil, contents: nil, slugURL: nil, tags: [], isEditing: false, post: nil, isDraft: nil, titleError: false, contentsError: false, site: req.siteInformation())
    }

    func createPostPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreatePostData.self)
        let author = try req.auth.require(BlogUser.self)

        if data.draft == nil && data.publish == nil {
            throw Abort(.badRequest)
        }

        if let createPostErrors = validatePostCreation(data) {
            let view = try await req.presenters.admin.createPostView(errors: createPostErrors.errors, title: data.title, contents: data.contents, slugURL: nil, tags: data.tags, isEditing: false, post: nil, isDraft: nil, titleError: createPostErrors.titleError, contentsError: createPostErrors.contentsError, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }

        guard let title = data.title, let contents = data.contents else {
            throw Abort(.internalServerError)
        }

        let uniqueSlug = try await BlogPost.generateUniqueSlugURL(from: title, on: req)
        let newPost: BlogPost
        newPost = try BlogPost(title: title, contents: contents, author: author, slugUrl: uniqueSlug, published: data.publish != nil, featureImage: "", featureImageCaption: "", creationDate: Date())
        
        try await req.repositories.blogPost.save(newPost)
        
        var existingTags: [BlogTag] = []
        for tagName in data.tags {
            if let tag = try await req.repositories.blogTag.getTag(tagName) {
                existingTags.append(tag)
            }
        }
        
        var tagsSaves: [BlogTag] = []
        for tagName in data.tags {
            if !existingTags.contains(where: { $0.name == tagName }) {
                let tag = BlogTag(name: tagName, visibility: .public)
                try await req.repositories.blogTag.save(tag)
                tagsSaves.append(tag)
            }
        }
        
        for tag in tagsSaves {
            try await req.repositories.blogTag.add(tag, to: newPost)
        }
        for tag in existingTags {
            try await req.repositories.blogTag.add(tag, to: newPost)
        }
        return req.redirect(to: BlogPathCreator.createPath(for: "posts/\(newPost.slugUrl)"))
    }

    func deletePostHandler(_ req: Request) async throws -> Response {
        let post = try await req.parameters.findPost(on: req)
        try await req.repositories.blogTag.deleteTags(for: post)
        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "admin"))
        try await req.repositories.blogPost.delete(post)
        return redirect
    }

    func editPostHandler(_ req: Request) async throws -> View {
        let post = try await req.parameters.findPost(on: req)
        let tags = try await req.repositories.blogTag.getTags(for: post)
        return try await req.presenters.admin.createPostView(errors: nil, title: post.title, contents: post.contents, slugURL: post.slugUrl, tags: tags.map { $0.name }, isEditing: true, post: post, isDraft: !post.published, titleError: false, contentsError: false, site: req.siteInformation())
    }

    func editPostPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreatePostData.self)
        let post = try await req.parameters.findPost(on: req)
        if let errors = self.validatePostCreation(data) {
            return try await req.presenters.admin.createPostView(errors: errors.errors, title: data.title, contents: data.contents, slugURL: post.slugUrl, tags: data.tags, isEditing: true, post: post, isDraft: !post.published, titleError: errors.titleError, contentsError: errors.contentsError, site: req.siteInformation()).encodeResponse(for: req)
        }
        
        guard let title = data.title, let contents = data.contents else {
            throw Abort(.internalServerError)
        }
        
        post.title = title
        post.contents = contents
        
        let slugURL: String
        if let updateSlugURL = data.updateSlugURL, updateSlugURL {
            slugURL = try await BlogPost.generateUniqueSlugURL(from: title, on: req)
        } else {
            slugURL = post.slugUrl
        }
        
        post.slugUrl = slugURL
        if post.published {
            post.lastEdited = Date()
        } else {
            post.created = Date()
            if let publish = data.publish, publish {
                post.published = true
            }
        }
        
        let existingTags = try await req.repositories.blogTag.getTags(for: post)
        let allTags = try await req.repositories.blogTag.getAllTags()
        let tagsToUnlink = existingTags.filter { (anExistingTag) -> Bool in
            for tagName in data.tags {
                if anExistingTag.name == tagName {
                    return false
                }
            }
            return true
        }
//        var removeTagLinkResults = [EventLoopFuture<Void>]()
        for tagToUnlink in tagsToUnlink {
            try await req.repositories.blogTag.remove(tagToUnlink, from: post)
        }
        
        let newTagsNames = data.tags.filter { (tagName) -> Bool in
            !existingTags.contains { (existingTag) -> Bool in
                existingTag.name == tagName
            }
        }
        
        var tagCreateSaves: [BlogTag] = []
        for newTagName in newTagsNames {
            let foundInAllTags = allTags.filter { $0.name == newTagName }.first
            if let existingTag = foundInAllTags {
                tagCreateSaves.append(existingTag)
            } else {
                let newTag = BlogTag(name: newTagName, visibility: .public)
                try await req.repositories.blogTag.save(newTag)
                tagCreateSaves.append(newTag)
            }
        }
        let newTags = tagCreateSaves
        
        for tag in newTags {
            try await req.repositories.blogTag.add(tag, to: post)
        }
        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "posts/\(post.slugUrl)"))
        let _ = try await req.repositories.blogPost.save(post)
        return redirect
    }

    // MARK: - Validators
    private func validatePostCreation(_ data: CreatePostData) -> CreatePostErrors? {
        var createPostErrors = [String]()
        var titleError = false
        var contentsError = false

        if data.title.isEmptyOrWhitespace() {
            createPostErrors.append("You must specify a blog post title")
            titleError = true
        }

        if data.contents.isEmptyOrWhitespace() {
            createPostErrors.append("You must have some content in your blog post")
            contentsError = true
        }

        if createPostErrors.count == 0 {
            return nil
        }

        return CreatePostErrors(errors: createPostErrors, titleError: titleError, contentsError: contentsError)
    }

}
