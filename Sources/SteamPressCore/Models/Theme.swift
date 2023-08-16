import Vapor

struct Theme: Codable {
    var name: String
    var description: String
    var version: String
    var license: String
    var author: Author
    
    struct Author: Codable {
        var name: String
        var email: String
        var url: String
    }
}

extension Theme {
    static var requiredFiles: [String] {
        var adminFiles: [String] = ["admin/index", "admin/explore", "admin/pages", "admin/tags", "admin/tag", "admin/posts", "admin/post", "admin/members", "admin/member", "admin/login", "admin/resetPassword", "admin/settings"]
        var indexFiles: [String] = ["index", "tags", "tag", "authors", "author", "post", "search"]
        indexFiles.append(contentsOf: adminFiles)
        return indexFiles
    }
    
    var urlSafeName: String {
        let alphanumericsWithHyphenAndSpace = CharacterSet(charactersIn: " -0123456789abcdefghijklmnopqrstuvwxyz")
        let urlSafeName = name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: alphanumericsWithHyphenAndSpace.inverted).joined()
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
            .replacingOccurrences(of: " ", with: "-", options: .regularExpression)
        return urlSafeName
    }
}
