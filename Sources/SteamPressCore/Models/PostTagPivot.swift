import Vapor
import Fluent

public final class PostTagPivot: Model {
    public static let schema = "post_tag_pivot"
    
    @ID(key: .id)
    public var id: UUID?
    
    @Parent(key: "post_id")
    public var post: BlogPost
    
    @Parent(key: "tag_id")
    public var tag: BlogTag
    
    public init() { }
    
    public init(id: UUID? = nil, post: BlogPost, tag: BlogTag) throws {
        self.id = id
        self.$post.id = try post.requireID()
        self.$tag.id = try tag.requireID()
    }
}
