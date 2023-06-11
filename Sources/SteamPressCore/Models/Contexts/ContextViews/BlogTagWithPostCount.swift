import Vapor

public struct BlogTagWithPostCount: Encodable {
    public let id: UUID
    public let name: String
    public let postCount: Int
    public let urlEncodedName: String
    
    public init(id: UUID, name: String, postCount: Int, urlEncodedName: String) {
        self.id = id
        self.name = name
        self.postCount = postCount
        self.urlEncodedName = urlEncodedName
    }
}
