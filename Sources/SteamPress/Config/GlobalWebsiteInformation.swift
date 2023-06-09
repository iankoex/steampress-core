import Foundation

public struct GlobalWebsiteInformation: Encodable {
    public let name: String
    public let url: URL
    public let logo: String?
    public let loggedInUser: BlogUser.Public?
    public let currentPageURL: URL
    public let currentPageEncodedURL: String
    public let disqusName: String?
    public let twitterHandle: String?
    public let googleAnalyticsIdentifier: String?
}
