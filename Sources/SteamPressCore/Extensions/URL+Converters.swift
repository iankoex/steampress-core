import Foundation
import Vapor

extension Request {
    func url() throws -> URL {
        guard let hostname = Environment.get("SP_WEBSITE_URL") else {
            throw SteamPressError(identifier: "SteamPressError", "SP_WEBSITE_URL not set")
        }
        
        guard let siteURL = URL(string: hostname) else {
            throw SteamPressError(identifier: "SteamPressError", "Failed to convert url hostname to URL")
        }
        return siteURL.appendingPathComponent(self.url.string)
    }
    
    func rootUrl() throws -> URL {
        guard let hostname = Environment.get("SP_WEBSITE_URL") else {
            throw SteamPressError(identifier: "SteamPressError", "SP_WEBSITE_URL not set")
        }
        
        guard let url = URL(string: hostname) else {
            throw SteamPressError(identifier: "SteamPressError", "Failed to convert url hostname to URL")
        }
        return url.appendingPathComponent(BlogPathCreator.blogPath ?? "")
    }
}
