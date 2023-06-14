import Vapor
import SwiftSoup
import SwiftMarkdown

struct CreatePostData: Content {
    let title: String
    let contents: String
    let excerpt: String?
    let isDraft: Bool
    let tag: String
    let updateSlugURL: Bool?
}

extension CreatePostData {
    func createBlogPost(with authorID: UUID?, on req: Request) async throws -> BlogPost {
        let uniqueSlug = try await BlogPost.generateUniqueSlugURL(from: self.title, on: req)
        let (postImageURL, postImageAlt) = try getImageAndImageAlt()
        let snippet = self.excerpt == nil ? try self.getSnippet() : self.excerpt ?? ""
        
        return BlogPost(
            title: self.title,
            contents: self.contents,
            authorID: authorID ?? UUID(),
            slugURL: uniqueSlug,
            published: !self.isDraft,
            imageURL: postImageURL,
            imageAlt: postImageAlt,
            snippet: snippet,
            creationDate: Date()
        )
    }
    
    private func getImageAndImageAlt() throws -> (String?, String?) {
        let postImageURL: String?
        let postImageAlt: String?
        
        let image = try SwiftSoup.parse(markdownToHTML(self.contents)).select("img").first()
        
        if let imageFound = image {
            postImageURL = try imageFound.attr("src")
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
            postImageURL = nil
            postImageAlt = nil
        }
        return (postImageURL, postImageAlt)
    }
    
    private func getSnippet() throws -> String {
        let lines = getLines(characterLimit: 150)
        let snippet = try SwiftSoup.parse(markdownToHTML(lines)).text()
        return snippet
    }
    
    private func getLines(characterLimit: Int) -> String {
        let contents = self.contents.replacingOccurrences(of: "\r\n", with: "\n", options: .regularExpression)
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
}
