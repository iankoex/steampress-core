import Foundation
import Vapor

extension Request {
    func url() throws -> URL {
        guard let hostname = Environment.get("SP_WEBSITE_URL") else {
            throw SteamPressError(identifier: "SteamPressError", "SP_WEBSITE_URL not set")
        }
        let newHostName = hostname.appending(self.url.string)
        guard let siteURL = URL(string: newHostName) else {
            throw SteamPressError(identifier: "SteamPressError", "Failed to convert url hostname to URL")
        }
        return siteURL
    }
    
    func rootUrl() throws -> URL {
        guard let hostname = Environment.get("SP_WEBSITE_URL") else {
            throw SteamPressError(identifier: "SteamPressError", "SP_WEBSITE_URL not set")
        }
        let newHostName = hostname.appending(BlogPathCreator.blogPath ?? "")
        guard let url = URL(string: newHostName) else {
            throw SteamPressError(identifier: "SteamPressError", "Failed to convert url hostname to URL")
        }
        return url
    }
}
