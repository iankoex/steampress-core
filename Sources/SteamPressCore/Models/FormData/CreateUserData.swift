import Vapor

struct CreateUserData: Content {
    let name: String?
    let username: String?
    let password: String?
    let confirmPassword: String?
    let email: String?
    let profilePicture: String?
    let tagline: String?
    let biography: String?
    let twitterHandle: String?
    let resetPasswordOnLogin: Bool?
}

struct CreateOwnerData: Content {
    let name: String
    let password: String
    let email: String
}

extension CreateOwnerData: Validatable {
    static func validations(_ validations: inout Validations) {
        let usernameCharacterSet = CharacterSet(charactersIn: "-_")
        let usernameValidationCharacters = Validator<String>.characterSet(.alphanumerics + usernameCharacterSet)
        validations.add("name", as: String.self, is: usernameValidationCharacters)
        validations.add("password", as: String.self, is: .valid)
        validations.add("email", as: String.self, is: .email)
    }
}

extension CreateUserData: Validatable {
    
    static func validations(_ validations: inout Validations) {
        let usernameCharacterSet = CharacterSet(charactersIn: "-_")
        let usernameValidationCharacters = Validator<String>.characterSet(.alphanumerics + usernameCharacterSet)
        validations.add("username", as: String.self, is: usernameValidationCharacters)
    }
}
