import Foundation
import Vapor
import SwiftSoup
import SwiftMarkdown

struct ViewBlogPost: Encodable {
    var id: UUID?
    var title: String
    var contents: String
    var author: UUID
    var created: Date
    var lastEdited: Date?
    var slugUrl: String
    var published: Bool
    var longSnippet: String
    var createdDate: Date
    var lastEditedDate: Date?
    var authorName: String
    var authorUsername: String
    var image: String?
    var imageAlt: String?
    var description: String
    var tags: [ViewBlogTag]?
}

extension BlogPost {
    func toViewPost() throws -> ViewBlogPost {
        
        let postImage: String?
        let postImageAlt: String?
        
        let image = try SwiftSoup.parse(markdownToHTML(self.contents)).select("img").first()

        if let imageFound = image {
            postImage = try imageFound.attr("src")
            do {
                let imageAlt = try imageFound.attr("alt")
                if imageAlt != "" {
                    postImageAlt = imageAlt
                }  else {
                    postImageAlt = nil
                }
            } catch {
                postImageAlt = nil
            }
        } else {
            postImage = nil
            postImageAlt = nil
        }
        let viewTags = try self.tags.toViewBlogTag()
        return try ViewBlogPost(
            id: self.id,
            title: self.title,
            contents: self.contents,
            author: self.$author.id,
            created: created,
            lastEdited: self.lastEdited,
            slugUrl: self.slugUrl,
            published: self.published,
            longSnippet: self.longSnippet(),
            createdDate: self.created,
            lastEditedDate: self.lastEdited,
            authorName: self.author.name,
            authorUsername: self.author.username,
            image: postImage,
            imageAlt: postImageAlt,
            description: self.description(),
            tags: viewTags.isEmpty ? nil : viewTags
        )
    }
}

extension Array where Element: BlogPost {
    func toViewPosts() throws -> [ViewBlogPost] {
        return try self.map { try $0.toViewPost() }
    }
}
