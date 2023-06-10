import Vapor

protocol BlogAdminPresenter {
    func `for`(_ request: Request, pathCreator: BlogPathCreator) -> BlogAdminPresenter
    func createIndexView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View
    func createExploreView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View
    func createPagesView(usersCount: Int, errors: [String]?, site: GlobalWebsiteInformation) async throws -> View
    func createPostsView(posts: [BlogPost], usersCount: Int, site: GlobalWebsiteInformation) async throws -> View
    func createPostView(errors: [String]?, title: String?, contents: String?, slugURL: String?, tags: [String], isEditing: Bool, post: BlogPost?, isDraft: Bool?, titleError: Bool, contentsError: Bool, site: GlobalWebsiteInformation) async throws -> View
    func createUserView(editing: Bool, errors: [String]?, name: String?, nameError: Bool, username: String?, usernameErorr: Bool, passwordError: Bool, confirmPasswordError: Bool, resetPasswordOnLogin: Bool, userID: UUID?, profilePicture: String?, twitterHandle: String?, biography: String?, tagline: String?, site: GlobalWebsiteInformation) async throws -> View
    func createResetPasswordView(errors: [String]?, passwordError: Bool?, confirmPasswordError: Bool?, site: GlobalWebsiteInformation) async throws -> View
}

extension ViewBlogAdminPresenter {
    func `for`(_ request: Request, pathCreator: BlogPathCreator) -> BlogAdminPresenter {
        return ViewBlogAdminPresenter(pathCreator: pathCreator, viewRenderer: request.view)
    }
}
