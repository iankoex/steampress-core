import Fluent

extension BlogPost {
    public struct Migration: AsyncMigration {
        public var name: String { "CreateBlogPost" }
        
        public init() {}
        
        public func prepare(on database: Database) async throws {
            
            try await database.schema(BlogPost.schema)
                .id()
                .field("title", .string, .required)
                .field("contents", .string, .required)
                .field("author", .uuid, .required, .references(BlogUser.schema, .id))
                .field("created", .datetime, .required)
                .field("last_edited", .datetime)
                .field("slug_url", .string, .required)
                .field("published", .bool, .required)
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(BlogPost.schema)
                .delete()
        }
    }
}
