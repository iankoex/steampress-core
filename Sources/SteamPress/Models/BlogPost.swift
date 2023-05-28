import Vapor
import Fluent
import SwiftSoup
import SwiftMarkdown

// MARK: - Model

public final class BlogPost: Model, Codable {
    
    public static let schema: String = "blog_posts"
    
    @ID
    public var id: UUID?

    @OptionalField(key: "blog_id")
    public var blogID: Int?
    
    @Field(key: "title")
    public var title: String
    
    @Field(key: "contents")
    public var contents: String
    
    @Parent(key: "author")
    public var author: BlogUser
    
    @Field(key: "created")
    public var created: Date
    
    @Timestamp(key: "last_edited", on: .update)
    public var lastEdited: Date?
    
    @Field(key: "slug_url")
    public var slugUrl: String
    
    @Field(key: "published")
    public var published: Bool
    
    public init() { }

    public init(
        title: String,
        contents: String,
        author: BlogUser,
        creationDate: Date,
        slugUrl: String,
        published: Bool
    ) throws {
        self.title = title
        self.contents = contents
        guard let authorID = author.id else {
            throw SteamPressError(identifier: "ID-required", "Author ID not set")
        }
        self.$author.id = authorID
        self.created = creationDate
        self.slugUrl = slugUrl
        self.lastEdited = nil
        self.published = published
    }
    
//    public init(
//        blogID: Int? = nil,
//        title: String,
//        contents: String,
//        authorID: Int,
//        creationDate: Date,
//        slugUrl: String,
//        published: Bool
//    ) {
//        self.blogID = blogID
//        self.title = title
//        self.contents = contents
//        self.author = authorID
//        self.created = creationDate
//        self.slugUrl = slugUrl
//        self.lastEdited = nil
//        self.published = published
//    }
}

// MARK: - BlogPost Utilities

extension BlogPost {

    public func shortSnippet() -> String {
        return getLines(characterLimit: 150)
    }

    public func longSnippet() -> String {
        return getLines(characterLimit: 900)
    }

    func description() throws -> String {
        return try SwiftSoup.parse(markdownToHTML(shortSnippet())).text()
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
