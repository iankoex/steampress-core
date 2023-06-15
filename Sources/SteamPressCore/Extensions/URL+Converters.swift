import Foundation
import Vapor

extension Request {
    func url() throws -> URL {
        guard var hostname = Environment.get("SP_WEBSITE_URL") else {
            throw SteamPressError(identifier: "SteamPressError", "SP_WEBSITE_URL not set")
        }
        if !hostname.hasSuffix("/") {
            hostname = hostname + "/"
        }
        var newHostName = hostname.appending(self.url.string)
        if !newHostName.hasSuffix("/") {
            newHostName = newHostName + "/"
        }
        guard let siteURL = URL(string: newHostName) else {
            throw SteamPressError(identifier: "SteamPressError", "Failed to convert url hostname to URL")
        }
        return siteURL
    }
    
    func rootUrl() throws -> URL {
        guard var hostname = Environment.get("SP_WEBSITE_URL") else {
            throw SteamPressError(identifier: "SteamPressError", "SP_WEBSITE_URL not set")
        }
        if !hostname.hasSuffix("/") {
            hostname = hostname + "/"
        }
        var newHostName = hostname.appending(BlogPathCreator.blogPath ?? "")
        if !newHostName.hasSuffix("/") {
            newHostName = newHostName + "/"
        }
        guard let url = URL(string: newHostName) else {
            throw SteamPressError(identifier: "SteamPressError", "Failed to convert url hostname to URL")
        }
        return url
    }
}
