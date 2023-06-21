import Vapor
import Fluent

public class SteamPressLifecycleHandler: LifecycleHandler {

    var configuration: SteamPressConfiguration

    public init(configuration: SteamPressConfiguration = SteamPressConfiguration()) {
        self.configuration = configuration
    }
    
    public func willBoot(_ application: Application) throws {
        application.routes.defaultMaxBodySize = "100mb"
        application.sessions.use(.fluent)
        application.passwords.use(.bcrypt)
        
        // Migrations
        application.migrations.add(SessionRecord.migration)
        application.migrations.add(BlogUser.Migration())
        application.migrations.add(BlogPost.Migration())
        application.migrations.add(BlogTag.Migration())
        application.migrations.add(PostTagPivot.Migration())
        try application.autoMigrate().wait()
        
        // Routes
        let router = application.routes
        BlogPathCreator.setBlogPathFromEnv()
        let feedController = FeedController(feedInformation: self.configuration.feedInformation)
        let apiController = APIController()
        let blogController = BlogController(enableAuthorPages: self.configuration.enableAuthorPages, enableTagPages: self.configuration.enableTagPages, postsPerPage: self.configuration.postsPerPage)
        let blogAdminController = BlogAdminController()

        let blogRoutes: RoutesBuilder
        if let blogPath = BlogPathCreator.blogPath {
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
        application.middleware.use(BlogRememberMeMiddleware())

        try sessionedRoutes.register(collection: feedController)
        try sessionedRoutes.register(collection: apiController)
        try sessionedRoutes.register(collection: blogController)
        try sessionedRoutes.register(collection: blogAdminController)
    }
}
