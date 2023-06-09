struct BlogPostPageContext: Encodable {
    let title: String
    let post: ViewBlogPost
    let author: BlogUser.Public
    let blogPostPage = true
    let website: GlobalWebsiteInformation
}
