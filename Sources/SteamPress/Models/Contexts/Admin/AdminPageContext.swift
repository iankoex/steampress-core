struct AdminPageContext: Encodable {
    let errors: [String]?
    let publishedPosts: [ViewBlogPostWithoutTags]
    let draftPosts: [ViewBlogPostWithoutTags]
    let users: [BlogUser.Public]
    let website: GlobalWebsiteInformation
    let blogAdminPage = true
    let title = "Blog Admin"
}
