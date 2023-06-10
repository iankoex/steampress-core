struct SearchPageContext: Encodable {
    let title = "Search Blog"
    let searchTerm: String?
    let posts: [ViewBlogPost]
    let totalResults: Int
    let site: GlobalWebsiteInformation
    let paginationTagInformation: PaginationTagInformation
}
