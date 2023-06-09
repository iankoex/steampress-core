import Vapor
import SwiftSoup
import SwiftMarkdown

public struct ViewBlogPresenter: BlogPresenter {
    let viewRenderer: ViewRenderer
    let longDateFormatter: LongPostDateFormatter
    let numericDateFormatter: NumericPostDateFormatter

    public func indexView(posts: [BlogPost], tags: [BlogTag], authors: [BlogUser.Public], tagsForPosts: [UUID: [BlogTag]], website: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View {
        let viewPosts = try posts.convertToViewBlogPosts(authors: authors, tagsForPosts: tagsForPosts, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
        let viewTags = try tags.map { try $0.toViewBlogTag() }
        let context = BlogIndexPageContext(posts: viewPosts, tags: viewTags, authors: authors, website: website, paginationTagInformation: paginationTagInfo)
        return try await viewRenderer.render("blog/index", context)
    }

    public func postView(post: BlogPost, author: BlogUser.Public, tags: [BlogTag], website: GlobalWebsiteInformation) async throws -> View {
        let viewPost = try post.toViewPost(authorName: author.name, authorUsername: author.username, longFormatter: longDateFormatter, numericFormatter: numericDateFormatter, tags: tags)
        
        let context = BlogPostPageContext(title: post.title, post: viewPost, author: author, website: website)
        return try await viewRenderer.render("blog/post", context)
    }

    public func allAuthorsView(authors: [BlogUser.Public], authorPostCounts: [UUID: Int], website: GlobalWebsiteInformation) async throws -> View {
        var viewAuthors = try authors.map { user -> ViewBlogAuthor in
            guard let userID = user.id else {
                throw SteamPressError(identifier: "ViewBlogPresenter", "User ID Was Not Set")
            }
            return ViewBlogAuthor(userID: userID, name: user.name, username: user.username, profilePicture: user.profilePicture, twitterHandle: user.twitterHandle, biography: user.biography, tagline: user.tagline, postCount: authorPostCounts[userID] ?? 0)
            
        }
        viewAuthors.sort { $0.postCount > $1.postCount }
        let context = AllAuthorsPageContext(website: website, authors: viewAuthors)
        return try await viewRenderer.render("blog/authors", context)
    }

    public func authorView(author: BlogUser.Public, posts: [BlogPost], postCount: Int, tagsForPosts: [UUID: [BlogTag]], website: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View {
        let myProfile: Bool
        if let loggedInUser = website.loggedInUser {
            myProfile = loggedInUser.id == author.id
        } else {
            myProfile = false
        }
        let viewPosts = try posts.convertToViewBlogPosts(authors: [author], tagsForPosts: tagsForPosts, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
        let context = AuthorPageContext(author: author, posts: viewPosts, website: website, myProfile: myProfile, postCount: postCount, paginationTagInformation: paginationTagInfo)
        return try await viewRenderer.render("blog/profile", context)
    }

    public func allTagsView(tags: [BlogTag], tagPostCounts: [UUID: Int], website: GlobalWebsiteInformation) async throws -> View {
        var viewTags = try tags.map { tag -> BlogTagWithPostCount in
            guard let tagID = tag.id else {
                throw SteamPressError(identifier: "ViewBlogPresenter", "Tag ID Was Not Set")
            }
            guard let urlEncodedName = tag.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                throw SteamPressError(identifier: "ViewBlogPresenter", "Failed to URL encoded tag name")
            }
            return BlogTagWithPostCount(id: tagID, name: tag.name, postCount: tagPostCounts[tagID] ?? 0, urlEncodedName: urlEncodedName)
        }
        viewTags.sort { $0.postCount > $1.postCount }
        let context = AllTagsPageContext(title: "All Tags", tags: viewTags, website: website)
        return try await viewRenderer.render("blog/tags", context)
    }

    public func tagView(tag: BlogTag, posts: [BlogPost], authors: [BlogUser.Public], totalPosts: Int, website: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View {
        let tagsForPosts = try posts.reduce(into: [UUID: [BlogTag]]()) { dict, blog in
            guard let blogID = blog.id else {
                throw SteamPressError(identifier: "ViewBlogPresenter", "Blog has no ID set")
            }
            dict[blogID] = [tag]
        }
        
        let viewPosts = try posts.convertToViewBlogPosts(authors: authors, tagsForPosts: tagsForPosts, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
        let context = TagPageContext(tag: tag, website: website, posts: viewPosts, postCount: totalPosts, paginationTagInformation: paginationTagInfo)
        return try await viewRenderer.render("blog/tag", context)
    }

    public func searchView(totalResults: Int, posts: [BlogPost], authors: [BlogUser.Public], searchTerm: String?, tagsForPosts: [UUID: [BlogTag]], website: GlobalWebsiteInformation, paginationTagInfo: PaginationTagInformation) async throws -> View {
        let viewPosts = try posts.convertToViewBlogPosts(authors: authors, tagsForPosts: tagsForPosts, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
        let context = SearchPageContext(searchTerm: searchTerm, posts: viewPosts, totalResults: totalResults, website: website, paginationTagInformation: paginationTagInfo)
        return try await viewRenderer.render("blog/search", context)
    }

    public func loginView(loginWarning: Bool, errors: [String]?, username: String?, usernameError: Bool, passwordError: Bool, rememberMe: Bool, website: GlobalWebsiteInformation) async throws -> View {
        let context = LoginPageContext(errors: errors, loginWarning: loginWarning, username: username, usernameError: usernameError, passwordError: passwordError, rememberMe: rememberMe, website: website)
        return try await viewRenderer.render("blog/admin/login", context)
    }
    
}
