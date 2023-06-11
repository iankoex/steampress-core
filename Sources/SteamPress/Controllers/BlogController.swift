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
        routes.post("uploadImages", use: uploadImagesHandler)
    }

    // MARK: - Route Handlers

    func indexHandler(_ req: Request) async throws -> View {
        let paginationInformation = req.getPaginationInformation(postsPerPage: postsPerPage)
        
        let posts = try await req.repositories.blogPost.getAllPostsSortedByPublishDate(includeDrafts: false, count: postsPerPage, offset: paginationInformation.offset)
        let totalPostCount = try await req.repositories.blogPost.getAllPostsCount(includeDrafts: false)
        return try await req.presenters.blog.indexView(posts: posts, site: try req.siteInformation(), paginationTagInfo: self.getPaginationInformation(currentPage: paginationInformation.page, totalPosts: totalPostCount, currentQuery: req.url.query))
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
        let site: GlobalWebsiteInformation = try req.siteInformation()
        return try await req.presenters.blog.postView(post: post, site: site)
    }

    func tagViewHandler(_ req: Request) async throws -> View {
        let tag = try await req.parameters.findTag(on: req)
        let paginationInformation = req.getPaginationInformation(postsPerPage: self.postsPerPage)
        let posts = try await req.repositories.blogPost.getSortedPublishedPosts(for: tag, count: self.postsPerPage, offset: paginationInformation.offset)
        let totalPosts = try await req.repositories.blogPost.getPublishedPostCount(for: tag)
        let authors = try await req.repositories.blogUser.getAllUsers().convertToPublic()
        let paginationTagInfo = self.getPaginationInformation(currentPage: paginationInformation.page, totalPosts: totalPosts, currentQuery: req.url.query)
        return try await req.presenters.blog.tagView(tag: tag, posts: posts, authors: authors, totalPosts: totalPosts, site: try req.siteInformation(), paginationTagInfo: paginationTagInfo)
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
        let postCount = try await req.repositories.blogPost.getPostCount(for: author)
        let paginationTagInfo = self.getPaginationInformation(currentPage: paginationInformation.page, totalPosts: postCount, currentQuery: req.url.query)
        return try await req.presenters.blog.authorView(author: author.convertToPublic(), posts: posts, postCount: postCount, site: try req.siteInformation(), paginationTagInfo: paginationTagInfo)
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
        return try await req.presenters.blog.allTagsView(tags: allTags, tagPostCounts: tagCounts, site: try req.siteInformation())
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
        return try await req.presenters.blog.allAuthorsView(authors: allUsers.convertToPublic(), authorPostCounts: authorCounts, site: try req.siteInformation())
    }

    func searchHandler(_ req: Request) async throws -> View {
        let paginationInformation = req.getPaginationInformation(postsPerPage: postsPerPage)
        guard let searchTerm = req.query[String.self, at: "term"], !searchTerm.isEmpty else {
            let paginationTagInfo = getPaginationInformation(currentPage: paginationInformation.page, totalPosts: 0, currentQuery: req.url.query)
            return try await req.presenters.blog.searchView(totalResults: 0, posts: [], authors: [], tags: [], searchTerm: nil, site: try req.siteInformation(), paginationTagInfo: paginationTagInfo)
        }

        let totalPosts = try await req.repositories.blogPost.getPublishedPostCount(for: searchTerm)
        let posts = try await req.repositories.blogPost.findPublishedPostsOrdered(for: searchTerm, count: self.postsPerPage, offset: paginationInformation.offset)
        let tags = try await req.repositories.blogTag.getAllTags()
        let users = try await req.repositories.blogUser.getAllUsers().convertToPublic()
        
        let paginationTagInfo = self.getPaginationInformation(currentPage: paginationInformation.page, totalPosts: totalPosts, currentQuery: req.url.query)
        return try await req.presenters.blog.searchView(totalResults: totalPosts, posts: posts, authors: users, tags: tags, searchTerm: searchTerm, site: try req.siteInformation(), paginationTagInfo: paginationTagInfo)
    }
    
    func getPaginationInformation(currentPage: Int, totalPosts: Int, currentQuery: String?) -> PaginationTagInformation {
        let totalPages = Int(ceil(Double(totalPosts) / Double(postsPerPage)))
        return PaginationTagInformation(currentPage: currentPage, totalPages: totalPages, currentQuery: currentQuery)
    }

    func uploadImagesHandler(_ req: Request) async throws -> String {
        print("began")
        
        let fileName = "upload-\(UUID().uuidString).\(req.content.contentType?.subType ?? "kkjj")"
        let upload = StreamModel(fileName: fileName)
        let filePath = upload.filePath(for: req.application)
        
        // Remove any file with the same name
        try? FileManager.default.removeItem(atPath: filePath)
        print("uploading \(upload.fileName) to \(filePath)")
        let handle = try await req.application.fileio.openFile(
            path: filePath,
            mode: .write,
            flags: .allowFileCreation(posixMode: 0x744),
            eventLoop: req.eventLoop
        ).get()
        defer {
            do {
                try handle.close()
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        do {
            var offset: Int64 = 0
            for try await byteBuffer in req.body {
                do {
                    try await req.application.fileio.write(
                        fileHandle: handle,
                        toOffset: offset,
                        buffer: byteBuffer,
                        eventLoop: req.eventLoop
                    ).get()
                    offset += Int64(byteBuffer.readableBytes)
                } catch {
                    print("\(error.localizedDescription)")
                }
            }
            print(offset)
        } catch {
            try FileManager.default.removeItem(atPath: filePath)
            print("File save failed for \(filePath)")
            throw Abort(.internalServerError)
        }
        print("saved \(upload)")
        return "Saved \(upload)"
        
//        struct Input: Content {
//            var file: File
//        }
//        let input = try req.content.decode(Input.self)
//
//        guard input.file.data.readableBytes > 0 else {
//            throw Abort(.badRequest)
//        }
//
//        let formatter = DateFormatter()
//        formatter.dateFormat = "y-m-d-HH-MM-SS-"
//        let prefix = formatter.string(from: .init())
//        let fileName = prefix + input.file.filename
//        let path = req.application.directory.publicDirectory + fileName
//
//        let handle = try await req.application.fileio.openFile(
//            path: path,
//            mode: .write,
//            flags: .allowFileCreation(posixMode: 0x744),
//            eventLoop: req.eventLoop
//        ).get()
//        try await req.application.fileio.write(
//            fileHandle: handle,
//            buffer: input.file.data,
//            eventLoop: req.eventLoop
//        ).get()
//        try handle.close()
//        print(fileName)
//        return fileName
    }
}

struct SomeP: Codable {
    var name: String
    var filename: String
}

struct StreamModel: Content, CustomStringConvertible {
    var id: UUID?
    
    var fileName: String
    
    public func filePath(for app: Application) -> String {
        app.directory.publicDirectory + "Content/" + fileName
    }
    
    var description: String {
        return fileName
    }
    
    init(id: UUID? = nil, fileName: String) {
        self.id = id
        self.fileName = fileName
    }
}
