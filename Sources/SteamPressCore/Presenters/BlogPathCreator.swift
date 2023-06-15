import Vapor

public struct BlogPathCreator {
    
    private(set) static var blogPath: String? = nil
    
    public static func createPath(for path: String?, query: String? = nil) -> String {
        var createdPath = constructPath(from: path)
        
        if let query = query {
            createdPath = "\(createdPath)?\(query)"
        }
        return createdPath
    }
    
    fileprivate static func constructPath(from path: String?) -> String {
        if path == blogPath {
            if let index = blogPath, !index.isEmpty  {
                return "/\(index)/"
            } else {
                return "/"
            }
        }
        if let index = blogPath, !index.isEmpty {
            if let pathSuffix = path {
                return "/\(index)/\(pathSuffix)/"
            } else {
                return "/\(index)/"
            }
        } else {
            guard let path = path else {
                return "/"
            }
            return "/\(path)/"
        }
    }
    
    static func setBlogPathFromEnv() {
        if let path = Environment.get("SP_BLOG_PATH") {
            self.blogPath = path.trimmingCharacters(in: .whitespaces)
        }
    }
}
