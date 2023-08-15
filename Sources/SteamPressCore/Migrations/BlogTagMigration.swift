import Fluent

extension BlogTag {
    public struct Migration: AsyncMigration {
        public var name: String { "Create_SP_Tag" }
        
        public init() {}
        
        public func prepare(on database: Database) async throws {
            _ = try await database.enum("blog_tags_visibility")
                .case(TagVisibility.public.rawValue)
                .case(TagVisibility.private.rawValue)
                .create()
            
            try await database.schema(BlogTag.schema)
                .id()
                .field("name", .string, .required)
                .field("visibility", .string, .required)
                .field("slug_url", .string, .required)
                .field("created_date", .datetime)
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(BlogTag.schema)
                .delete()
        }
    }
}
