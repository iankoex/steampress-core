struct AuthorPageContext: Encodable {
    let author: BlogUser.Public
    let posts: [ViewBlogPost]
    let pageInformation: BlogGlobalPageInformation
    let myProfile: Bool
    let profilePage = true
    let postCount: Int
    let paginationTagInformation: PaginationTagInformation
}
