import Vapor

public struct ViewBlogAuthor: Encodable {
    public let userID: UUID
    public let name: String
    public let username: String
    public let profilePicture: String?
    public let twitterHandle: String?
    public let biography: String?
    public let tagline: String?
    public let postCount: Int
    
    public init(userID: UUID, name: String, username: String, profilePicture: String?, twitterHandle: String?, biography: String?, tagline: String?, postCount: Int) {
        self.userID = userID
        self.name = name
        self.username = username
        self.profilePicture = profilePicture
        self.twitterHandle = twitterHandle
        self.biography = biography
        self.tagline = tagline
        self.postCount = postCount
    }
}
