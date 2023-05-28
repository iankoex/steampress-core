import Vapor

//public extension Request {
//    var blogUserRepository: BlogUserRepository {
//        self.application.steampress.blogRepositories.userRepository.for(self)
//    }
//    
//    var blogPostRepository: BlogPostRepository {
//        self.application.steampress.blogRepositories.postRepository.for(self)
//    }
//    
//    var blogTagRepository: BlogTagRepository {
//        self.application.steampress.blogRepositories.tagRepository.for(self)
//    }
//}

public extension SteamPressRepositoryFactory {
    var blogUser: BlogUserRepository {
        guard let result = make(.blogUser) as? BlogUserRepository else {
            fatalError("BlogUserRepository is not configured")
        }
        return result
    }
    
    var blogPost: BlogPostRepository {
        guard let result = make(.blogPost) as? BlogPostRepository else {
            fatalError("BlogPostRepository is not configured")
        }
        return result
    }
    
    var blogTag: BlogTagRepository {
        guard let result = make(.blogTag) as? BlogTagRepository else {
            fatalError("BlogTagRepository is not configured")
        }
        return result
    }
}

public extension SteamPressRepositoryId {
    static let blogUser = SteamPressRepositoryId("blogUser")
    static let blogPost = SteamPressRepositoryId("blogPost")
    static let blogTag = SteamPressRepositoryId("blogTag")
    static let chpter = SteamPressRepositoryId("chpter")
}
