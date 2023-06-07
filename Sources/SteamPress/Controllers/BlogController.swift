import Vapor

struct BlogController: RouteCollection {

    // MARK: - Properties
    fileprivate let blogPostsPath = PathComponent(stringLiteral: "posts")
    fileprivate let tagsPath = PathComponent(stringLiteral: "tags")
    fileprivate let authorsPath = PathComponent(stringLiteral: "authors")
    fileprivate let apiPath = PathComponent(stringLiteral: "api")
    fileprivate let searchPath = PathComponent(stringLiteral: "search")
    fileprivate let pathCreator: BlogPathCreator
    fileprivate let enableAuthorPages: Bool
    fileprivate let enableTagsPages: Bool
    fileprivate let postsPerPage: Int

    // MARK: - Initialiser
    init(pathCreator: BlogPathCreator, enableAuthorPages: Bool, enableTagPages: Bool, postsPerPage: Int) {
        self.pathCreator = pathCreator
        self.enableAuthorPages = enableAuthorPages
        self.enableTagsPages = enableTagPages
        self.postsPerPage = postsPerPage
    }

    // MARK: - Add routes
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
        routes.get(blogPostsPath, ":blogSlug", use: blogPostHandler)
        routes.get(blogPostsPath, use: blogPostIndexRedirectHandler)
        routes.get(searchPath, use: searchHandler)
        if enableAuthorPages {
            routes.get(authorsPath, use: allAuthorsViewHandler)
            routes.get(authorsPath, ":authorUsername", use: authorViewHandler)
        }
        if enableTagsPages {
            routes.get(tagsPath, BlogTag.parameter, use: tagViewHandler)
            routes.get(tagsPath, use: allTagsViewHandler)
        }
    }

    // MARK: - Route Handlers

    func indexHandler(_ req: Request) async throws -> View {
        let paginationInformation = req.getPaginationInformation(postsPerPage: postsPerPage)
        
        let posts = try await req.repositories.blogPost.getAllPostsSortedByPublishDate(includeDrafts: false, count: postsPerPage, offset: paginationInformation.offset)
        let tags = try await req.repositories.blogTag.getAllTags()
        let users = try await req.repositories.blogUser.getAllUsers().convertToPublic()
        let totalPostCount = try await req.repositories.blogPost.getAllPostsCount(includeDrafts: false)
        let tagsForPosts = try await req.repositories.blogTag.getTagsForAllPosts()
        return try await req.blogPresenter.indexView(posts: posts, tags: tags, authors: users, tagsForPosts: tagsForPosts, pageInformation: try req.pageInformation(), paginationTagInfo: self.getPaginationInformation(currentPage: paginationInformation.page, totalPosts: totalPostCount, currentQuery: req.url.query))
    }

    func blogPostIndexRedirectHandler(_ req: Request) async throws -> Response {
        return req.redirect(to: pathCreator.createPath(for: pathCreator.blogPath), redirectType: .permanent)
    }

    func blogPostHandler(_ req: Request) async throws -> View {
        guard let blogSlug: String = req.parameters.get("blogSlug") else {
            throw Abort(.badRequest)
        }
        guard let post = try await req.repositories.blogPost.getPost(slug: blogSlug) else {
            throw Abort(.notFound)
        }
        let tags: [BlogTag] = try await req.repositories.blogTag.getTags(for: post)
        guard let user = try await req.repositories.blogUser.getUser(id: post.$author.id) else {
            throw Abort(.internalServerError)
        }
        let pageInformation: BlogGlobalPageInformation = try req.pageInformation()
        return try await req.blogPresenter.postView(post: post, author: user.convertToPublic(), tags: tags, pageInformation: pageInformation)
    }

    func tagViewHandler(_ req: Request) async throws -> View {
        let tag = try await req.parameters.findTag(on: req)
        let paginationInformation = req.getPaginationInformation(postsPerPage: self.postsPerPage)
        let posts = try await req.repositories.blogPost.getSortedPublishedPosts(for: tag, count: self.postsPerPage, offset: paginationInformation.offset)
        let totalPosts = try await req.repositories.blogPost.getPublishedPostCount(for: tag)
        let authors = try await req.repositories.blogUser.getAllUsers().convertToPublic()
        let paginationTagInfo = self.getPaginationInformation(currentPage: paginationInformation.page, totalPosts: totalPosts, currentQuery: req.url.query)
        return try await req.blogPresenter.tagView(tag: tag, posts: posts, authors: authors, totalPosts: totalPosts, pageInformation: try req.pageInformation(), paginationTagInfo: paginationTagInfo)
    }

    func authorViewHandler(_ req: Request) async throws -> View {
        guard let authorUsername = req.parameters.get("authorUsername") else {
            throw Abort(.badRequest)
        }
        let paginationInformation = req.getPaginationInformation(postsPerPage: postsPerPage)
        guard let author = try await req.repositories.blogUser.getUser(username: authorUsername) else {
            throw Abort(.notFound)
        }
        let posts = try await req.repositories.blogPost.getAllPostsSortedByPublishDate(for: author, includeDrafts: false, count: self.postsPerPage, offset: paginationInformation.offset)
        let tagsForPosts = try await req.repositories.blogTag.getTagsForAllPosts()
        let postCount = try await req.repositories.blogPost.getPostCount(for: author)
        let paginationTagInfo = self.getPaginationInformation(currentPage: paginationInformation.page, totalPosts: postCount, currentQuery: req.url.query)
        return try await req.blogPresenter.authorView(author: author.convertToPublic(), posts: posts, postCount: postCount, tagsForPosts: tagsForPosts, pageInformation: try req.pageInformation(), paginationTagInfo: paginationTagInfo)
    }

    func allTagsViewHandler(_ req: Request) async throws -> View {
        let tagswithCount = try await req.repositories.blogTag.getAllTagsWithPostCount()
        let allTags = tagswithCount.map { $0.0 }
        let tagCounts = try tagswithCount.reduce(into: [UUID: Int]()) {
            guard let tagID = $1.0.id else {
                throw SteamPressError(identifier: "BlogController", "Tag ID not set")
            }
            return $0[tagID] = $1.1
        }
        return try await req.blogPresenter.allTagsView(tags: allTags, tagPostCounts: tagCounts, pageInformation: try req.pageInformation())
    }

    func allAuthorsViewHandler(_ req: Request) async throws -> View {
        let allUsersWithCount = try await req.repositories.blogUser.getAllUsersWithPostCount()
        let allUsers = allUsersWithCount.map { $0.0 }
        let authorCounts = try allUsersWithCount.reduce(into: [UUID: Int]()) {
            guard let userID = $1.0.id else {
                throw SteamPressError(identifier: "BlogController", "User ID not set")
            }
            return $0[userID] = $1.1
        }
        return try await req.blogPresenter.allAuthorsView(authors: allUsers.convertToPublic(), authorPostCounts: authorCounts, pageInformation: try req.pageInformation())
    }

    func searchHandler(_ req: Request) async throws -> View {
        let paginationInformation = req.getPaginationInformation(postsPerPage: postsPerPage)
        guard let searchTerm = req.query[String.self, at: "term"], !searchTerm.isEmpty else {
            let paginationTagInfo = getPaginationInformation(currentPage: paginationInformation.page, totalPosts: 0, currentQuery: req.url.query)
            return try await req.blogPresenter.searchView(totalResults: 0, posts: [], authors: [], searchTerm: nil, tagsForPosts: [:], pageInformation: try req.pageInformation(), paginationTagInfo: paginationTagInfo)
        }

        let totalPosts = try await req.repositories.blogPost.getPublishedPostCount(for: searchTerm)
        let posts = try await req.repositories.blogPost.findPublishedPostsOrdered(for: searchTerm, count: self.postsPerPage, offset: paginationInformation.offset)
        let tagsForPosts = try await req.repositories.blogTag.getTagsForAllPosts()
        let users = try await req.repositories.blogUser.getAllUsers().convertToPublic()
        
        let paginationTagInfo = self.getPaginationInformation(currentPage: paginationInformation.page, totalPosts: totalPosts, currentQuery: req.url.query)
        return try await req.blogPresenter.searchView(totalResults: totalPosts, posts: posts, authors: users, searchTerm: searchTerm, tagsForPosts: tagsForPosts, pageInformation: try req.pageInformation(), paginationTagInfo: paginationTagInfo)
    }
    
    func getPaginationInformation(currentPage: Int, totalPosts: Int, currentQuery: String?) -> PaginationTagInformation {
        let totalPages = Int(ceil(Double(totalPosts) / Double(postsPerPage)))
        return PaginationTagInformation(currentPage: currentPage, totalPages: totalPages, currentQuery: currentQuery)
    }

}
