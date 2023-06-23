import Vapor

public struct CreateTagData: Content {
    public let name: String
    public let visibility: BlogTag.TagVisibility
    
    public init(name: String, visibility: BlogTag.TagVisibility = .public) {
        self.name = name
        self.visibility = visibility
    }
}
