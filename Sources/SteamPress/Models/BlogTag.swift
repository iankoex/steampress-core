import Vapor
import Fluent

// MARK: - Model

public final class BlogTag: Model, Codable {
    
    public static let schema: String = "blog_tags"
    
    @ID
    public var id: UUID?
    
    @Field(key: "name")
    public var name: String
    
    @Field(key: "visibility")
    public var visibility: TagVisibility
    
    @Siblings(through: PostTagPivot.self, from: \.$tag, to: \.$post)
    public var posts: [BlogPost]
    
    public init () {}

    public init(
        id: UUID? = UUID(),
        name: String,
        visibility: TagVisibility
    ) {
        self.id = id
        self.name = name
        self.visibility = visibility
    }
}

extension BlogTag: Content {}

extension BlogTag {
    public enum TagVisibility: String, Codable {
        case `public`
        case `private`
    }
}
