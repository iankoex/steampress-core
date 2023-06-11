@testable import SteamPressCore
import Vapor

extension TestWorld {
    static func getSteamPressApp(
        eventLoopGroup: EventLoopGroup,
        repository: InMemoryRepository,
        path: String?,
        postsPerPage: Int,
        feedInformation: FeedInformation,
        blogPresenter: CapturingBlogPresenter,
        adminPresenter: CapturingAdminPresenter,
        enableAuthorPages: Bool,
        enableTagPages: Bool,
        passwordHasherToUse: PasswordHasherChoice,
        randomNumberGenerator: StubbedRandomNumberGenerator
    ) -> Application {
        
        let application = Application(.testing, .shared(eventLoopGroup))
        
        application.steampress.configuration = SteamPressConfiguration(blogPath: path, feedInformation: feedInformation, postsPerPage: postsPerPage, enableAuthorPages: enableAuthorPages, enableTagPages: enableTagPages)
        
        application.repositories.register(.blogPost) { req in
            repository
        }
        
        application.repositories.register(.blogTag) { req in
            repository
        }
        
        application.repositories.register(.blogUser) { req in
            repository
        }

        application.steampress.randomNumberGenerators.use { _ in randomNumberGenerator }

        application.middleware.use(BlogRememberMeMiddleware())
        application.middleware.use(SessionsMiddleware(session: application.sessions.driver))

        application.steampress.blogPresenters.use { _ in
            return blogPresenter
        }
        application.steampress.adminPresenters.use { _ in
            return adminPresenter
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
