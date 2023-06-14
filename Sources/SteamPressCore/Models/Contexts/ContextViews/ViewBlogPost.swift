import Foundation
import Vapor
import SwiftSoup
import SwiftMarkdown

public struct ViewBlogPost: Encodable {
    var id: UUID?
    var title: String
    var contents: String
    var author: UUID
    var created: Date
    var lastEdited: Date?
    var slugURL: String
    var published: Bool
    var longSnippet: String
    var createdDate: Date
    var lastEditedDate: Date?
    var authorName: String
    var authorUsername: String
    var image: String?
    var imageAlt: String?
    var snippet: String
    var tags: [ViewBlogTag]?
}

public extension BlogPost {
    func toViewPost() throws -> ViewBlogPost {
        let viewTags = try self.tags.toViewBlogTag()
        
        return ViewBlogPost(
            id: self.id,
            title: self.title,
            contents: self.contents,
            author: self.$author.id,
            created: created,
            lastEdited: self.lastEdited,
            slugURL: self.slugURL,
            published: self.published,
            longSnippet: self.longSnippet(),
            createdDate: self.created,
            lastEditedDate: self.lastEdited,
            authorName: self.author.name,
            authorUsername: self.author.username,
            image: self.imageURL,
            imageAlt: self.imageAlt,
            snippet: self.snippet,
            tags: viewTags.isEmpty ? nil : viewTags
        )
    }
}

public extension Array where Element: BlogPost {
    func toViewPosts() throws -> [ViewBlogPost] {
        return try self.map { try $0.toViewPost() }
    }
}
