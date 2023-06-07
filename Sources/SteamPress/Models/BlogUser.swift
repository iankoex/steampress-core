import Vapor
import Fluent

// MARK: - Model

public final class BlogUser: Model, Codable {
    
    public static let schema: String = "blog_users"
    
    @ID
    public var id: UUID?
    
    @Field(key: "name")
    public var name: String
    
    @Field(key: "username")
    public var username: String
    
    @Field(key: "password")
    public var password: String
    
    @Field(key: "reset_password_required")
    public var resetPasswordRequired: Bool
    
    @Field(key: "profile_picture")
    public var profilePicture: String?
    
    @Field(key: "twitter_handle")
    public var twitterHandle: String?
    
    @Field(key: "biography")
    public var biography: String?
    
    @Field(key: "tagline")
    public var tagline: String?
    
    @Children(for: \.$author)
    var posts: [BlogPost]
    
    public init () {}

    public init(
        id: UUID? = nil,
        name: String,
        username: String,
        password: String,
        resetPasswordRequired: Bool = false,
        profilePicture: String?,
        twitterHandle: String?,
        biography: String?,
        tagline: String?
    ) {
        self.id = id
        self.name = name
        self.username = username.lowercased()
        self.password = password
        self.resetPasswordRequired = resetPasswordRequired
        self.profilePicture = profilePicture
        self.twitterHandle = twitterHandle
        self.biography = biography
        self.tagline = tagline
    }

}

// MARK: - Authentication

extension BlogUser: Authenticatable {
    func authenticateSession(on req: Request) {
        req.session.data["_BlogUserSession"] = self.id?.description
        req.auth.login(self)
    }
}

extension Request {
    func unauthenticateBlogUserSession() {
        guard self.hasSession else {
            return
        }
        session.data["_BlogUserSession"] = nil
        self.auth.logout(BlogUser.self)
    }
}

extension BlogUser {
    public struct Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        var profilePicture: String?
        var twitterHandle: String?
        var biography: String?
        var tagline: String?
    }
}

extension BlogUser {
    func convertToPublic() -> BlogUser.Public {
        return BlogUser.Public(id: id, name: name, username: username, profilePicture: profilePicture, twitterHandle: twitterHandle, biography: biography, tagline: tagline)
    }
}

extension Collection where Element: BlogUser {
    func convertToPublic() -> [BlogUser.Public] {
        return self.map { $0.convertToPublic() }
    }
}
