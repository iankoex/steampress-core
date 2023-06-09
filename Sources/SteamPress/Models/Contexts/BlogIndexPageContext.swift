struct BlogIndexPageContext: Encodable {
    let posts: [ViewBlogPost]
    let tags: [ViewBlogTag]
    let authors: [BlogUser.Public]
    let website: GlobalWebsiteInformation
    let title = "Blog"
    let blogIndexPage = true
    let paginationTagInformation: PaginationTagInformation
}
