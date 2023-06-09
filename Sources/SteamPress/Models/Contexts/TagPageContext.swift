struct TagPageContext: Encodable {
    let tag: BlogTag
    let website: GlobalWebsiteInformation
    let posts: [ViewBlogPost]
    let tagPage = true
    let postCount: Int
    let paginationTagInformation: PaginationTagInformation
}
