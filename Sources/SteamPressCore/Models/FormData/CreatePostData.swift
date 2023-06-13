import Vapor

struct CreatePostData: Content {
    let title: String
    let contents: String
    let isDraft: Bool
    let tag: String
    let updateSlugURL: Bool?
}
