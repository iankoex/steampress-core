import Vapor
import Fluent

// MARK: - Model

public final class BlogTag: Model, Codable {
    
    public static let schema: String = "blog_tags"
    
    @ID
    public var id: UUID?
    
    @OptionalField(key: "tag_id")
    public var tagID: Int?
    
    @Field(key: "name")
    public var name: String
    
    public init () {}

    public init(id: Int? = nil, name: String) {
        self.tagID = id
        self.name = name
    }
}

extension BlogTag: Content {}
