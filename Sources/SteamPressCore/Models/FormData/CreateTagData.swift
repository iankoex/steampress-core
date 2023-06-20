import Vapor

public struct CreateTagData: Content {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}
