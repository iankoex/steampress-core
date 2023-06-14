import Vapor
import Foundation

struct AtomFeedGenerator {

    // MARK: - Properties
    let title: String
    let description: String
    let copyright: String?
    let imageURL: String?

    let xmlDeclaration = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    let feedStart = "<feed xmlns=\"http://www.w3.org/2005/Atom\">"
    let feedEnd = "</feed>"
    let iso8601Formatter = DateFormatter()

    // MARK: - Initialiser
    init(title: String, description: String, copyright: String?, imageURL: String?) {
        self.title = title
        self.description = description
        self.copyright = copyright
        self.imageURL = imageURL

        iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        iso8601Formatter.locale = Locale(identifier: "en_US_POSIX")
        iso8601Formatter.timeZone = TimeZone(secondsFromGMT: 0)
    }

    // MARK: - Route Handler

    func feedHandler(_ request: Request) async throws -> Response {
        let posts = try await request.repositories.blogPost.getAllPostsSortedByPublishDate(includeDrafts: false)
        var feed = try self.getFeedStart(for: request)
        
        if !posts.isEmpty {
            let postDate = (posts[0].lastEdited ?? posts[0].created)
            feed += "<updated>\(self.iso8601Formatter.string(from: postDate))</updated>\n"
        } else {
            feed += "<updated>\(self.iso8601Formatter.string(from: Date()))</updated>\n"
        }
        
        if let copyright = self.copyright {
            feed += "<rights>\(copyright)</rights>\n"
        }
        
        if let imageURL = self.imageURL {
            feed += "<logo>\(imageURL)</logo>\n"
        }
        
        var postsInformation: [String] = []
        for post in posts {
            let data = try await post.getPostAtomFeed(blogPath: self.getRootPath(for: request), dateFormatter: self.iso8601Formatter, for: request)
            postsInformation.append(data)
        }
        
        for postInformation in postsInformation {
            feed += postInformation
        }
        
        feed += self.feedEnd
        let httpResponse = Response(body: .init(stringLiteral: feed))
        httpResponse.headers.add(name: .contentType, value: "application/atom+xml")
        return httpResponse
    }

    // MARK: - Private functions

    private func getFeedStart(for request: Request) throws -> String {
        let blogLink = try getRootPath(for: request) + "/"
        let feedLink = blogLink + "atom.xml"
        return "\(xmlDeclaration)\n\(feedStart)\n\n<title>\(title)</title>\n<subtitle>\(description)</subtitle>\n<id>\(blogLink)</id>\n<link rel=\"alternate\" type=\"text/html\" href=\"\(blogLink)\"/>\n<link rel=\"self\" type=\"application/atom+xml\" href=\"\(feedLink)\"/>\n<generator uri=\"https://www.steampress.io/\">SteamPress</generator>\n"
    }

    private func getRootPath(for request: Request) throws -> String {
        guard let hostname = Environment.get("WEBSITE_URL") else {
            throw SteamPressError(identifier: "SteamPressError", "WEBSITE_URL not set")
        }
        let path = request.url.path
        return "\(hostname)\(path.replacingOccurrences(of: "/atom.xml", with: ""))"
    }
}

fileprivate extension BlogPost {
    func getPostAtomFeed(blogPath: String, dateFormatter: DateFormatter, for request: Request) async throws -> String {
        let updatedTime = lastEdited ?? created
        let user = try await request.repositories.blogUser.getUser(id: self.$author.id)
        guard let user = user else {
            throw SteamPressError(identifier: "Invalid-relationship", "Blog user with ID \(self.author) not found")
        }
        guard let postID = self.id else {
            throw SteamPressError(identifier: "ID-required", "Blog Post has no ID")
        }
        var postEntry = "<entry>\n<id>\(blogPath)/posts-id/\(postID)/</id>\n<title>\(self.title)</title>\n<updated>\(dateFormatter.string(from: updatedTime))</updated>\n<published>\(dateFormatter.string(from: self.created))</published>\n<author>\n<name>\(user.name)</name>\n<uri>\(blogPath)/authors/\(user.username)/</uri>\n</author>\n<summary>\(self.snippet)</summary>\n<link rel=\"alternate\" href=\"\(blogPath)/posts/\(self.slugURL)/\" />\n"
        
        let tags = try await request.repositories.blogTag.getTags(for: self)
        for tag in tags {
            if let percentDecodedTag = tag.name.removingPercentEncoding {
                postEntry += "<category term=\"\(percentDecodedTag)\"/>\n"
            }
        }
        
        postEntry += "</entry>\n"
        return postEntry
    }
}
