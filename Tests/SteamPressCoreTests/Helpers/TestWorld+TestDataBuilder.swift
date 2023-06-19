import SteamPressCore
import Foundation

extension TestWorld {
    func createPost(tags: [String]? = nil, createdDate: Date? = nil, title: String = "An Exciting Post!", contents: String = "This is a blog post", slugURL: String = "an-exciting-post", author: BlogUser? = nil, published: Bool = true) async throws -> TestData {
        return try await TestDataBuilder.createPost(on: self.context.req, tags: tags, createdDate: createdDate, title: title, contents: contents, slugURL: slugURL, author: author, published: published)
    }

    func createPosts(count: Int, author: BlogUser, tag: BlogTag? = nil) async throws {
        for index in 1...count {
            let data = try await createPost(title: "Post \(index)", slugURL: "post-\(index)", author: author)
            if let tag = tag {
                try await context.req.repositories.blogTag.add(tag, to: data.post)
            }
        }
    }

    func createUser(name: String = "Luke", username: String = "luke", password: String = "password", resetPasswordRequired: Bool = false) async throws -> BlogUser {
        let user = TestDataBuilder.anyUser(name: name, username: username, password: password)
        try await self.context.req.repositories.blogUser.save(user)
        if resetPasswordRequired {
            user.resetPasswordRequired = true
        }
        return user
    }

    func createTag(_ name: String = "Engineering") async throws -> BlogTag {
        let tag = BlogTag(name: name, visibility: .public)
        try await self.context.req.repositories.blogTag.save(tag)
        return tag
    }

    func createTag(_ name: String = "Engineering", on post: BlogPost) async throws -> BlogTag {
        let tag = try await createTag(name)
        try await self.context.req.repositories.blogTag.add(tag, to: post)
        return tag
    }
}
