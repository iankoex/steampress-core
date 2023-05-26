import Vapor

public protocol SteamPressRepository {
    //    associatedtype ModelType
    //    func get(_ id: Int, on eventLoop: EventLoop) async throws -> ModelType
}

public protocol BlogTagRepository: SteamPressRepository {
    func `for`(_ request: Request) async throws -> BlogTagRepository
    func getAllTags() async throws -> [BlogTag]
    func getAllTagsWithPostCount() async throws -> [(BlogTag, Int)]
    func getTags(for post: BlogPost) async throws -> [BlogTag]
    func getTagsForAllPosts() async throws -> [Int: [BlogTag]]
    func getTag(_ name: String) async throws -> BlogTag?
    func save(_ tag: BlogTag) async throws -> BlogTag
    // Delete all the pivots between a post and collection of tags -> you should probably delete the
    // tags that have no posts associated with a tag
    func deleteTags(for post: BlogPost) async throws -> Void
    func remove(_ tag: BlogTag, from post: BlogPost) async throws -> Void
    func add(_ tag: BlogTag, to post: BlogPost) async throws -> Void
}

public protocol BlogPostRepository: SteamPressRepository {
    func `for`(_ request: Request) async throws -> BlogPostRepository
    func getAllPostsSortedByPublishDate(includeDrafts: Bool) async throws -> [BlogPost]
    func getAllPostsCount(includeDrafts: Bool) async throws -> Int
    func getAllPostsSortedByPublishDate(includeDrafts: Bool, count: Int, offset: Int) async throws -> [BlogPost]
    func getAllPostsSortedByPublishDate(for user: BlogUser, includeDrafts: Bool, count: Int, offset: Int) async throws -> [BlogPost]
    func getPostCount(for user: BlogUser) async throws -> Int
    func getPost(slug: String) async throws -> BlogPost?
    func getPost(id: Int) async throws -> BlogPost?
    func getSortedPublishedPosts(for tag: BlogTag, count: Int, offset: Int) async throws -> [BlogPost]
    func getPublishedPostCount(for tag: BlogTag) async throws -> Int
    func findPublishedPostsOrdered(for searchTerm: String, count: Int, offset: Int) async throws -> [BlogPost]
    func getPublishedPostCount(for searchTerm: String) async throws -> Int
    func save(_ post: BlogPost) async throws -> BlogPost
    func delete(_ post: BlogPost) async throws -> Void
}

public protocol BlogUserRepository: SteamPressRepository {
    func `for`(_ request: Request) async throws -> BlogUserRepository
    func getAllUsers() async throws -> [BlogUser]
    func getAllUsersWithPostCount() async throws -> [(BlogUser, Int)]
    func getUser(id: Int) async throws -> BlogUser?
    func getUser(username: String) async throws -> BlogUser?
    func save(_ user: BlogUser) async throws -> BlogUser
    func delete(_ user: BlogUser) async throws -> Void
    func getUsersCount() async throws -> Int
}
