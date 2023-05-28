import Vapor

protocol BlogAdminPresenter {
    func `for`(_ request: Request, pathCreator: BlogPathCreator) -> BlogAdminPresenter
    func createIndexView(posts: [BlogPost], users: [BlogUser], errors: [String]?, pageInformation: BlogAdminPageInformation) async throws -> View
    func createPostView(errors: [String]?, title: String?, contents: String?, slugURL: String?, tags: [String]?, isEditing: Bool, post: BlogPost?, isDraft: Bool?, titleError: Bool, contentsError: Bool, pageInformation: BlogAdminPageInformation) async throws -> View
    func createUserView(editing: Bool, errors: [String]?, name: String?, nameError: Bool, username: String?, usernameErorr: Bool, passwordError: Bool, confirmPasswordError: Bool, resetPasswordOnLogin: Bool, userID: UUID?, profilePicture: String?, twitterHandle: String?, biography: String?, tagline: String?, pageInformation: BlogAdminPageInformation) async throws -> View
    func createResetPasswordView(errors: [String]?, passwordError: Bool?, confirmPasswordError: Bool?, pageInformation: BlogAdminPageInformation) async throws -> View
}

extension ViewBlogAdminPresenter {
    func `for`(_ request: Request, pathCreator: BlogPathCreator) -> BlogAdminPresenter {
        return ViewBlogAdminPresenter(pathCreator: pathCreator, viewRenderer: request.view, longDateFormatter: LongPostDateFormatter(), numericDateFormatter: NumericPostDateFormatter())
    }
}
