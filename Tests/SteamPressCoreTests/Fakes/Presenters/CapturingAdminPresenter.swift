@testable import SteamPressCore
import Vapor

class CapturingAdminPresenter: BlogAdminPresenter {
    
    private(set) var adminViewErrors: [String]?
    private(set) var usersCount: Int
    private(set) var adminViewsite: GlobalWebsiteInformation?
    private(set) var adminViewTags: [BlogTag]
    
    required init(_ req: Request) {
        usersCount = 0
        adminViewTags = []
    }
    
    func `for`(_ request: Request) -> BlogAdminPresenter {
        return self
    }
    
    // MARK: - BlogPresenter
    
    func createIndexView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View {
        self.usersCount = usersCount
        self.adminViewErrors = errors
        self.adminViewsite = site
        return TestDataBuilder.createView()
    }
    
    func createExploreView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View {
        self.usersCount = usersCount
        self.adminViewErrors = errors
        self.adminViewsite = site
        return TestDataBuilder.createView()
    }
    
    func createPagesView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View {
        self.usersCount = usersCount
        self.adminViewErrors = errors
        self.adminViewsite = site
        return TestDataBuilder.createView()
    }
    
    
    func createTagsView(tags: [BlogTag], usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        self.usersCount = usersCount
        self.adminViewTags = tags
        self.adminViewsite = site
        return TestDataBuilder.createView()
    }
    
    func createCreateTagView(usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        self.usersCount = usersCount
        self.adminViewsite = site
        return TestDataBuilder.createView()
    }
    
    func createEditTagView(tag: BlogTag, usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        self.usersCount = usersCount
        self.adminViewsite = site
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
