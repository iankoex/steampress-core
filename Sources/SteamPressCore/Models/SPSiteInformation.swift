import Vapor
import Fluent

// MARK: - Model

public final class SPSiteInformation: Model {
    
    public static let schema: String = "SP_Site_Information"
    
    @ID
    public var id: UUID?
    
    @Field(key: "title")
    public var title: String
    
    @Field(key: "description")
    public var description: String
    
    @Timestamp(key: "last_edited", on: .update)
    public var lastEdited: Date?
    
    public init () {}
    
    public init(
        id: UUID? = UUID(),
        title: String,
        description: String
    ) {
        self.id = id
        self.title = title
        self.description = description
    }
    
    static var current: SPSiteInformation = SPSiteInformation(
        title: "SteamPress",
        description: "The SteamPress Blog. SteamPress is an Open Source Blogging Engine and Platform Written in Swift, Powered by Vapor."
    )
}
