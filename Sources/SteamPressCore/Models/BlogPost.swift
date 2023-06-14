import Vapor
import Fluent
import SwiftSoup
import SwiftMarkdown

// MARK: - Model

public final class BlogPost: Model, Codable {
    
    public static let schema: String = "blog_posts"
    
    @ID
    public var id: UUID?
    
    @Field(key: "title")
    public var title: String
    
    @Field(key: "contents")
    public var contents: String
    
    @Parent(key: "author")
    public var author: BlogUser
    
    @Field(key: "slug_url")
    public var slugURL: String
    
    @Field(key: "published")
    public var published: Bool
    
    @Field(key: "image_url")
    public var imageURL: String?
    
    @Field(key: "image_alt")
    public var imageAlt: String?
    
    @Field(key: "snippet")
    public var snippet: String
    
    @Field(key: "created")
    public var created: Date
    
    @Timestamp(key: "last_edited", on: .update)
    public var lastEdited: Date?
    
    @Siblings(through: PostTagPivot.self, from: \.$post, to: \.$tag)
    public var tags: [BlogTag]
    
    public init() { }

    public init(
        title: String,
        contents: String,
        authorID: BlogUser.IDValue,
        slugURL: String,
        published: Bool,
        imageURL: String?,
        imageAlt: String?,
        snippet: String,
        creationDate: Date
    ) {
        self.title = title
        self.contents = contents
        self.$author.id = authorID
        self.slugURL = slugURL
        self.published = published
        self.imageURL = imageURL
        self.imageAlt = imageAlt
        self.snippet = snippet
        self.created = creationDate
        self.lastEdited = nil
    }
}

// MARK: - BlogPost Utilities

extension BlogPost {
    
    public func longSnippet() -> String {
        return getLines(characterLimit: 900)
    }

    private func getLines(characterLimit: Int) -> String {
        contents = contents.replacingOccurrences(of: "\r\n", with: "\n", options: .regularExpression)
        let lines = contents.components(separatedBy: "\n")
        var snippet = ""
        for line in lines where line != "" {
            snippet += "\(line)\n"
            if snippet.count > characterLimit {
                return snippet
            }
        }
        return snippet
    }

    static func generateUniqueSlugURL(from title: String, on req: Request) async throws -> String {
        let alphanumericsWithHyphenAndSpace = CharacterSet(charactersIn: " -0123456789abcdefghijklmnopqrstuvwxyz")
        let initialSlug = title.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: alphanumericsWithHyphenAndSpace.inverted).joined()
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
            .replacingOccurrences(of: " ", with: "-", options: .regularExpression)
        let postWithSameSlug = try await req.repositories.blogPost.getPost(slug: initialSlug)
        if postWithSameSlug != nil {
            let randomNumber = req.randomNumberGenerator.getNumber()
            return "\(initialSlug)-\(randomNumber)"
        } else {
            return initialSlug
        }
    }
}
