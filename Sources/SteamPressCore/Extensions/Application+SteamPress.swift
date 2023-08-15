import Vapor

extension Application {
    public class SteamPress {
        public let application: Application
        let lifecycleHandler: SteamPressLifecycleHandler
        
        init(application: Application, lifecycleHandler: SteamPressLifecycleHandler) {
            self.application = application
            self.lifecycleHandler = lifecycleHandler
        }
        
        struct Key: StorageKey {
            typealias Value = Storage
        }
        
        var storage: Storage {
            if self.application.storage[Key.self] == nil {
                self.initialize()
            }
            return self.application.storage[Key.self]!
        }
        
        func initialize() {
            self.application.storage[Key.self] = .init()
            self.application.lifecycle.use(lifecycleHandler)
        }
    }
    
    public var steampress: SteamPress {
        .init(application: self, lifecycleHandler: SteamPressLifecycleHandler())
    }
}
