import Vapor

public struct ResetPasswordData: Content {
    public let password: String?
    public let confirmPassword: String?
    
    public init(password: String?, confirmPassword: String?) {
        self.password = password
        self.confirmPassword = confirmPassword
    }
}
