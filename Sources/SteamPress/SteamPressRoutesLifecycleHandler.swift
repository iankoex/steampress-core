import Vapor
import Fluent

public class SteamPressRoutesLifecycleHandler: LifecycleHandler {

    var configuration: SteamPressConfiguration

    public init(configuration: SteamPressConfiguration = SteamPressConfiguration()) {
        self.configuration = configuration
    }
    
    public func willBoot(_ application: Application) throws {
        
        // Migrations
//        application.migrations.add(SessionRecord.migration)
        application.migrations.add(BlogPost.Migration())
        application.migrations.add(BlogTag.Migration())
        application.migrations.add(BlogUser.Migration())
//
        print(12)
        try application.autoMigrate().wait()
        print(13)
        
        // Repositories
        application.repositories.register(.blogTag) { req in
            FluentTagRepository(req)
        }
        
        application.repositories.register(.blogPost) { req in
            FluentPostRepository(req)
        }
        
        application.repositories.register(.blogUser) { req in
            FluentUserRepository(req)
        }
        
        let router = application.routes
        let pathCreator = BlogPathCreator(blogPath: self.configuration.blogPath)

        let feedController = FeedController(pathCreator: pathCreator, feedInformation: self.configuration.feedInformation)
        let apiController = APIController()
        let blogController = BlogController(pathCreator: pathCreator, enableAuthorPages: self.configuration.enableAuthorPages, enableTagPages: self.configuration.enableTagPages, postsPerPage: self.configuration.postsPerPage)
        let blogAdminController = BlogAdminController(pathCreator: pathCreator)

        let blogRoutes: RoutesBuilder
        if let blogPath = self.configuration.blogPath {
            blogRoutes = router.grouped(PathComponent(stringLiteral: blogPath))
        } else {
            blogRoutes = router.grouped("")
        }
        let steampressSessionsConfig = SessionsConfiguration(cookieName: "steampress-session") { value in
            HTTPCookies.Value(string: value.string)
        }
        let steampressSessions = SessionsMiddleware(session: application.sessions.driver, configuration: steampressSessionsConfig)
        let steampressAuthSessions = BlogAuthSessionsMiddleware()
        let sessionedRoutes = blogRoutes.grouped(steampressSessions, steampressAuthSessions)

        try sessionedRoutes.register(collection: feedController)
        try sessionedRoutes.register(collection: apiController)
        try sessionedRoutes.register(collection: blogController)
        try sessionedRoutes.register(collection: blogAdminController)
    }
}
