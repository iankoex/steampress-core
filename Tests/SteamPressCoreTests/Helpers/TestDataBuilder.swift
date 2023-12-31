import Foundation
@testable import SteamPressCore
import Vapor

struct TestDataBuilder {

    static let longContents = "Welcome to SteamPress!\n\nSteamPress started out as an idea - after all, I was porting sites and backends over to Swift and would like to have a blog as well. Being early days for Server-Side Swift, and embracing Vapor, there wasn't anything available to put a blog on my site, so I did what any self-respecting engineer would do - I made one! Besides, what better way to learn a framework than build a blog!\n\nI plan to put some more posts up going into how I actually wrote SteamPress, going into some Vapor basics like Authentication and other popular #help topics on [Slack](qutheory.slack.com) (I probably need to rewrite a lot of it properly first!) either on here or on https://geeks.brokenhands.io, which will be the engineering site for Broken Hands, which is what a lot of future projects I have planned will be under. \n\n![SteamPress Logo](https://user-images.githubusercontent.com/9938337/29742058-ed41dcc0-8a6f-11e7-9cfc-680501cdfb97.png)\n\n This however requires DynamoDB integration with Vapor (which the Swift SDK work has been started [here](https://github.com/brokenhandsio/AWSwift)) as that is what I use for most of my DB usage (it's cheap, I don't have to manage any DB servers etc and I can tear down/scale web servers and the DB will scale in parallel without me having to do anything). But I digress...\n\n# Usage\n\nI designed SteamPress to be as easy to integrate as possible. Full details can be found in the [repo](https://github.com/brokenhandsio/SteamPress/blob/master/README.md) but as an overview:\n\nYou need to add it as a dependency in your `Package.swift`:\n\n```swift\ndependencies: [\n...,\n.Package(url: \"https://github.com/brokenhandsio/SteamPress\", majorVersion: 0, minor: 1)\n]\n```\n\nNext import it at the top of your `main.swift` (or wherever you link it in):\n\n```swift\nimport SteamPressCore\n```\n\nFinally initialise it:\n\n```swift\nlet steamPress = SteamPress(drop: drop)\n```\n\nThat’s it! You can then blog away to your hearts content. Note that the first time you access the login page it will create a `admin` user for you, and print the credentials out (you need to restart the Heroku app at this point to flush the logs for some reason if you are trying to run on Heroku)\n\nYou also need to link up all the expected templates, so see the [`README`](https://github.com/brokenhandsio/SteamPress/blob/master/README.md) for that, or look at the [Example Site](https://github.com/brokenhandsio/SteamPressExample) - this code that powers this site!\n\n# Features\n\nOne of the reasons for writing this post is to show off some of the features of SteamPress! As you can see, we have blog posts (obviously!), multiple users for the blog and you can tag blog posts with different labels to help categorise posts. Currently (especially in the example site), the list of users, labels etc isn’t particularly functional but it will be expanded over time. We also have pagination for large number of posts.\n\nThere are also some hidden features that prove useful. You can write posts in markdown and then use the [Markdown Provider](https://github.com/vapor-community/markdown-provider) to easily format your posts. Combine it with some syntax highlighting (I use [http://prismjs.com](http://prismjs.com) on this site and you can easily write code and have it highlighted for you, as soon above. Great for technical blogs especially!\n\n# Roadmap\n\nCurrently I have released SteamPress under version 0 as I expect there to be some significant, most probably breaking, changes coming up to add better functionality. Among these include comments (probably just using [Disqus](https://disqus.com)) and making the site a bit easier and nicer to use with some Javascript to do things like form validation and making the labels UI a bit better. Also it would be nice to improve the experience of writing posts (some sort of preview function?), as well as things like AMP and generally tidying the code up! Also, the site desperately needs some UI love!\n\nOther things include:\n\n* Proper testing!\n* Remember Me functionality for logging in\n* Slug URL for posts - helps SEO and makes life a bit easier!\n* Image uploading\n* Blog drafts\n* Sitemap/RSS feed - again for SEO\n* Searching through the blog\n\nIf you have any ideas, find any bugs or any questions, just create an issue in Github for either the [main engine](https://github.com/brokenhandsio/SteamPress/issues) or the [example site](https://github.com/brokenhandsio/SteamPressExample/issues).\n\nHappy blogging!\n\nTim\n"

    static func anyUser(id: UUID? = UUID(), name: String = "Luke", username: String = "luke", password: String = "password", email: String = "like@skywalker.com", type: BlogUser.BlogUserType = .owner) -> BlogUser {
        return BlogUser(id: id, name: name, username: username, email: email, password: password, type: type, profilePicture: "https://static.brokenhands.io/steampress/images/authors/luke.png", twitterHandle: "luke", biography: "The last Jedi", tagline: "Who is my father")
    }

    static func anyPost(author: BlogUser, title: String = "An Exciting Post!", contents: String = "This is a blog post", slugURL: String = "some-exciting-title", creationDate: Date = Date(), published: Bool = true, lastEditedDate: Date? = nil, imageURL: String =  "https://static.brokenhands.io/steampress/images/authors/luke.png", imageAlt: String = "Image Alt", snippet: String = "This is") throws -> BlogPost {
        let blogPost = BlogPost(
            title: title,
            contents: contents,
            authorID: author.id ?? UUID(),
            slugURL: slugURL,
            published: published,
            imageURL: imageURL,
            imageAlt: imageAlt,
            snippet: snippet,
            creationDate: creationDate
        )
        if let lastEdited = lastEditedDate {
            blogPost.lastEdited = lastEdited
        }
        return blogPost
    }
    
    static func anyTag(name: String = "Engineering", visibility: BlogTag.TagVisibility = .public) -> BlogTag {
        BlogTag(name: name, visibility: visibility, slugURL: BlogTag.generateUniqueSlugURL(from: name))
    }

    static func createPost(on req: Request, tags: [BlogTag]? = nil, createdDate: Date? = nil, title: String = "An Exciting Post!", contents: String = "This is a blog post", slugURL: String = "an-exciting-post", author: BlogUser? = nil, published: Bool = true) async throws -> TestData {
        let postAuthor: BlogUser
        if let author = author {
            postAuthor = author
        } else {
            if let existingUser = req.auth.get(BlogUser.self) {
                postAuthor = existingUser
            } else {
                postAuthor = TestDataBuilder.anyUser()
                try await req.repositories.blogUser.save(postAuthor)
            }
        }

        let post: BlogPost
        post = try TestDataBuilder.anyPost(author: postAuthor, title: title, contents: contents, slugURL: slugURL, creationDate: createdDate ?? Date(), published: published)

        try await req.repositories.blogPost.save(post)

        let blogTag: BlogTag
        if let tags = tags {
            blogTag = tags.first!
            for tag in tags {
                try await req.repositories.blogTag.add(tag, to: post)
            }
        } else {
            let tag = TestDataBuilder.anyTag()
            try await req.repositories.blogTag.save(tag)
            try await req.repositories.blogTag.add(tag, to: post)
            blogTag = tag
        }

        return TestData(post: post, author: postAuthor, tag: blogTag)
    }

    static func createUser(on repository: InMemoryRepository) async throws -> BlogUser {
        let user = TestDataBuilder.anyUser()
        try await repository.save(user)
        return user
    }
    
    static func createView() -> View {
        let string = "Some HTML"
        var byteBuffer = ByteBufferAllocator().buffer(capacity: string.count)
        byteBuffer.writeString("Some HTML")
        let view = View(data: byteBuffer)
        return view
    }
}

struct TestData {
    let post: BlogPost
    let author: BlogUser
    let tag: BlogTag
}

struct EmptyContent: Content {}
