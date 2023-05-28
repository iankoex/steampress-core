import Fluent
import Vapor

struct FluentTagRepository: BlogTagRepository {
    
    var req: Request
    
    init(_ req: Request) {
        self.req = req
    }
    
    func `for`(_ request: Vapor.Request) -> BlogTagRepository {
        return self
    }
    
    func getAllTags() async throws -> [BlogTag] {
        try await BlogTag.query(on: req.db).all()
    }
    
    func getAllTagsWithPostCount() async throws -> [(BlogTag, Int)] {
        let tags = try await BlogTag.query(on: req.db).all()
//        let pivots = try await BlogPostTagPivot.query(on: req.db).all()
//        return try tags.map { tag in
//            let postCount = try pivots.filter { try $0.tagID == tag.requireID() }.count
//            return (tag, postCount)
//        }
        fatalError()
        return [(tags[0], 0)]
    }
    
    func getTagsForAllPosts() async throws -> [Int : [BlogTag]] {
        let tags = try await BlogTag.query(on: req.db).all()
//        let pivots = try await BlogPostTagPivot.query(on: req.db).all()
//        let pivotsSortedByPost = Dictionary(grouping: pivots) { (pivot) -> Int in
//            return pivot.postID
//        }
//
//        let postsWithTags = pivotsSortedByPost.mapValues { value in
//            return value.map { pivot in
//                tags.first { $0.tagID == pivot.tagID }
//            }
//        }.mapValues { $0.compactMap { $0 } }
//
//        return postsWithTags
        fatalError()
        return [0: tags]
    }
    
    func getTags(for post: BlogPost) async throws -> [BlogTag] {
//        try await post.tags.query(on: req.db).all()
        fatalError()
        return []
    }
    
    func getTag(_ name: String) async throws -> BlogTag? {
        try await BlogTag.query(on: req.db).filter(\.$name == name).first()
    }
    
    func save(_ tag: BlogTag) async throws {
        try await tag.save(on: req.db)
    }
    
    func deleteTags(for post: BlogPost) async throws {
//        let tags = try await post.tags.query(on: req.db).all()
//        let tagIDs = tags.compactMap { $0.tagID }
//        try await BlogPostTagPivot.query(on: req.db)
//            .filter(\.$postID == post.requireID())
//            .filter(\.$tagID ~~ tagIDs)
//            .delete()
//        try await cleanupTags(tags: tags)
    }
    
    func remove(_ tag: BlogTag, from post: BlogPost) async throws {
//        try await post.tags.detach(tag, on: req.db)
//        try await self.cleanupTags(tags: [tag])
    }
    
    func cleanupTags(tags: [BlogTag]) async throws {
        print("Not Implemented")
        fatalError()
//        var tagCleanups = [EventLoopFuture<Void>]()
//        for tag in tags {
//            let tagCleanup = try tag.posts.query(on: req.db)
//                .all().flatMap(to: Void.self) { posts in
//                let cleanupFuture: EventLoopFuture<Void>
//                if posts.count == 0 {
//                    cleanupFuture = tag.delete(on: req.db)
//                } else {
//                    cleanupFuture = connection.future()
//                }
//                return cleanupFuture
//            }
//            tagCleanups.append(tagCleanup)
//        }
//        return tagCleanups.flatten(on: req.db)
    }
    
    func add(_ tag: BlogTag, to post: BlogPost) async throws {
//        try await post.tags.attach(tag, on: req.db)
    }
}
