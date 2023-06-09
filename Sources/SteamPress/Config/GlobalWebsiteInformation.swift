import Foundation

public struct GlobalWebsiteInformation: Encodable {
    public let name: String
    public let url: String
    public let logo: String?
    public let loggedInUser: BlogUser.Public?
    public let currentPageURL: String
    public let currentPageEncodedURL: String
    public let disqusName: String?
    public let twitterHandle: String?
    public let googleAnalyticsIdentifier: String?
}
