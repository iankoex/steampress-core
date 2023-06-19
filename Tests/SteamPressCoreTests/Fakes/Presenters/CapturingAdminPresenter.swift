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
    
    func createResetPasswordView(errors: [String]?, site: GlobalWebsiteInformation) async throws -> View {
        return TestDataBuilder.createView()
    }
    
    private(set) var loginWarning: Bool?
    private(set) var loginErrors: [String]?
    private(set) var loginEmail: String?
    private(set) var loginsite: GlobalWebsiteInformation?
    private(set) var loginPageRememberMe: Bool?
    func loginView(loginWarning: Bool, errors: [String]?, email: String?, rememberMe: Bool, requireName: Bool, site: GlobalWebsiteInformation) async throws -> View {
        self.loginWarning = loginWarning
        self.loginErrors = errors
        self.loginEmail = email
        self.loginsite = site
        self.loginPageRememberMe = rememberMe
        return TestDataBuilder.createView()
    }
    
    func createMembersView(users: [BlogUser.Public], usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        return TestDataBuilder.createView()
    }
    
    func createCreateMemberView(userData: CreateUserData?, errors: [String]?, usersCount: Int, site: GlobalWebsiteInformation) async throws -> View {
        return TestDataBuilder.createView()
    }
    
//    private(set) var createPostErrors: [String]?
//    private(set) var createPostTitle: String?
//    private(set) var createPostContents: String?
//    private(set) var createPostTags: [String]?
//    private(set) var createPostIsEditing: Bool?
//    private(set) var createPostPost: BlogPost?
//    private(set) var createPostDraft: Bool?
//    private(set) var createPostSlugURL: String?
//    private(set) var createPostTitleError: Bool?
//    private(set) var createPostContentsError: Bool?
//    private(set) var createPostsite: GlobalWebsiteInformation?
//    func createPostView(errors: [String]?, title: String?, contents: String?, slugURL: String?, tags: [String]?, isEditing: Bool, post: BlogPost?, isDraft: Bool?, titleError: Bool, contentsError: Bool, site: GlobalWebsiteInformation) -> View {
//        self.createPostErrors = errors
//        self.createPostTitle = title
//        self.createPostContents = contents
//        self.createPostSlugURL = slugURL
//        self.createPostTags = tags
//        self.createPostIsEditing = isEditing
//        self.createPostPost = post
//        self.createPostDraft = isDraft
//        self.createPostTitleError = titleError
//        self.createPostContentsError = contentsError
//        self.createPostsite = site
//        return TestDataBuilder.createView()
//    }
//
//    private(set) var createUserErrors: [String]?
//    private(set) var createUserName: String?
//    private(set) var createUserUsername: String?
//    private(set) var createUserPasswordError: Bool?
//    private(set) var createUserConfirmPasswordError: Bool?
//    private(set) var createUserResetPasswordRequired: Bool?
//    private(set) var createUserUserID: UUID?
//    private(set) var createUserProfilePicture: String?
//    private(set) var createUserTwitterHandle: String?
//    private(set) var createUserBiography: String?
//    private(set) var createUserTagline: String?
//    private(set) var createUserEditing: Bool?
//    private(set) var createUserNameError: Bool?
//    private(set) var createUserUsernameError: Bool?
//    func createUserView(editing: Bool, errors: [String]?, name: String?, nameError: Bool, username: String?, usernameErorr: Bool, passwordError: Bool, confirmPasswordError: Bool, resetPasswordOnLogin: Bool, userID: UUID?, profilePicture: String?, twitterHandle: String?, biography: String?, tagline: String?, site: GlobalWebsiteInformation) -> View {
//        self.createUserEditing = editing
//        self.createUserErrors = errors
//        self.createUserName = name
//        self.createUserUsername = username
//        self.createUserPasswordError = passwordError
//        self.createUserConfirmPasswordError = confirmPasswordError
//        self.createUserUserID = userID
//        self.createUserProfilePicture = profilePicture
//        self.createUserTwitterHandle = twitterHandle
//        self.createUserBiography = biography
//        self.createUserTagline = tagline
//        self.createUserNameError = nameError
//        self.createUserUsernameError = usernameErorr
//        self.createUserResetPasswordRequired = resetPasswordOnLogin
//        return TestDataBuilder.createView()
//    }
//
//    private(set) var resetPasswordErrors: [String]?
//    private(set) var resetPasswordError: Bool?
//    private(set) var resetPasswordConfirmError: Bool?
//    private(set) var resetPasswordsite: GlobalWebsiteInformation?
//    func createResetPasswordView(errors: [String]?, passwordError: Bool?, confirmPasswordError: Bool?, site: GlobalWebsiteInformation) -> View {
//        self.resetPasswordErrors = errors
//        self.resetPasswordError = passwordError
//        self.resetPasswordConfirmError = confirmPasswordError
//        self.resetPasswordsite = site
//        return TestDataBuilder.createView()
//    }
}
