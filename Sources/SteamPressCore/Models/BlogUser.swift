import Vapor
import Fluent

// MARK: - Model

public final class BlogUser: Model, Codable {
    
    public static let schema: String = "SP_users"
    
    @ID
    public var id: UUID?
    
    @Field(key: "name")
    public var name: String
    
    @Field(key: "username")
    public var username: String
    
    @Field(key: "email")
    public var email: String
    
    @Field(key: "password")
    public var password: String
    
    @Field(key: "reset_password_required")
    public var resetPasswordRequired: Bool
    
    @Field(key: "user_type")
    public var type: BlogUserType
    
    @Field(key: "profile_picture")
    public var profilePicture: String?
    
    @Field(key: "twitter_handle")
    public var twitterHandle: String?
    
    @Field(key: "biography")
    public var biography: String?
    
    @Field(key: "tagline")
    public var tagline: String?
    
    @Timestamp(key: "created_date", on: .create)
    public var createdDate: Date?
    
    @Children(for: \.$author)
    public var posts: [BlogPost]
    
    public init () {}

    public init(
        id: UUID? = nil,
        name: String,
        username: String,
        email: String,
        password: String,
        resetPasswordRequired: Bool = false,
        type: BlogUserType,
        profilePicture: String?,
        twitterHandle: String?,
        biography: String?,
        tagline: String?
    ) {
        self.id = id
        self.name = name
        self.username = username.lowercased()
        self.email = email
        self.password = password
        self.resetPasswordRequired = resetPasswordRequired
        self.type = type
        self.profilePicture = profilePicture
        self.twitterHandle = twitterHandle
        self.biography = biography
        self.tagline = tagline
    }
}

public extension BlogUser {
    enum BlogUserType: String, Codable {
        case member
        case owner
        case administrator
        case editor
        case author
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
        public var id: UUID?
        public var name: String
        public var username: String
        public var email: String
        public var type: BlogUserType
        public var createdDate: Date?
        public var profilePicture: String?
        public var twitterHandle: String?
        public var biography: String?
        public var tagline: String?
    }
}

public extension BlogUser {
    func convertToPublic() -> BlogUser.Public {
        return BlogUser.Public(id: id, name: name, username: username, email: email, type: type, createdDate: createdDate, profilePicture: profilePicture, twitterHandle: twitterHandle, biography: biography, tagline: tagline)
    }
}

public extension Collection where Element: BlogUser {
    func convertToPublic() -> [BlogUser.Public] {
        return self.map { $0.convertToPublic() }
    }
}
