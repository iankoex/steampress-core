import Vapor

public class SteamPressConfiguration {
    let blogPath: String?
    let feedInformation: FeedInformation
    let postsPerPage: Int
    let enableAuthorPages: Bool
    let enableTagPages: Bool
    
    public init(
        blogPath: String? = nil,
        feedInformation: FeedInformation = FeedInformation(),
        postsPerPage: Int = 10,
        enableAuthorPages: Bool = true,
        enableTagPages: Bool = true) {
            self.blogPath = blogPath
            self.feedInformation = feedInformation
            self.postsPerPage = postsPerPage
            self.enableAuthorPages = enableAuthorPages
            self.enableTagPages = enableTagPages
        }
}
