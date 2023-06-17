import Vapor

struct CreatePostData: Content {
    let title: String
    let contents: String
    let snippet: String
    let isDraft: Bool
    let tags: [String]
    let updateSlugURL: Bool?
    let imageURL: String?
    let imageAlt: String?
}

extension CreatePostData {
    func createBlogPost(with authorID: UUID?, on req: Request) async throws -> BlogPost {
        let uniqueSlug = try await BlogPost.generateUniqueSlugURL(from: self.title, on: req)
        
        return BlogPost(
            title: self.title,
            contents: self.contents,
            authorID: authorID ?? UUID(),
            slugURL: uniqueSlug,
            published: !self.isDraft,
            imageURL: self.imageURL,
            imageAlt: self.imageAlt,
            snippet: self.snippet,
            creationDate: Date()
        )
    }
}
