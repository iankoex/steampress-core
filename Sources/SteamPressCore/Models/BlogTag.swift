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
    
    @Field(key: "slug_url")
    public var slugURL: String
    
    @Timestamp(key: "created_date", on: .create)
    public var createdDate: Date?
    
    @Siblings(through: PostTagPivot.self, from: \.$tag, to: \.$post)
    public var posts: [BlogPost]
    
    public init () {}

    public init(
        id: UUID? = UUID(),
        name: String,
        visibility: TagVisibility,
        slugURL: String
    ) {
        self.id = id
        self.name = name
        self.visibility = visibility
        self.slugURL = slugURL
    }
}

extension BlogTag: Content {}

extension BlogTag {
    public enum TagVisibility: String, Codable {
        case `public`
        case `private`
    }
}

public extension BlogTag {
    static func generateUniqueSlugURL(from name: String) -> String {
        let alphanumericsWithHyphenAndSpace = CharacterSet(charactersIn: " -0123456789abcdefghijklmnopqrstuvwxyz")
        let slug = name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: alphanumericsWithHyphenAndSpace.inverted).joined()
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
            .replacingOccurrences(of: " ", with: "-", options: .regularExpression)
        return slug
    }
}
