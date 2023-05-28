import Vapor

struct BlogTagWithPostCount: Encodable {
    let id: UUID
    let name: String
    let postCount: Int
    let urlEncodedName: String
}

