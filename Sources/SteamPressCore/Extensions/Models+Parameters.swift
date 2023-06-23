import Vapor

extension BlogUser: ParameterModel {
    public static let parameterKey = "blogUserID"
    public static let parameter = PathComponent(stringLiteral: ":\(BlogUser.parameterKey)")

}

extension BlogPost: ParameterModel {
    public static let parameterKey = "blogPostID"
    public static let parameter = PathComponent(stringLiteral: ":\(BlogPost.parameterKey)")
}

extension BlogTag: ParameterModel {
    public static let parameterKey = "blogTagName"
    public static let parameter = PathComponent(stringLiteral: ":\(BlogTag.parameterKey)")
}

protocol ParameterModel {
    static var parameterKey: String { get }
    static var parameter: PathComponent { get }
}

extension Parameters {    
    func findUser(on req: Request) async throws -> BlogUser {
        guard let userID = req.parameters.get(BlogUser.parameterKey, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let user = try await req.repositories.blogUser.getUser(id: userID ) else {
            throw Abort(.notFound)
        }
        return user
    }
    
    func findPost(on req: Request) async throws -> BlogPost {
        guard let postID = req.parameters.get(BlogPost.parameterKey, as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let post = try await req.repositories.blogPost.getPost(id: postID) else {
            throw Abort(.notFound)
        }
        return post
    }
    
    func findTag(on req: Request) async throws -> BlogTag {
        guard let tagSlug = req.parameters.get(BlogTag.parameterKey) else {
            throw Abort(.notFound)
        }
        guard let tag = try await req.repositories.blogTag.getTag(using: tagSlug) else {
            throw Abort(.notFound)
        }
        return tag
    }
}
