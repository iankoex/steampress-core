import Vapor
import SteamPressCore

class InMemoryRepository: BlogTagRepository, BlogPostRepository, BlogUserRepository {

    private(set) var tags: [BlogTag]
    private(set) var posts: [BlogPost]
    private(set) var users: [BlogUser]
    private(set) var postTagLinks: [BlogPostTagLink]

    required init(_ req: Vapor.Request) {
        tags = []
        posts = []
        users = []
        postTagLinks = []
    }

    // MARK: - BlogTagRepository
    
    func `for`(_ request: Request) -> BlogTagRepository {
        return self
    }

    func getAllTags() async throws -> [BlogTag] {
        return tags
    }

    func getAllTagsWithPostCount() async throws -> [(BlogTag, Int)] {
        let tagsWithCount = tags.map { tag -> (BlogTag, Int) in
            let postCount = postTagLinks.filter { $0.tagID == tag.id }.count
            return (tag, postCount)
        }
        return tagsWithCount
    }
    
    func getTagsForAllPosts() async throws -> [UUID : [BlogTag]] {
        var dict = [UUID: [BlogTag]]()
        for tag in tags {
            postTagLinks.filter { $0.tagID == tag.id }.forEach { link in
                if var array = dict[link.postID] {
                    array.append(tag)
                    dict[link.postID] = array
                } else {
                    dict[link.postID] = [tag]
                }
            }
        }
        return dict
    }

    func getTags(for post: BlogPost) async throws -> [BlogTag] {
        var results = [BlogTag]()
        guard let postID = post.id else {
            fatalError("Post doesn't exist when it should")
        }
        for link in postTagLinks where link.postID == postID {
            let foundTag = tags.first { $0.id == link.tagID }
            guard let tag =  foundTag else {
                fatalError("Tag doesn't exist when it should")
            }
            results.append(tag)
        }
        return results
    }

    func save(_ tag: BlogTag) async throws {
        if tag.id == nil {
//            tag.id = tags.count + 1
            tag.id = UUID()
        }
        tags.append(tag)
    }

    func addTag(name: String) throws -> BlogTag {
        let newTag = BlogTag(id: UUID(), name: name)
        tags.append(newTag)
        return newTag
    }

    func add(_ tag: BlogTag, to post: BlogPost) async throws -> Void {
        do {
            try internalAdd(tag, to: post)
        } catch {
            throw SteamPressTestError(name: "Failed to add tag to post")
        }
    }

    func internalAdd(_ tag: BlogTag, to post: BlogPost) throws {
        guard let postID = post.id else {
            fatalError("Blog doesn't exist when it should")
        }
        guard let tagID = tag.id else {
            fatalError("Tag ID hasn't been set")
        }
        let newLink = BlogPostTagLink(postID: postID, tagID: tagID)
        postTagLinks.append(newLink)
    }

    func addTag(name: String, for post: BlogPost) throws -> BlogTag {
        let newTag = try addTag(name: name)
        try internalAdd(newTag, to: post)
        return newTag
    }

    func getTag(_ name: String) async throws -> BlogTag? {
        return tags.first { $0.name == name }
    }

    func addTag(_ tag: BlogTag, to post: BlogPost) {
        guard let postID = post.id else {
            fatalError("Blog doesn't exist when it should")
        }
        guard let tagID = tag.id else {
            fatalError("Tag ID hasn't been set")
        }
        let newLink = BlogPostTagLink(postID: postID, tagID: tagID)
        postTagLinks.append(newLink)
    }

    func deleteTags(for post: BlogPost) async throws -> Void {
        let tags = try await getTags(for: post)
        for tag in tags {
            self.postTagLinks.removeAll { $0.tagID == tag.id! && $0.postID == post.id! }
        }
    }

    func remove(_ tag: BlogTag, from post: BlogPost) -> Void {
        self.postTagLinks.removeAll { $0.tagID == tag.id! && $0.postID == post.id! }
    }

    // MARK: - BlogPostRepository
    
    func `for`(_ request: Request) -> BlogPostRepository {
        return self
    }

    func getAllPostsSortedByPublishDate(includeDrafts: Bool) async throws -> [BlogPost] {
        var sortedPosts = posts.sorted { $0.created > $1.created }
        if !includeDrafts {
            sortedPosts = sortedPosts.filter { $0.published }
        }
        return sortedPosts
    }

    func getAllPostsSortedByPublishDate(includeDrafts: Bool, count: Int, offset: Int) async throws -> [BlogPost] {
        var sortedPosts = posts.sorted { $0.created > $1.created }
        if !includeDrafts {
            sortedPosts = sortedPosts.filter { $0.published }
        }
        let startIndex = min(offset, sortedPosts.count)
        let endIndex = min(offset + count, sortedPosts.count)
        return Array(sortedPosts[startIndex..<endIndex])
    }
    
    func getAllPostsCount(includeDrafts: Bool) -> Int {
        var sortedPosts = posts.sorted { $0.created > $1.created }
        if !includeDrafts {
            sortedPosts = sortedPosts.filter { $0.published }
        }
        return sortedPosts.count
    }

    func getAllPostsSortedByPublishDate(for user: BlogUser, includeDrafts: Bool, count: Int, offset: Int) async throws -> [BlogPost] {
        let authorsPosts = posts.filter { $0.author.id == user.id }
        var sortedPosts = authorsPosts.sorted { $0.created > $1.created }
        if !includeDrafts {
            sortedPosts = sortedPosts.filter { $0.published }
        }
        let startIndex = min(offset, sortedPosts.count)
        let endIndex = min(offset + count, sortedPosts.count)
        return Array(sortedPosts[startIndex..<endIndex])
    }

    func getPostCount(for user: BlogUser) -> Int {
        return posts.filter { $0.author.id == user.id }.count
    }

    func getPost(slug: String) async throws -> BlogPost? {
        return posts.first { $0.slugURL == slug }
    }

    func getPost(id: UUID) async throws -> BlogPost? {
        return posts.first { $0.id == id }
    }

    func getSortedPublishedPosts(for tag: BlogTag, count: Int, offset: Int) async throws -> [BlogPost] {
        var results = [BlogPost]()
        guard let tagID = tag.id else {
            fatalError("Tag doesn't exist when it should")
        }
        for link in postTagLinks where link.tagID == tagID {
            let foundPost = posts.first { $0.id == link.postID }
            guard let post =  foundPost else {
                fatalError("Post doesn't exist when it should")
            }
            results.append(post)
        }
        let sortedPosts = results.sorted { $0.created > $1.created }.filter { $0.published }
        let startIndex = min(offset, sortedPosts.count)
        let endIndex = min(offset + count, sortedPosts.count)
        return Array(sortedPosts[startIndex..<endIndex])
    }
    
    func getPublishedPostCount(for tag: BlogTag) async throws -> Int {
        var results = [BlogPost]()
        guard let tagID = tag.id else {
            fatalError("Tag doesn't exist when it should")
        }
        for link in postTagLinks where link.tagID == tagID {
            let foundPost = posts.first { $0.id == link.postID }
            guard let post =  foundPost else {
                fatalError("Post doesn't exist when it should")
            }
            results.append(post)
        }
        let sortedPosts = results.sorted { $0.created > $1.created }.filter { $0.published }
        return sortedPosts.count
    }
    
    func getPublishedPostCount(for searchTerm: String) async throws -> Int {
        let titleResults = posts.filter { $0.title.contains(searchTerm) }
        let results = titleResults.sorted { $0.created > $1.created }.filter { $0.published }
        return results.count
    }
    
    func findPublishedPostsOrdered(for searchTerm: String, count: Int, offset: Int) async throws -> [BlogPost] {
        let titleResults = posts.filter { $0.title.contains(searchTerm) }
        let results = titleResults.sorted { $0.created > $1.created }.filter { $0.published }
        let startIndex = min(offset, results.count)
        let endIndex = min(offset + count, results.count)
        return Array(results[startIndex..<endIndex])
    }

    func save(_ post: BlogPost) async throws {
        self.add(post)
    }

    func add(_ post: BlogPost) {
        if (posts.first { $0.id == post.id } == nil) {
            post.id = UUID()
            posts.append(post)
        }
    }

    func delete(_ post: BlogPost) async throws -> Void {
        posts.removeAll { $0.id == post.id }
    }

    // MARK: - BlogUserRepository
    
    func `for`(_ request: Request) -> BlogUserRepository {
        return self
    }

    func add(_ user: BlogUser) {
        if (users.first { $0.id == user.id } == nil) {
            if (users.first { $0.username == user.username} != nil) {
                fatalError("Duplicate users added with username \(user.username)")
            }
            user.id = UUID()
            users.append(user)
        }
    }

    func getUser(id: UUID) -> BlogUser? {
        return users.first { $0.id == id }
    }

    func getAllUsers() async throws -> [BlogUser] {
        return users
    }

    func getAllUsersWithPostCount() async throws -> [(BlogUser, Int)] {
        let usersWithCount = users.map { user -> (BlogUser, Int) in
            let postCount = posts.filter { $0.author.id == user.id }.count
            return (user, postCount)
        }
        return usersWithCount
    }

    func getUser(username: String) async throws -> BlogUser? {
        return users.first { $0.username == username }
    }

    private(set) var userUpdated = false
    func save(_ user: BlogUser) async throws {
        self.add(user)
        userUpdated = true
    }

    func delete(_ user: BlogUser) async throws -> Void {
        users.removeAll { $0.id == user.id }
    }

    func getUsersCount() async throws -> Int {
        return users.count
    }

}

struct BlogPostTagLink: Codable {
    let postID: UUID
    let tagID: UUID
}
