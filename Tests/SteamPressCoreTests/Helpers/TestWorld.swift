import SteamPressCore
import Vapor

struct TestWorld {

    static func create(
        path: String? = nil,
        postsPerPage: Int = 10,
        feedInformation: FeedInformation = FeedInformation(),
        enableAuthorPages: Bool = true,
        enableTagPages: Bool = true,
        passwordHasherToUse: PasswordHasherChoice = .plaintext,
        randomNumberGenerator: StubbedRandomNumberGenerator = StubbedRandomNumberGenerator(numberToReturn: 666),
        url: String = "https://www.steampress.io"
    ) throws -> TestWorld {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let application = TestWorld.getSteamPressApp(
            eventLoopGroup: eventLoopGroup,
            path: path,
            postsPerPage: postsPerPage,
            feedInformation: feedInformation,
            enableAuthorPages: enableAuthorPages,
            enableTagPages: enableTagPages,
            passwordHasherToUse: passwordHasherToUse,
            randomNumberGenerator: randomNumberGenerator
        )
        let req = Request(application: application, on: eventLoopGroup.next())
        let context = Context(
            app: application,
            req: req,
            path: path,
            eventLoopGroup: eventLoopGroup
        )
        unsetenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER")
        unsetenv("BLOG_SITE_TWITTER_HANDLE")
        unsetenv("BLOG_DISQUS_NAME")
        unsetenv("SP_WEBSITE_URL")
        setenv("SP_WEBSITE_URL", url, 1)
        setenv("SP_BLOG_PATH", "blog", 1)
        try application.boot()
        return TestWorld(context: context)
    }

    let context: Context

    init(context: Context) {
        self.context = context
    }

    struct Context {
        let app: Application
        let req: Request
        let path: String?
        let eventLoopGroup: EventLoopGroup
    }
    
    func shutdown() throws {
        context.app.shutdown()
        try context.eventLoopGroup.syncShutdownGracefully()
    }
}
