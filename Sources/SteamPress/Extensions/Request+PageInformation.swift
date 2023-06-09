import Vapor

extension Request {
    func websiteInformation() throws -> GlobalWebsiteInformation {
        let currentURL = try self.url()
        guard let currentEncodedURL = currentURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SteamPressError(identifier: "STEAMPRESS", "Failed to convert page url to URL encoded")
        }
        return try GlobalWebsiteInformation(
            name: "SteamPress",
            url: self.rootUrl().absoluteString,
            logo: "/static/images/favicon.ico",
            loggedInUser: self.auth.get(BlogUser.self)?.convertToPublic(),
            currentPageURL: currentURL.absoluteString,
            currentPageEncodedURL: currentEncodedURL,
            disqusName: Environment.get("BLOG_DISQUS_NAME"),
            twitterHandle: Environment.get("BLOG_SITE_TWITTER_HANDLE"),
            googleAnalyticsIdentifier: Environment.get("BLOG_GOOGLE_ANALYTICS_IDENTIFIER")
        )
    }

//    func adminPageInfomation() throws -> GlobalWebsiteInformation {
//        return try GlobalWebsiteInformation(loggedInUser: self.auth.require(BlogUser.self), url: self.rootUrl(), currentPageURL: self.url())
//    }
}
