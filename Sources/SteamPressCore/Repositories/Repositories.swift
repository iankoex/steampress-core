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

public extension SteamPressRepositoryID {
    static let blogUser = SteamPressRepositoryID("blogUser")
    static let blogPost = SteamPressRepositoryID("blogPost")
    static let blogTag = SteamPressRepositoryID("blogTag")
    static let chpter = SteamPressRepositoryID("chpter")
}
