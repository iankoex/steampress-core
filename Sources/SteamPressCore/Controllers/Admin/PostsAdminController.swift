import Vapor

struct PostsAdminController: RouteCollection {
    
    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("posts", use: postsHandler)
        routes.get("posts", "new", use: createPostHandler)
        routes.post("posts", "new", use: createPostPostHandler)
        routes.get("posts", BlogPost.parameter, use: editPostHandler)
        routes.post("posts", BlogPost.parameter, use: editPostPostHandler)
        routes.get("posts", BlogPost.parameter, "delete", use: deletePostHandler)
    }
    
    // MARK: - Route handlers
    
    func postsHandler(_ req: Request) async throws -> View {
        var posts: [BlogPost] = []
        let queryType = try? req.query.get(String.self, at: "type")
        if queryType == "draft" {
            posts = try await req.repositories.blogPost.getAllDraftsPosts()
        } else if queryType == "published" {
            posts = try await req.repositories.blogPost.getAllPosts(includeDrafts: false)
        } else if queryType == "scheduled" {
            posts = []
        } else {
            posts = try await req.repositories.blogPost.getAllPosts(includeDrafts: true)
        }
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createPostsView(posts: posts, usersCount: usersCount, site: req.siteInformation())
    }
    
    func createPostHandler(_ req: Request) async throws -> View {
        let tags = try await req.repositories.blogTag.getAllTags()
        return try await req.presenters.admin.createPostView(errors: nil, tags: tags, post: nil, titleSupplied: nil, contentSupplied: nil, snippetSupplied: nil, site: req.siteInformation())
    }
    
    func createPostPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreatePostData.self)
        let author = try req.auth.require(BlogUser.self)
        
        if let createPostErrors = validatePostCreation(data) {
            let tags = try await req.repositories.blogTag.getAllTags()
            let view = try await req.presenters.admin.createPostView(errors: createPostErrors, tags: tags, post: nil, titleSupplied: data.title, contentSupplied: data.contents, snippetSupplied: data.snippet, site: req.siteInformation())
            return try await view.encodeResponse(for: req)
        }
        
        let newPost = try await data.createBlogPost(with: author.id, on: req)
        var postTags: [BlogTag]  = []
        for tagStr in data.tags {
            guard let tag = try await req.repositories.blogTag.getTag(tagStr) else {
                let tags = try await req.repositories.blogTag.getAllTags()
                let errors = ["Tag not found"]
                let view = try await req.presenters.admin.createPostView(errors: errors, tags: tags, post: nil, titleSupplied: data.title, contentSupplied: data.contents, snippetSupplied: data.snippet, site: req.siteInformation())
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
        try await req.repositories.blogPost.delete(post)
        return req.redirect(to: BlogPathCreator.createPath(for: "steampress/posts"))
    }
    
    func editPostHandler(_ req: Request) async throws -> View {
        let post = try await req.parameters.findPost(on: req)
        let tags = try await req.repositories.blogTag.getAllTags()
        return try await req.presenters.admin.createPostView(errors: nil, tags: tags, post: post, titleSupplied: post.title, contentSupplied: post.contents, snippetSupplied: post.snippet, site: req.siteInformation())
    }
    
    func editPostPostHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreatePostData.self)
        let post = try await req.parameters.findPost(on: req)
        if let errors = self.validatePostCreation(data) {
            let tags = try await req.repositories.blogTag.getAllTags()
            return try await req.presenters.admin.createPostView(errors: errors, tags: tags, post: post, titleSupplied: post.title, contentSupplied: post.contents, snippetSupplied: post.snippet, site: req.siteInformation()).encodeResponse(for: req)
        }
        
        post.title = data.title
        post.contents = data.contents
        post.snippet = data.snippet
        
        let slugURL: String
        if let updateSlugURL = data.updateSlugURL, updateSlugURL {
            slugURL = try await BlogPost.generateUniqueSlugURL(from: data.title, on: req)
        } else {
            slugURL = post.slugURL
        }
        post.slugURL = slugURL
        
        post.published = !data.isDraft
        if post.published {
            post.lastEdited = Date()
        } else {
            post.created = Date()
        }
        
        var newTags: [BlogTag]  = []
        for tagStr in data.tags {
            guard let tag = try await req.repositories.blogTag.getTag(tagStr) else {
                let tags = try await req.repositories.blogTag.getAllTags()
                let errors = ["Tag not found"]
                let view = try await req.presenters.admin.createPostView(errors: errors, tags: tags, post: nil, titleSupplied: data.title, contentSupplied: data.contents, snippetSupplied: data.snippet, site: req.siteInformation())
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
