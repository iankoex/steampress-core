import Vapor

struct PostsAdminController: RouteCollection {

    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("createPost", use: createPostHandler)
        routes.post("createPost", use: createPostPostHandler)
        routes.get("posts", BlogPost.parameter, use: editPostHandler)
        routes.post("posts", BlogPost.parameter, use: editPostPostHandler)
        routes.post("posts", BlogPost.parameter, "delete", use: deletePostHandler)
    }

    // MARK: - Route handlers
    func createPostHandler(_ req: Request) async throws -> View {
        let tags = try await req.repositories.blogTag.getAllTags()
        return try await req.presenters.admin.createPostView(errors: nil, tags: tags, post: nil, titleSupplied: nil, contentSupplied: nil, excerptSupplied: nil, site: req.siteInformation())
    }

    func createPostPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreatePostData.self)
        let author = try req.auth.require(BlogUser.self)

        if let createPostErrors = validatePostCreation(data) {
            let tags = try await req.repositories.blogTag.getAllTags()
            let view = try await req.presenters.admin.createPostView(errors: createPostErrors, tags: tags, post: nil, titleSupplied: data.title, contentSupplied: data.contents, excerptSupplied: data.excerpt, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        let newPost = try await data.createBlogPost(with: author.id, on: req)
        var postTags: [BlogTag]  = []
        for tagStr in data.tags {
            guard let tag = try await req.repositories.blogTag.getTag(tagStr) else {
                let tags = try await req.repositories.blogTag.getAllTags()
                var errors = ["Tag not found"]
                let view = try await req.presenters.admin.createPostView(errors: errors, tags: tags, post: nil, titleSupplied: data.title, contentSupplied: data.contents, excerptSupplied: data.excerpt, site: req.siteInformation())
                return try await view.encodeResponse(for: req)
            }
            postTags.append(tag)
        }
       
        
        try await req.repositories.blogPost.save(newPost)
        for tag in postTags {
            try await req.repositories.blogTag.add(tag, to: newPost)
        }
        
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress/posts"))
    }

    func deletePostHandler(_ req: Request) async throws -> Response {
        let post = try await req.parameters.findPost(on: req)
        try await req.repositories.blogTag.deleteTags(for: post)
        let redirect = req.redirect(to: BlogPathCreator.createPath(for: "steampress/posts"))
        try await req.repositories.blogPost.delete(post)
        return redirect
    }

    func editPostHandler(_ req: Request) async throws -> View {
        let post = try await req.parameters.findPost(on: req)
        let tags = try await req.repositories.blogTag.getAllTags()
        return try await req.presenters.admin.createPostView(errors: nil, tags: tags, post: post, titleSupplied: post.title, contentSupplied: post.contents, excerptSupplied: post.snippet, site: req.siteInformation())
    }

    func editPostPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreatePostData.self)
        let post = try await req.parameters.findPost(on: req)
        if let errors = self.validatePostCreation(data) {
            let tags = try await req.repositories.blogTag.getAllTags()
            return try await req.presenters.admin.createPostView(errors: errors, tags: tags, post: post, titleSupplied: post.title, contentSupplied: post.contents, excerptSupplied: post.snippet, site: req.siteInformation()).encodeResponse(for: req)
        }

        post.title = data.title
        post.contents = data.contents

        let slugURL: String
        if let updateSlugURL = data.updateSlugURL, updateSlugURL {
            slugURL = try await BlogPost.generateUniqueSlugURL(from: data.title, on: req)
        } else {
            slugURL = post.slugURL
        }
        post.slugURL = slugURL
        
        if post.published {
            post.lastEdited = Date()
        } else {
            post.created = Date()
            post.published = !data.isDraft
        }

        var newTags: [BlogTag]  = []
        for tagStr in data.tags {
            guard let tag = try await req.repositories.blogTag.getTag(tagStr) else {
                let tags = try await req.repositories.blogTag.getAllTags()
                var errors = ["Tag not found"]
                let view = try await req.presenters.admin.createPostView(errors: errors, tags: tags, post: nil, titleSupplied: data.title, contentSupplied: data.contents, excerptSupplied: data.excerpt, site: req.siteInformation())
                return try await view.encodeResponse(for: req)
            }
            newTags.append(tag)
        }
        
        for tag in post.tags {
            if newTags.contains(where: { $0.name == tag.name }) {
                newTags.removeAll(where: { $0.name == tag.name })
            } else {
                try await req.repositories.blogTag.remove(tag, from: post)
            }
        }
        
        for tag in newTags {
            try await req.repositories.blogTag.add(tag, to: post)
        }
        
        try await req.repositories.blogPost.save(post)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress/posts"))
    }

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
