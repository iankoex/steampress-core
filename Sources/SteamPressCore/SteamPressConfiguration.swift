import Vapor
import Fluent

extension SteamPressLifecycleHandler {
    
    func configure(_ app: Application) throws {
        _ = SPSiteInformation.query(on: app.db).first().map { info in
            if let info = info {
                SPSiteInformation.current = info
            } else {
                _ = SPSiteInformation.current.save(on: app.db)
            }
        }
        
        _ = BlogTag.query(on: app.db).first().map { tag in
            if tag == nil {
                let blogTag = BlogTag(name: "Blog", visibility: .public, slugURL: "blog")
                _ = blogTag.create(on: app.db)
            }
        }
    }
}
