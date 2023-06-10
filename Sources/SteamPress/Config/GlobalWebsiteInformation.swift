import Foundation

public struct GlobalWebsiteInformation: Encodable {
    public let title: String
    public let url: String
    public let logo: String
    public let image: String
    public let description: String
    public let loggedInUser: BlogUser.Public?
    public let currentPageURL: String
    public let currentPageEncodedURL: String
    public let generator: String
    public let disqusName: String?
    public let twitterHandle: String?
    public let googleAnalyticsIdentifier: String?
}
