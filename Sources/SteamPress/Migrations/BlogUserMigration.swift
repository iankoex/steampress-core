import Fluent

extension BlogUser {
    public struct Migration: AsyncMigration {
        public var name: String { "CreateBlogPost" }
        
        public init() {}
        
        public func prepare(on database: Database) async throws {
            
            try await database.schema(BlogUser.schema)
                .id()
                .field("name", .string, .required)
                .field("username", .string, .required)
                .field("password", .string, .required)
                .field("reset_password_required", .bool, .required)
                .field("profile_picture", .string)
                .field("twitter_handle", .string)
                .field("biography", .string)
                .field("tagline", .string)
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(BlogUser.schema)
                .delete()
        }
    }
}
