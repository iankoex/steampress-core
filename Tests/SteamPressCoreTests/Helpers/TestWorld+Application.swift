@testable import SteamPressCore
import Vapor
import Fluent
import FluentSQLiteDriver

extension TestWorld {
    static func getSteamPressApp(
        eventLoopGroup: EventLoopGroup,
        path: String?,
        postsPerPage: Int,
        feedInformation: FeedInformation,
        enableAuthorPages: Bool,
        enableTagPages: Bool,
        passwordHasherToUse: PasswordHasherChoice,
        randomNumberGenerator: StubbedRandomNumberGenerator
    ) -> Application {
        
        let application = Application(.testing, .shared(eventLoopGroup))
        
        application.databases.use(.sqlite(.memory), as: .sqlite, isDefault: true)
        
        let steamPressConfig = SteamPressConfiguration(feedInformation: feedInformation, postsPerPage: postsPerPage, enableAuthorPages: enableAuthorPages, enableTagPages: enableTagPages)
        let steamPressLifecycle = SteamPressLifecycleHandler(configuration: steamPressConfig)
        application.lifecycle.use(steamPressLifecycle)
        
        application.steampress.application.repositories.register(.blogPost) { req in
            InMemoryRepository(req)
        }
        
        application.steampress.application.repositories.register(.blogTag) { req in
            InMemoryRepository(req)
        }
        
        application.steampress.application.repositories.register(.blogUser) { req in
            InMemoryRepository(req)
        }

//        application.steampress.randomNumberGenerators.use { _ in randomNumberGenerator }
//
//        application.middleware.use(BlogRememberMeMiddleware())
//        application.middleware.use(SessionsMiddleware(session: application.sessions.driver))

        application.steampress.application.presenters.register(.blog) { req in
            CapturingBlogPresenter(req)
        }
        application.steampress.application.presenters.register(.admin) { req in
            CapturingAdminPresenter(req)
        }

        switch passwordHasherToUse {
            case .real:
                application.passwords.use(.bcrypt)
            case .plaintext:
                application.passwords.use(.plaintext)
            case .reversed:
                application.passwords.use(.reversed)
        }

        return application
    }
}
