struct AllTagsPageContext: Encodable {
    let title: String
    let tags: [BlogTagWithPostCount]
    let website: GlobalWebsiteInformation
}
