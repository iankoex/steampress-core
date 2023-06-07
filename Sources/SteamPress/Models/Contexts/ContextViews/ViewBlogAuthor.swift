import Vapor

struct ViewBlogAuthor: Encodable {
    let userID: UUID
    let name: String
    let username: String
    let profilePicture: String?
    let twitterHandle: String?
    let biography: String?
    let tagline: String?
    let postCount: Int
}
