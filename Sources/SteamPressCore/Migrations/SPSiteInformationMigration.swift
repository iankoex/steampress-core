import Fluent

extension SPSiteInformation {
    public struct Migration: AsyncMigration {
        public var name: String { "Create_SP_SiteInformation" }
        
        public init() {}
        
        public func prepare(on database: Database) async throws {
            
            try await database.schema(SPSiteInformation.schema)
                .id()
                .field("title", .string, .required)
                .field("description", .string, .required)
                .field("last_edited", .datetime)
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(SPSiteInformation.schema)
                .delete()
        }
    }
}
