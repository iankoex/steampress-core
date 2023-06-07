import Vapor

extension Request {
    func pageInformation() throws -> BlogGlobalPageInformation {
        let currentURL = try self.url()
        guard let currentEncodedURL = currentURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SteamPressError(identifier: "STEAMPRESS", "Failed to convert page url to URL encoded")
        }
        return try BlogGlobalPageInformation(
            websiteName: "SteamPress",
            websiteURL: self.rootUrl(),
            websiteLogo: "/static/images/favicon.ico",
            loggedInUser: self.auth.get(BlogUser.self)?.convertToPublic(),
            currentPageURL: currentURL,
            currentPageEncodedURL: currentEncodedURL,
            disqusName: Environment.get("BLOG_DISQUS_NAME"),
            siteTwitterHandle: Environment.get("BLOG_SITE_TWITTER_HANDLE"),
            googleAnalyticsIdentifier: Environment.get("BLOG_GOOGLE_ANALYTICS_IDENTIFIER")
        )
    }

    func adminPageInfomation() throws -> BlogAdminPageInformation {
        return try BlogAdminPageInformation(loggedInUser: self.auth.require(BlogUser.self), websiteURL: self.rootUrl(), currentPageURL: self.url())
    }
}
