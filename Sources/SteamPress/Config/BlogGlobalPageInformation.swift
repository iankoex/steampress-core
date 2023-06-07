import Foundation

public struct BlogGlobalPageInformation: Encodable {
    public let websiteName: String
    public let websiteURL: URL
    public let websiteLogo: String?
    public let loggedInUser: BlogUser.Public?
    public let currentPageURL: URL
    public let currentPageEncodedURL: String
    public let disqusName: String?
    public let siteTwitterHandle: String?
    public let googleAnalyticsIdentifier: String?
}
