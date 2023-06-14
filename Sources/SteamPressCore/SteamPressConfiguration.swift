import Vapor

public class SteamPressConfiguration {
    let feedInformation: FeedInformation
    let postsPerPage: Int
    let enableAuthorPages: Bool
    let enableTagPages: Bool
    
    public init(
        feedInformation: FeedInformation = FeedInformation(),
        postsPerPage: Int = 10,
        enableAuthorPages: Bool = true,
        enableTagPages: Bool = true
    ) {
        self.feedInformation = feedInformation
        self.postsPerPage = postsPerPage
        self.enableAuthorPages = enableAuthorPages
        self.enableTagPages = enableTagPages
    }
}
