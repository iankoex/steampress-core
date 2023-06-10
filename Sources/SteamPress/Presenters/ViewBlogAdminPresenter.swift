import Vapor

public struct ViewBlogAdminPresenter: BlogAdminPresenter {
    
    let pathCreator: BlogPathCreator
    let viewRenderer: ViewRenderer
    let longDateFormatter: LongPostDateFormatter
    let numericDateFormatter: NumericPostDateFormatter
    
    public func createIndexView(posts: [BlogPost], users: [BlogUser.Public], errors: [String]?, site: GlobalWebsiteInformation) async throws -> View {
        let publishedPosts = try posts.filter { $0.published }.convertToViewBlogPostsWithoutTags(authors: users, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
        let draftPosts = try posts.filter { !$0.published }.convertToViewBlogPostsWithoutTags(authors: users, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
        let context = AdminPageContext(errors: errors, publishedPosts: publishedPosts, draftPosts: draftPosts, users: users, site: site)
        return try await viewRenderer.render("blog/admin/index", context)
    }
    
    public func createPostView(errors: [String]?, title: String?, contents: String?, slugURL: String?, tags: [String], isEditing: Bool, post: BlogPost?, isDraft: Bool?, titleError: Bool, contentsError: Bool, site: GlobalWebsiteInformation) async throws -> View {
        if isEditing {
            guard post != nil else {
                throw SteamPressError(identifier: "ViewBlogAdminPresenter", "Blog Post is empty whilst editing")
            }
        }
        let postPathSuffix = pathCreator.createPath(for: "posts")
        let postPathPrefix = site.url.appending(postPathSuffix)
        let pageTitle = isEditing ? "Edit Blog Post" : "Create Blog Post"
        let context = CreatePostPageContext(title: pageTitle, editing: isEditing, post: post, draft: isDraft ?? false, errors: errors, titleSupplied: title, contentsSupplied: contents, tagsSupplied: tags, slugURLSupplied: slugURL, titleError: titleError, contentsError: contentsError, postPathPrefix: postPathPrefix, site: site)
        return try await viewRenderer.render("blog/admin/createPost", context)
    }
    
    public func createUserView(editing: Bool, errors: [String]?, name: String?, nameError: Bool, username: String?, usernameErorr: Bool, passwordError: Bool, confirmPasswordError: Bool, resetPasswordOnLogin: Bool, userID: UUID?, profilePicture: String?, twitterHandle: String?, biography: String?, tagline: String?, site: GlobalWebsiteInformation) async throws -> View {
        if editing {
            guard userID != nil else {
                throw SteamPressError(identifier: "ViewBlogAdminPresenter", "User ID is nil whilst editing")
            }
        }
        
        let context = CreateUserPageContext(editing: editing, errors: errors, nameSupplied: name, nameError: nameError, usernameSupplied: username, usernameError: usernameErorr, passwordError: passwordError, confirmPasswordError: confirmPasswordError, resetPasswordOnLoginSupplied: resetPasswordOnLogin, userID: userID, twitterHandleSupplied: twitterHandle, profilePictureSupplied: profilePicture, biographySupplied: biography, taglineSupplied: tagline, site: site)
        return try await viewRenderer.render("blog/admin/createUser", context)
    }
    
    public func createResetPasswordView(errors: [String]?, passwordError: Bool?, confirmPasswordError: Bool?, site: GlobalWebsiteInformation) async throws -> View {
        let context = ResetPasswordPageContext(errors: errors, passwordError: passwordError, confirmPasswordError: confirmPasswordError, site: site)
        return try await viewRenderer.render("blog/admin/resetPassword", context)
    }
}
