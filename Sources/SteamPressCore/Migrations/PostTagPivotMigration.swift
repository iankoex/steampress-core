import Fluent

extension PostTagPivot {
    public struct Migration: AsyncMigration {
        public var name: String { "CreatePostTagPivot" }
        
        public init() {}
        
        public func prepare(on database: Database) async throws {
            
            try await database.schema(PostTagPivot.schema)
                .id()
                .field("post_id", .uuid, .required, .references(BlogPost.schema, .id))
                .field("tag_id", .uuid, .required, .references(BlogTag.schema, .id))
                .unique(on: "post_id", "tag_id")
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(PostTagPivot.schema)
                .delete()
        }
    }
}
