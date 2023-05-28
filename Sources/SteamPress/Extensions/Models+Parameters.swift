import Vapor

extension BlogUser: ParameterModel {
//    typealias Repository = repositories.blogUser
    public static let parameterKey = "blogUserID"
    public static let parameter = PathComponent(stringLiteral: ":\(BlogUser.parameterKey)")
    
//    public typealias ResolvedParameter = EventLoopFuture<BlogUser>
//    public static func resolveParameter(_ parameter: String, ) throws -> BlogUser.ResolvedParameter {
//        let userRepository = try container.make(repositories.blogUser.self)
//        guard let userID = Int(parameter) else {
//            throw SteamPressError(identifier: "Invalid-ID-Type", "Unable to convert \(parameter) to a User ID")
//        }
//        return userRepository.getUser(id: userID, on: container).unwrap(or: Abort(.notFound))
//    }
}

extension BlogPost: ParameterModel {
//    typealias Repository = repositories.blogPost
    public static let parameterKey = "blogPostID"
    public static let parameter = PathComponent(stringLiteral: ":\(BlogPost.parameterKey)")
    
//    public typealias ResolvedParameter = EventLoopFuture<BlogPost>
//    public static func resolveParameter(_ parameter: String, ) throws -> EventLoopFuture<BlogPost> {
//        let postRepository = try container.make(repositories.blogPost.self)
//        guard let postID = Int(parameter) else {
//            throw SteamPressError(identifier: "Invalid-ID-Type", "Unable to convert \(parameter) to a Post ID")
//        }
//        return postRepository.getPost(id: postID, on: container).unwrap(or: Abort(.notFound))
//    }
}

extension BlogTag: ParameterModel {
//    typealias Repository = repositories.blogTag
    public static let parameterKey = "blogTagName"
    public static let parameter = PathComponent(stringLiteral: ":\(BlogTag.parameterKey)")
    
//    public typealias ResolvedParameter = EventLoopFuture<BlogTag>
//    public static func resolveParameter(_ parameter: String, ) throws -> EventLoopFuture<BlogTag> {
//        let tagRepository = try container.make(repositories.blogTag.self)
//        return tagRepository.getTag(parameter, on: container).unwrap(or: Abort(.notFound))
//    }
}

protocol ParameterModel {
    static var parameterKey: String { get }
    static var parameter: PathComponent { get }
//    associatedtype Repository: SteamPressRepository
}
//
//extension Parameters {
//    func find<T>(on req: Request, repository: SteamPressRepository) -> EventLoopFuture<T> where T: ParameterModel {
//        guard let idString = req.parameters.get(T.parameterKey), let id = Int(idString) else {
//            return req.eventLoop.makeFailedFuture(Abort(.badRequest))
//        }
//        return repository.get(id, on: req.eventLoop)
//    }
//}

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
        guard let tagName = req.parameters.get(BlogTag.parameterKey) else {
            throw Abort(.notFound)
        }
        guard let tag = try await req.repositories.blogTag.getTag(tagName) else {
            throw Abort(.notFound)
        }
        return tag
    }
}
