import Vapor
import Fluent
import SteamPressCore

class InMemoryRepository: BlogTagRepository, BlogPostRepository, BlogUserRepository {
    var req: Request

    required init(_ req: Vapor.Request) {
        self.req = req
    }

    // MARK: - BlogTagRepository
    
    func `for`(_ request: Vapor.Request) -> BlogTagRepository {
        return self
    }
    
    func getAllTags() async throws -> [BlogTag] {
        let tags = try await BlogTag.query(on: req.db)
            .with(\.$posts)
            .sort(\.$createdDate, .descending)
            .all()
        return tags
    }
    
    func getAllTagsWithPostCount() async throws -> [(BlogTag, Int)] {
        let tags = try await BlogTag.query(on: req.db)
            .with(\.$posts)
            .all()
        var result: [(BlogTag, Int)] = []
        for tag in tags {
            let postCount = try await tag.$posts.get(on: req.db).count
            result.append((tag, postCount))
        }
        return result
    }
    
    func getTagsForAllPosts() async throws -> [UUID : [BlogTag]] {
        let tags = try await BlogTag.query(on: req.db)
            .with(\.$posts)
            .all()
        let pivots = try await PostTagPivot.query(on: req.db).all()
        let pivotsSortedByPost = Dictionary(grouping: pivots) { (pivot) -> UUID in
            return pivot.$post.id
        }
        
        let postsWithTags = pivotsSortedByPost.mapValues { value in
            return value.map { pivot in
                tags.first { $0.id == pivot.$tag.id }
            }
        }.mapValues { $0.compactMap { $0 } }
        
        return postsWithTags
    }
    
    func getTags(for post: BlogPost) async throws -> [BlogTag] {
        try await post.$tags.query(on: req.db)
            .with(\.$posts)
            .all()
    }
    
    func getTag(_ name: String) async throws -> BlogTag? {
        try await BlogTag.query(on: req.db)
            .filter(\.$name == name)
            .with(\.$posts)
            .first()
    }
    
    func save(_ tag: BlogTag) async throws {
        try await tag.save(on: req.db)
    }
    
    func update(_ tag: BlogTag) async throws {
        try await tag.update(on: req.db)
    }
    
    func delete(_ tag: BlogTag) async throws {
        try await tag.delete(on: req.db)
    }
    
    func deleteTags(for post: BlogPost) async throws {
        let tags = try await post.$tags.query(on: req.db)
            .with(\.$posts)
            .all()
        for tag in tags {
            try await remove(tag, from: post)
        }
    }
    
    func remove(_ tag: BlogTag, from post: BlogPost) async throws {
        try await post.$tags.detach(tag, on: req.db)
    }
    
    func add(_ tag: BlogTag, to post: BlogPost) async throws {
        try await post.$tags.attach(tag, on: req.db)
    }

    // MARK: - BlogPostRepository
    
    func `for`(_ request: Vapor.Request) -> BlogPostRepository {
        return self
    }
    
    func getAllPostsSortedByPublishDate(includeDrafts: Bool) async throws -> [BlogPost] {
        let query = BlogPost.query(on: req.db)
            .sort(\.$created, .descending)
            .with(\.$author)
            .with(\.$tags)
        if !includeDrafts {
            query.filter(\.$published == true)
        }
        return try await query.all()
    }
    
    func getAllDraftsPostsSortedByPublishDate() async throws -> [BlogPost] {
        let query = BlogPost.query(on: req.db)
            .sort(\.$created, .descending)
            .with(\.$author)
            .with(\.$tags)
            .filter(\.$published == false)
        return try await query.all()
    }
    
    func getAllPostsSortedByPublishDate(includeDrafts: Bool, count: Int, offset: Int) async throws -> [BlogPost] {
        let query = BlogPost.query(on: req.db)
            .sort(\.$created, .descending)
            .with(\.$author)
            .with(\.$tags)
        if !includeDrafts {
            query.filter(\.$published == true)
        }
        let upperLimit = count + offset
        return try await query.range(offset..<upperLimit).all()
    }
    
    func getAllPostsCount(includeDrafts: Bool) async throws -> Int {
        let query = BlogPost.query(on: req.db)
        if !includeDrafts {
            query.filter(\.$published == true)
        }
        return try await query.count()
    }
    
    func getAllPostsSortedByPublishDate(for user: BlogUser, includeDrafts: Bool, count: Int, offset: Int) async throws -> [BlogPost] {
        let query = user.$posts.query(on: req.db)
            .sort(\.$created, .descending)
            .with(\.$author)
            .with(\.$tags)
        if !includeDrafts {
            query.filter(\.$published == true)
        }
        let upperLimit = count + offset
        return try await query.range(offset..<upperLimit).all()
    }
    
    func getPostCount(for user: BlogUser) async throws -> Int {
        try await user.$posts.query(on: req.db)
            .filter(\.$published == true)
            .count()
    }
    
    func getPost(slug: String) async throws -> BlogPost? {
        try await BlogPost.query(on: req.db)
            .filter(\.$slugURL == slug)
            .with(\.$author)
            .with(\.$tags)
            .first()
    }
    
    func getPost(id: UUID) async throws -> BlogPost? {
        try await BlogPost.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$author)
            .with(\.$tags)
            .first()
    }
    
    func getSortedPublishedPosts(for tag: BlogTag, count: Int, offset: Int) async throws -> [BlogPost] {
        let query = tag.$posts.query(on: req.db)
            .filter(\.$published == true)
            .sort(\.$created, .descending)
            .with(\.$author)
            .with(\.$tags)
        let upperLimit = count + offset
        return try await query.range(offset..<upperLimit).all()
    }
    
    func getPublishedPostCount(for tag: BlogTag) async throws -> Int {
        try await tag.$posts.query(on: req.db)
            .filter(\.$published == true)
            .count()
    }
    
    func findPublishedPostsOrdered(for searchTerm: String, count: Int, offset: Int) async throws -> [BlogPost] {
        let query = BlogPost.query(on: req.db)
            .sort(\.$created, .descending)
            .filter(\.$published == true)
            .with(\.$author)
            .with(\.$tags)
        
        let upperLimit = count + offset
        let paginatedQuery = query.range(offset..<upperLimit)
        
        return try await paginatedQuery.group(.or) { or in
            or.filter(\.$title, .custom("ILIKE"), "%\(searchTerm)%")
            or.filter(\.$contents, .custom("ILIKE"), "%\(searchTerm)%")
        }.all()
    }
    
    func getPublishedPostCount(for searchTerm: String) async throws -> Int {
        try await BlogPost.query(on: req.db)
            .filter(\.$published == true).group(.or) { or in
                or.filter(\.$title, .custom("ILIKE"), "%\(searchTerm)%")
                or.filter(\.$contents, .custom("ILIKE"), "%\(searchTerm)%")
            }
            .count()
    }
    
    func save(_ post: BlogPost) async throws {
        try await post.save(on: req.db)
    }
    
    func delete(_ post: BlogPost) async throws {
        try await post.delete(on: req.db)
    }

    // MARK: - BlogUserRepository
    
    func `for`(_ request: Vapor.Request) -> BlogUserRepository {
        return self
    }
    
    func getAllUsers() async throws -> [BlogUser] {
        try await BlogUser.query(on: req.db).all()
    }
    
    func getAllUsersWithPostCount() async throws -> [(BlogUser, Int)] {
        let users = try await BlogUser.query(on: req.db)
            .all()
        var result: [(BlogUser, Int)] = []
        for user in users {
            let count = try await user.$posts.query(on: req.db).count()
            result.append((user, count))
        }
        return result
    }
    
    func getUser(id: UUID) async throws -> BlogUser? {
        try await BlogUser.query(on: req.db)
            .filter(\.$id == id)
            .first()
    }
    
    func getUser(name: String) async throws -> BlogUser? {
        try await BlogUser.query(on: req.db)
            .filter(\.$name == name)
            .first()
    }
    
    func getUser(username: String) async throws -> BlogUser? {
        try await BlogUser.query(on: req.db)
            .filter(\.$username == username)
            .first()
    }
    
    func getUser(email: String) async throws -> BlogUser? {
        try await BlogUser.query(on: req.db)
            .filter(\.$email == email)
            .first()
    }
    
    func save(_ user: BlogUser) async throws {
        try await user.save(on: req.db)
    }
    
    func delete(_ user: BlogUser) async throws {
        try await user.delete(on: req.db)
    }
    
    func getUsersCount() async throws -> Int {
        try await BlogUser.query(on: req.db).count()
    }
}
