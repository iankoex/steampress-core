import Vapor

public final class SteamPressPresenterRegistry {
    
    private let app: Application
    private var builders: [SteamPressPresenterID: ((Request) -> SteamPressPresenter)]
    
    fileprivate init(_ app: Application) {
        self.app = app
        self.builders = [:]
    }
    
    fileprivate func builder(_ req: Request) -> SteamPressPresenterFactory {
        .init(req, self)
    }
    
    fileprivate func make(_ id: SteamPressPresenterID, _ req: Request) -> SteamPressPresenter {
        guard let builder = builders[id] else {
            fatalError("SteamPressPresenter for id `\(id.string)` is not configured.")
        }
        return builder(req)
    }
    
    public func register(_ id: SteamPressPresenterID, _ builder: @escaping (Request) -> SteamPressPresenter) {
        builders[id] = builder
    }
}

public struct SteamPressPresenterFactory {
    private var registry: SteamPressPresenterRegistry
    private var req: Request
    
    fileprivate init(_ req: Request, _ registry: SteamPressPresenterRegistry) {
        self.req = req
        self.registry = registry
    }
    
    public func make(_ id: SteamPressPresenterID) -> SteamPressPresenter {
        registry.make(id, req)
    }
}

public struct SteamPressPresenterID: Hashable, Codable {
    
    public let string: String
    
    public init(_ string: String) {
        self.string = string
    }
}

public extension Application {
    
    private struct Key: StorageKey {
        typealias Value = SteamPressPresenterRegistry
    }
    
    var presenters: SteamPressPresenterRegistry {
        if storage[Key.self] == nil {
            storage[Key.self] = .init(self)
        }
        return storage[Key.self]!
    }
}

public extension Request {
    
    var presenters: SteamPressPresenterFactory {
        application.presenters.builder(self)
    }
}
