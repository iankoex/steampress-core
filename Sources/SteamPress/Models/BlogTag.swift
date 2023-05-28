import Vapor
import Fluent

// MARK: - Model

public final class BlogTag: Model, Codable {
    
    public static let schema: String = "blog_tags"
    
    @ID
    public var id: UUID?
    
    @Field(key: "name")
    public var name: String
    
    @Siblings(through: PostTagPivot.self, from: \.$tag, to: \.$post)
    public var posts: [BlogPost]
    
    public init () {}

    public init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension BlogTag: Content {}
