import Vapor
import Fluent

final class PostTagPivot: Model {
    static let schema = "post_tag_pivot"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "post_id")
    var post: BlogPost
    
    @Parent(key: "tag_id")
    var tag: BlogTag
    
    init() { }
    
    init(id: UUID? = nil, post: BlogPost, tag: BlogTag) throws {
        self.id = id
        self.$post.id = try post.requireID()
        self.$tag.id = try tag.requireID()
    }
}
