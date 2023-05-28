import Fluent
import Vapor

struct FluentUserRepository: BlogUserRepository {
    
    var req: Request
    
    init(_ req: Request) {
        self.req = req
    }
    
    func `for`(_ request: Vapor.Request) -> BlogUserRepository {
        return self
    }
    
    func getAllUsers() async throws -> [BlogUser] {
        try await BlogUser.query(on: req.db).all()
    }
    
    func getAllUsersWithPostCount() async throws -> [(BlogUser, Int)] {
        let users = try await BlogUser.query(on: req.db)
            .all()
//        let posts = try await BlogPost.query(on: req.db)
//            .filter(\.$published == true)
//            .all()
//        let postsByUserID = [Int: [BlogPost]](grouping: posts, by: { $0[keyPath: \.author] })
//        return users.map { user in
//            guard let userID = user.userID else {
//                return (user, 0)
//            }
//            let userPostCount = postsByUserID[userID]?.count ?? 0
//            return (user, userPostCount)
//        }
        
        return [(users[0], 0)]
    }
    
    func getUser(id: Int) async throws -> BlogUser? {
        try await BlogUser.query(on: req.db)
            .filter(\.$userID == id)
            .first()
    }
    
    func getUser(name: String) async throws -> BlogUser? {
        try await BlogUser.query(on: req.db)
            .filter(\.$name == name)
            .first()
    }
    
    func getUser(username: String) async throws -> BlogUser? {
        try await BlogUser.query(on: req.db)
            .filter(\.$username == username)
            .first()
    }
    
    func save(_ user: BlogUser) async throws {
        try await user.save(on: req.db)
    }
    
    func delete(_ user: BlogUser) async throws {
        try await user.delete(on: req.db)
    }
    
    func getUsersCount() async throws -> Int {
        try await BlogUser.query(on: req.db).count()
    }
}
