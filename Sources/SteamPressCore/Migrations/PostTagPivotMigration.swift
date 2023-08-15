import Fluent

extension PostTagPivot {
    public struct Migration: AsyncMigration {
        public var name: String { "Create_SP_PostTagPivot" }
        
        public init() {}
        
        public func prepare(on database: Database) async throws {
            
            try await database.schema(PostTagPivot.schema)
                .id()
                .field("post_id", .uuid, .required, .references(BlogPost.schema, .id, onDelete: .cascade, onUpdate: .cascade))
                .field("tag_id", .uuid, .required, .references(BlogTag.schema, .id, onDelete: .cascade, onUpdate: .cascade))
                .unique(on: "post_id", "tag_id")
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(PostTagPivot.schema)
                .delete()
        }
    }
}
