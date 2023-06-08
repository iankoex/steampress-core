import Fluent

extension BlogTag {
    public struct Migration: AsyncMigration {
        public var name: String { "CreateBlogTag" }
        
        public init() {}
        
        public func prepare(on database: Database) async throws {
            let visibility = try await database.enum("blog_tags_visibility")
                .case(TagVisibility.public.rawValue)
                .case(TagVisibility.private.rawValue)
                .create()
            
            try await database.schema(BlogTag.schema)
                .id()
                .field("name", .string, .required)
                .field("visibility", visibility, .required)
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(BlogTag.schema)
                .delete()
        }
    }
}
