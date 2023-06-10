struct AdminPageContext: Encodable {
    let errors: [String]?
    let publishedPosts: [ViewBlogPostWithoutTags]
    let draftPosts: [ViewBlogPostWithoutTags]
    let users: [BlogUser.Public]
    let site: GlobalWebsiteInformation
    let blogAdminPage = true
    let title = "Blog Admin"
}
