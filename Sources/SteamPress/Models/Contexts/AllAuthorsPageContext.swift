struct AllAuthorsPageContext: Encodable {
    let website: GlobalWebsiteInformation
    let authors: [ViewBlogAuthor]
}
