import Vapor
import Fluent

public class SteamPressLifecycleHandler: LifecycleHandler {
    
    public init() {}
    
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
        application.migrations.add(SPSiteInformation.Migration())
        try application.autoMigrate().wait()
        
        // Routes
        let router = application.routes
        BlogPathCreator.setBlogPathFromEnv()
        let feedInfo = FeedInformation(
            title: "The SteamPress Blog",
            description: "SteamPress is an open-source blogging engine written for and using Vapor in Swift",
            copyright: "Released under the MIT licence",
            imageURL: "https://user-images.githubusercontent.com/9938337/29742058-ed41dcc0-8a6f-11e7-9cfc-680501cdfb97.png"
        )
        let feedController = FeedController(feedInformation: feedInfo)
        let apiController = APIController()
        let blogController = BlogController(enableAuthorPages: true, enableTagPages: true, postsPerPage: 10)
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
        
        try configure(application)
    }
}
