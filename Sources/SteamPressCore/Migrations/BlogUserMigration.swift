import Fluent

extension BlogUser {
    public struct Migration: AsyncMigration {
        public var name: String { "CreateBlogUser" }
        
        public init() {}
        
        public func prepare(on database: Database) async throws {
            let userType = try await database.enum("blog_users_type")
                .case(BlogUserType.member.rawValue)
                .case(BlogUserType.owner.rawValue)
                .case(BlogUserType.administrator.rawValue)
                .case(BlogUserType.editor.rawValue)
                .case(BlogUserType.author.rawValue)
                .create()
            
            try await database.schema(BlogUser.schema)
                .id()
                .field("name", .string, .required)
                .field("username", .string, .required)
                .field("email", .string, .required)
                .field("user_type", .string, .required)
                .field("password", .string, .required)
                .field("reset_password_required", .bool, .required)
                .field("profile_picture", .string)
                .field("twitter_handle", .string)
                .field("biography", .string)
                .field("tagline", .string)
                .field("created_date", .datetime)
                .unique(on: "email")
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(BlogUser.schema)
                .delete()
        }
    }
}
