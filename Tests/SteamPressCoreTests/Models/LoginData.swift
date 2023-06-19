import Vapor

struct LoginData: Content {
    let email: String
    let password: String
    let rememberMe: Bool?

    init(email: String, password: String, rememberMe: Bool? = nil) {
        self.email = email
        self.password = password
        self.rememberMe = rememberMe
    }
}
