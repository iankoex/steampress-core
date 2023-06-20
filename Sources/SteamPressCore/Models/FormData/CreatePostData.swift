import Vapor

public struct CreatePostData: Content {
    public let title: String
    public let contents: String
    public let snippet: String
    public let isDraft: Bool
    public let tags: [String]
    public let updateSlugURL: Bool?
    public let imageURL: String?
    public let imageAlt: String?
    
    public init(
        title: String,
        contents: String,
        snippet: String,
        isDraft: Bool,
        tags: [String],
        updateSlugURL: Bool? = nil,
        imageURL: String? = nil,
        imageAlt: String? = nil
    ) {
        self.title = title
        self.contents = contents
        self.snippet = snippet
        self.isDraft = isDraft
        self.tags = tags
        self.updateSlugURL = updateSlugURL
        self.imageURL = imageURL
        self.imageAlt = imageAlt
    }
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
