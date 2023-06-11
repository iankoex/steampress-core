import Vapor
import Fluent

public final class SteamPressRepositoryRegistry {
    
    private let app: Application
    private var builders: [SteamPressRepositoryID: ((Request) -> SteamPressRepository)]
    
    fileprivate init(_ app: Application) {
        self.app = app
        self.builders = [:]
    }
    
    fileprivate func builder(_ req: Request) -> SteamPressRepositoryFactory {
        .init(req, self)
    }
    
    fileprivate func make(_ id: SteamPressRepositoryID, _ req: Request) -> SteamPressRepository {
        guard let builder = builders[id] else {
            fatalError("SteamPressRepository for id `\(id.string)` is not configured.")
        }
        return builder(req)
    }
    
    public func register(_ id: SteamPressRepositoryID, _ builder: @escaping (Request) -> SteamPressRepository) {
        builders[id] = builder
    }
}

public struct SteamPressRepositoryFactory {
    private var registry: SteamPressRepositoryRegistry
    private var req: Request
    
    fileprivate init(_ req: Request, _ registry: SteamPressRepositoryRegistry) {
        self.req = req
        self.registry = registry
    }
    
    public func make(_ id: SteamPressRepositoryID) -> SteamPressRepository {
        registry.make(id, req)
    }
}

public struct SteamPressRepositoryID: Hashable, Codable {
    
    public let string: String
    
    public init(_ string: String) {
        self.string = string
    }
}

public extension Application {
    
    private struct Key: StorageKey {
        typealias Value = SteamPressRepositoryRegistry
    }
    
    var repositories: SteamPressRepositoryRegistry {
        if storage[Key.self] == nil {
            storage[Key.self] = .init(self)
        }
        return storage[Key.self]!
    }
}

public extension Request {
    
    var repositories: SteamPressRepositoryFactory {
        application.repositories.builder(self)
    }
}
