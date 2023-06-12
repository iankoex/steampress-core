import Vapor

struct LoginData: Content {
    let email: String
    let password: String
    let rememberMe: Bool?
}
