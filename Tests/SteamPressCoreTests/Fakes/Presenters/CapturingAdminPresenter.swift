@testable import SteamPressCore
import Vapor

class CapturingAdminPresenter: BlogAdminPresenter {
    
    required init(_ req: Request) {
        
    }
    
    func `for`(_ request: Request) -> BlogAdminPresenter {
        return self
    }
    
    // MARK: - BlogPresenter
    
    static private(set) var indexViewUsersCount: Int?
    static private(set) var indexViewErrors: [String]?
    static private(set) var indexViewSite: GlobalWebsiteInformation?
    func createIndexView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View {
        CapturingAdminPresenter.indexViewUsersCount = usersCount
        CapturingAdminPresenter.indexViewErrors = errors
        CapturingAdminPresenter.indexViewSite = site
        return TestDataBuilder.createView()
    }
    
    static private(set) var exploreViewUsersCount: Int?
    static private(set) var exploreViewErrors: [String]?
    static private(set) var exploreViewSite: GlobalWebsiteInformation?
    func createExploreView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View {
        CapturingAdminPresenter.exploreViewUsersCount = usersCount
        CapturingAdminPresenter.exploreViewErrors = errors
        CapturingAdminPresenter.exploreViewSite = site
        return TestDataBuilder.createView()
    }
    
    static private(set) var pagesViewUsersCount: Int?
    static private(set) var pagesViewErrors: [String]?
    static private(set) var pagesViewSite: GlobalWebsiteInformation?
    func createPagesView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View {
        CapturingAdminPresenter.pagesViewUsersCount = usersCount
        CapturingAdminPresenter.pagesViewErrors = errors
        CapturingAdminPresenter.pagesViewSite = site
        return TestDataBuilder.createView()
    }
    
    static private(set) var createTagsViewTags: [BlogTag]?
    static private(set) var createTagsViewSite: GlobalWebsiteInformation?
    static private(set) var createTagsViewUsersCount: Int?
    func createTagsView(tags: [BlogTag], usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        CapturingAdminPresenter.createTagsViewTags = tags
        CapturingAdminPresenter.createTagsViewUsersCount = usersCount
        CapturingAdminPresenter.createTagsViewSite = site
        return TestDataBuilder.createView()
    }
    
    static private(set) var createCreateTagsViewErrors: [String]?
    static private(set) var createCreateTagsViewSite: GlobalWebsiteInformation?
    static private(set) var createCreateTagsViewUsersCount: Int?
    func createCreateTagView(errors: [String]?, usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        CapturingAdminPresenter.createCreateTagsViewErrors = errors
        CapturingAdminPresenter.createCreateTagsViewUsersCount = usersCount
        CapturingAdminPresenter.createCreateTagsViewSite = site
        return TestDataBuilder.createView()
    }
    
    func createEditTagView(tag: BlogTag, usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        
        return TestDataBuilder.createView()
    }
    
    func createPostsView(posts: [BlogPost], usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        return TestDataBuilder.createView()
    }
    
    func createPostView(errors: [String]?, tags: [BlogTag], post: BlogPost?, titleSupplied: String?, contentSupplied: String?, snippetSupplied: String?, site: GlobalWebsiteInformation) async throws -> View {
        return TestDataBuilder.createView()
    }
    
    static private(set) var resetPasswordErrors: [String]?
    static private(set) var resetPasswordsite: GlobalWebsiteInformation?
    func createResetPasswordView(errors: [String]?, site: GlobalWebsiteInformation) async throws -> View {
        CapturingAdminPresenter.resetPasswordsite = site
        CapturingAdminPresenter.resetPasswordErrors = errors
        return TestDataBuilder.createView()
    }
    
    static private(set) var loginWarning: Bool?
    static private(set) var loginErrors: [String]?
    static private(set) var loginEmail: String?
    static private(set) var loginsite: GlobalWebsiteInformation?
    static private(set) var loginPageRememberMe: Bool?
    func loginView(loginWarning: Bool, errors: [String]?, email: String?, rememberMe: Bool, requireName: Bool, site: GlobalWebsiteInformation) async throws -> View {
        CapturingAdminPresenter.loginWarning = loginWarning
        CapturingAdminPresenter.loginErrors = errors
        CapturingAdminPresenter.loginEmail = email
        CapturingAdminPresenter.loginsite = site
        CapturingAdminPresenter.loginPageRememberMe = rememberMe
        return TestDataBuilder.createView()
    }
    
    static private(set) var createMembersViewUsers: [BlogUser.Public]?
    static private(set) var createMembersViewSite: GlobalWebsiteInformation?
    static private(set) var createMembersViewUsersCount: Int?
    func createMembersView(users: [BlogUser.Public], usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        CapturingAdminPresenter.createMembersViewUsers = users
        CapturingAdminPresenter.createMembersViewSite = site
        CapturingAdminPresenter.createMembersViewUsersCount = usersCount
        return TestDataBuilder.createView()
    }
    
    static private(set) var createCreateMembersViewUserData: CreateUserData?
    static private(set) var createCreateMembersViewUsersCount: Int?
    static private(set) var createCreateMembersViewErrors: [String]?
    static private(set) var createCreateMembersViewSite: GlobalWebsiteInformation?
    func createCreateMemberView(userData: CreateUserData?, errors: [String]?, usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        CapturingAdminPresenter.createCreateMembersViewUserData = userData
        CapturingAdminPresenter.createCreateMembersViewUsersCount = usersCount
        CapturingAdminPresenter.createCreateMembersViewErrors = errors
        CapturingAdminPresenter.createCreateMembersViewSite = site
        return TestDataBuilder.createView()
    }
}
