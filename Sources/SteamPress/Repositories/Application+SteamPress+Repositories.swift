//import Vapor
//
//public extension Application.SteamPress {
//    struct BlogRepositories {
//        public struct Provider {
//            let run: (Application) -> ()
//            
//            public init(_ run: @escaping (Application) -> ()) {
//                self.run = run
//            }
//        }
//        
//        final class Storage {
//            var makePostRepository: ((Application) -> repositories.blogPost)?
//            var makeTagRepository: ((Application) -> repositories.blogTag)?
//            var makeUserRepository: ((Application) -> repositories.blogUser)?
//            init() { }
//        }
//        
//        struct Key: StorageKey {
//            typealias Value = Storage
//        }
//        
//        let application: Application
//        
//        public var userRepository: repositories.blogUser {
//            guard let makeRepository = self.storage.makeUserRepository else {
//                fatalError("No user repository configured. Configure with app.blogRepositories.use(...)")
//            }
//            return makeRepository(self.application)
//        }
//        
//        public var postRepository: repositories.blogPost {
//            guard let makeRepository = self.storage.makePostRepository else {
//                fatalError("No post repository configured. Configure with app.blogRepositories.use(...)")
//            }
//            return makeRepository(self.application)
//        }
//        
//        public var tagRepository: repositories.blogTag {
//            guard let makeRepository = self.storage.makeTagRepository else {
//                fatalError("No tag repository configured. Configure with app.blogRepositories.use(...)")
//            }
//            return makeRepository(self.application)
//        }
//        
//        public func use(_ provider: Provider) {
//            provider.run(self.application)
//        }
//        
//        public func use(_ makeRespository: @escaping (Application) -> (repositories.blogUser & repositories.blogTag & repositories.blogPost)) {
//            self.storage.makeUserRepository = makeRespository
//            self.storage.makeTagRepository = makeRespository
//            self.storage.makePostRepository = makeRespository
//        }
//        
//        public func use(_ makeRepository: @escaping (Application) -> repositories.blogUser) {
//            self.storage.makeUserRepository = makeRepository
//        }
//        
//        public func use(_ makeRepository: @escaping (Application) -> repositories.blogTag) {
//            self.storage.makeTagRepository = makeRepository
//        }
//        
//        public func use(_ makeRepository: @escaping (Application) -> repositories.blogPost) {
//            self.storage.makePostRepository = makeRepository
//        }
//        
//        public func initialize() {
//            self.application.storage[Key.self] = .init()
//        }
//        
//        private var storage: Storage {
//            if self.application.storage[Key.self] == nil {
//                self.initialize()
//            }
//            return self.application.storage[Key.self]!
//        }
//    }
//    
//    var blogRepositories: BlogRepositories {
//        .init(application: self.application)
//    }
//}
