import Vapor
import Foundation

struct RSSFeedGenerator {

    // MARK: - Properties

    let rfc822DateFormatter: DateFormatter
    let title: String
    let description: String
    let copyright: String?
    let imageURL: String?
    let xmlEnd = "</channel>\n\n</rss>"

    // MARK: - Initialiser

    init(title: String, description: String, copyright: String?, imageURL: String?) {
        self.title = title
        self.description = description
        self.copyright = copyright
        self.imageURL = imageURL

        rfc822DateFormatter = DateFormatter()
        rfc822DateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        rfc822DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc822DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    }

    // MARK: - Route Handler

    func feedHandler(_ request: Request) async throws -> Response {
        let posts = try await request.blogPostRepository.getAllPostsSortedByPublishDate(includeDrafts: false)
        var xmlFeed = try self.getXMLStart(for: request)
        
        if !posts.isEmpty {
            let postDate = posts[0].lastEdited ?? posts[0].created
            xmlFeed += "<pubDate>\(self.rfc822DateFormatter.string(from: postDate))</pubDate>\n"
        }
        
        xmlFeed += try "<textinput>\n<description>Search \(self.title)</description>\n<title>Search</title>\n<link>\(self.getRootPath(for: request))/search?</link>\n<name>term</name>\n</textinput>\n"
        
        var postInformation: [String] = []
        for post in posts {
            let data = try await post.getPostRSSFeed(rootPath: self.getRootPath(for: request), dateFormatter: self.rfc822DateFormatter, for: request)
            postInformation.append(data)
        }
        
        for post in postInformation {
            xmlFeed += post
        }
        
        xmlFeed += self.xmlEnd
        let httpResponse = Response(body: .init(stringLiteral: xmlFeed))
        httpResponse.headers.add(name: .contentType, value: "application/rss+xml")
        return httpResponse
    }

    // MARK: - Private functions

    private func getXMLStart(for request: Request) throws -> String {

        let link = try getRootPath(for: request) + "/"

        var start = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<rss version=\"2.0\">\n\n<channel>\n<title>\(title)</title>\n<link>\(link)</link>\n<description>\(description)</description>\n<generator>SteamPress</generator>\n<ttl>60</ttl>\n"

        if let copyright = copyright {
            start += "<copyright>\(copyright)</copyright>\n"
        }

        if let imageURL = imageURL {
            start += "<image>\n<url>\(imageURL)</url>\n<title>\(title)</title>\n<link>\(link)</link>\n</image>\n"
        }

        return start
    }

    private func getRootPath(for request: Request) throws -> String {
        guard let hostname = Environment.get("WEBSITE_URL") else {
            throw SteamPressError(identifier: "SteamPressError", "WEBSITE_URL not set")
        }
        let path = request.url.path
        return "\(hostname)\(path.replacingOccurrences(of: "/rss.xml", with: ""))"
    }
}

fileprivate extension BlogPost {
    func getPostRSSFeed(rootPath: String, dateFormatter: DateFormatter, for request: Request) async throws -> String {
        let link = rootPath + "/posts/\(slugUrl)/"
        var postEntry = "<item>\n<title>\n\(title)\n</title>\n<description>\n\(try description())\n</description>\n<link>\n\(link)\n</link>\n"

        let tags = try await request.blogTagRepository.getTags(for: self)
        for tag in tags {
            if let percentDecodedTag = tag.name.removingPercentEncoding {
                postEntry += "<category>\(percentDecodedTag)</category>\n"
            }
        }
        postEntry += "<pubDate>\(dateFormatter.string(from: self.lastEdited ?? self.created))</pubDate>\n</item>\n"
        return postEntry
    }
}
