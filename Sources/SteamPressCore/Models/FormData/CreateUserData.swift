import Vapor

public struct CreateUserData: Content, Codable {
    public let name: String
    public let username: String
    public let password: String?
    public let confirmPassword: String?
    public let email: String
    public let profilePicture: String?
    public let tagline: String?
    public let biography: String?
    public let twitterHandle: String?
    public let resetPasswordOnLogin: Bool?
}

public struct CreateOwnerData: Content {
    public let name: String
    public let password: String
    public let email: String
    
    public init(name: String, password: String, email: String) {
        self.name = name
        self.password = password
        self.email = email
    }
}

extension CreateOwnerData: Validatable {
    public static func validations(_ validations: inout Validations) {
        let usernameCharacterSet = CharacterSet(charactersIn: "-_")
        let usernameValidationCharacters = Validator<String>.characterSet(.alphanumerics + usernameCharacterSet)
        validations.add("name", as: String.self, is: usernameValidationCharacters)
        validations.add("password", as: String.self, is: .valid)
        validations.add("email", as: String.self, is: .email)
    }
}

extension CreateUserData: Validatable {
     public static func validations(_ validations: inout Validations) {
        let usernameCharacterSet = CharacterSet(charactersIn: "-_")
        let usernameValidationCharacters = Validator<String>.characterSet(.alphanumerics + usernameCharacterSet)
        validations.add("username", as: String.self, is: usernameValidationCharacters)
    }
}

extension BlogUser {
    func convertToUserData() -> CreateUserData {
        CreateUserData(name: name, username: username, password: nil, confirmPassword: nil, email: email, profilePicture: profilePicture, tagline: tagline, biography: biography, twitterHandle: twitterHandle, resetPasswordOnLogin: resetPasswordRequired)
    }
}
