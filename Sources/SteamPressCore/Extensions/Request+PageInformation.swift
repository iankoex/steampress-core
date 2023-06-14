import Vapor

extension Request {
    func siteInformation() throws -> GlobalWebsiteInformation {
        let currentURL = try self.url()
        guard let currentEncodedURL = currentURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SteamPressError(identifier: "STEAMPRESS", "Failed to convert page url to URL encoded")
        }
        
        return try GlobalWebsiteInformation(
            title: "SteamPress",
            url: self.rootUrl().absoluteString,
            logo: "/static/images/favicon.ico",
            image: "/static/images/steampress-og-image_1.jpg",
            description: "The SteamPress Blog. SteamPress is an Open Source Blogging Engine and Platform written in Swift powered by Vapor.",
            loggedInUser: self.auth.get(BlogUser.self)?.convertToPublic(),
            currentPageURL: currentURL.absoluteString,
            currentPageEncodedURL: currentEncodedURL,
            generator: "SteamPress 2.0.4",
            disqusName: Environment.get("BLOG_DISQUS_NAME"),
            twitterHandle: Environment.get("BLOG_SITE_TWITTER_HANDLE"),
            googleAnalyticsIdentifier: Environment.get("BLOG_GOOGLE_ANALYTICS_IDENTIFIER")
        )
    }
}
