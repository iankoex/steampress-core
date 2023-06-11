import Vapor

public extension SteamPressPresenterFactory {
    var blog: BlogPresenter {
        guard let result = make(.blog) as? BlogPresenter else {
            fatalError("BlogPresenter is not configured")
        }
        return result
    }
    
    var admin: BlogAdminPresenter {
        guard let result = make(.admin) as? BlogAdminPresenter else {
            fatalError("BlogAdminPresenter is not configured")
        }
        return result
    }
}

public extension SteamPressPresenterID {
    static let blog = SteamPressPresenterID("blogPresenter")
    static let admin = SteamPressPresenterID("adminPresenter")
}
