import Fluent

extension BlogTag {
    public struct Migration: AsyncMigration {
        public var name: String { "CreateBlogTag" }
        
        public init() {}
        
        public func prepare(on database: Database) async throws {
            
            try await database.schema(BlogTag.schema)
                .id()
                .field("tag_id", .int)
                .field("name", .string, .required)
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(BlogTag.schema)
                .delete()
        }
    }
}
