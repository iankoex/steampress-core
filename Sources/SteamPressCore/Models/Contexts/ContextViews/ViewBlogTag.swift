import Vapor

public struct ViewBlogTag: Encodable {
    public let tagID: UUID
    public let name: String
    public let urlEncodedName: String
    public let postsCount: Int?
}


public extension BlogTag {
    func toViewBlogTag(withPostsCount: Bool = false) throws -> ViewBlogTag {
        guard let tagID = self.id else {
            throw SteamPressError(identifier: "ViewBlogPost", "Tag has no ID")
        }
        return ViewBlogTag(
            tagID: tagID,
            name: self.name,
            urlEncodedName: self.slugURL,
            postsCount: withPostsCount ? self.posts.count : nil
        )
    }
}

public extension Collection where Element: BlogTag {
    func toViewBlogTag(withPostsCount: Bool = false) throws -> [ViewBlogTag] {
        return try self.map { try $0.toViewBlogTag(withPostsCount: withPostsCount) }
    }
}
