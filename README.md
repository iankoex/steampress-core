<p align="center">
    <img src="https://user-images.githubusercontent.com/9938337/29742058-ed41dcc0-8a6f-11e7-9cfc-680501cdfb97.png" alt="SteamPress">
    <br>
    <br>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/Swift-5.5-brightgreen.svg" alt="Language">
    </a>
    <a href="https://github.com/iankoex/steampress-core/actions/workflows/tests.yml">
        <img src="https://github.com/iankoex/steampress-core/actions/workflows/tests.yml/badge.svg" alt="Build Status">
    </a>
    </a>
    <a href="https://raw.githubusercontent.com/iankoex/steam-press-core/main/LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
    </a>
</p>

SteamPress: A Blogging Engine and Platform written in Swift.

`steampress-core` is the core engine for [SteamPress](https://github.com/iankoex/SteamPress). It uses protocols to define database storage, and therefore will work with any Vapor database provider.

The blog can either be used as the root of your site (i.e. appearing at https://www.acme.org) or in a subpath (i.e. https://www.acme.org/blog/).

## Features:

- Blog entries

- Multiple user accounts

- Tags on blog posts

- Snippet for posts

- Draft Posts

- Works with any Fluent driver

- Protected Admin route for creating blog posts

- Slug URLs for SEO optimisation and easy linking to posts

- Support for comments via Disqus

- Open Graph and Twitter Card support

- RSS/Atom Feed support

- Blog Search

# How to Use

First, add the package to your `Package.swift` dependencies:

```swift

dependencies: [

// ...

.package(url: "https://github.com/iankoex/steampress-core.git", from: "2.0.8"),

],

```

Then add it as a dependecy to your application target:

```swift

.target(name: "App",

dependencies: [

// ...

.product(name: "SteamPressCore", package: "steampress-core"),

])

```

In `configure.swift`, import the package:

```swift

import SteamPressCore

```

Next, configure your preferred database, in this example we are using postgres:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
}
```

Next, setup the `SteamPressLifecycleHandler`, the presenters and repositiories:

```swift

let feedInfo = FeedInformation(
    title: "The SteamPress Blog",
    description: "SteamPress is an open-source blogging engine written for Vapor in Swift",
    copyright: "Released under the MIT licence",
    imageURL: "https://user-images.githubusercontent.com/9938337/29742058-ed41dcc0-8a6f-11e7-9cfc-680501cdfb97.png"
)
let steamPressConfig = SteamPressConfiguration(feedInformation: feedInfo, postsPerPage: 4, enableAuthorPages: true, enableTagPages: true)
let steamPressLifecycle = SteamPressLifecycleHandler(configuration: steamPressConfig)
app.lifecycle.use(steamPressLifecycle)
    
// Presenters
app.steampress.application.presenters.register(.blog) { req in
    ViewBlogPresenter(req)
}
app.steampress.application.presenters.register(.admin) { req in
    ViewBlogAdminPresenter(req)
}
    
// Repositories
app.steampress.application.repositories.register(.blogTag) { req in
    FluentTagRepository(req)
}
app.steampress.application.repositories.register(.blogPost) { req in
    FluentPostRepository(req)
}
app.steampress.application.repositories.register(.blogUser) { req in
    FluentUserRepository(req)
}

```


## Configuration

You should set the `SP_WEBSITE_URL` environment variable to the root address of your site, e.g. `https://www.steampress.io`. This is used to set various parameters throughout SteamPress.
You can also set the `SP_BLOG_PATH` environment variable as the path you wish the blog to be, e.g `blog`. The website will therefore be available at `https://www.steampress.io/blog`
The admin page will be found at path `steampress`. Depending on your `SP_BLOG_PATH`, the admic page can be found on `https://www.steampress.io/blog/steampress`

## Logging In

When you first access the Admin page you will be required to create an account for the owner.

## Comments

SteamPress currently supports using [Disqus](https://disqus.com) for the comments engine. To use Disqus, start the app with the environment variable `BLOG_DISQUS_NAME` set to the name of your disqus sute. (You can get the name of your Disqus site from your Disqus admin panel)

This will pass it through to the Leaf templates for the Blog index (`blog.leaf`), blog posts (`blogpost.leaf`), author page (`profile.leaf`) and tag page (`tag.leaf`) so you can include it if needs be. If you want to manually set up comments you can do this yourself and just include the necessary files for your provider. This is mainly to provide easy configuration for the [example site](https://github.com/brokenhandsio/SteamPressExample).

## Open Graph Twitter Card Support

SteamPress supports both Open Graph and Twitter Cards. The blog post page context will pass in the created date and last edited date (if applicable) in ISO 8601 format for Open Graph article support, under the parameters `createdDateNumeric` and `lastEditedDateNumeric`.

The Blog Post page will also be passed a number of other useful parameters for Open Graph and Twitter Cards. See the `blogpost.leaf` section below.

The Twitter handle of the site can be configured with a `BLOG_SITE_TWITTER_HANDLE` environment variable (the site's twitter handle without the `@`). If set, this will be injected into the public pages as described below. This is for the `twitter:site` tag for Twitter Cards

## Google Analytics Support

SteamPress makes it easy to integrate Google Analytics into your blog. Just start the application with the `BLOG_GOOGLE_ANALYTICS_IDENTIFIER` environment variable set to you Google Analytics identifier. (You can get your identifier from the Google Analytics console, it will look something like UA-12345678-1)

This will pass a `googleAnalyticsIdentifier` parameter through to all of the public pages in the `site` variable, which you can include and then use the [Example Site's javascript](https://github.com/brokenhandsio/SteamPressExample/blob/master/Public/static/js/analytics.js) to integrate with.

## Atom/RSS Support

SteamPress automatically provides endpoints for registering RSS readers, either using RSS 2.0 or Atom 1.0. These endpoints can be found at the blog's `atom.xml` and `rss.xml` paths; e.g. if you blog is at `https://www.example.com/blog` then the atom feed will appear at `https://wwww.example.com/blog/atom.xml`. These will work by default, but you will probably want to configure some of fields. These are configured with the `FeedInformation` parameter passed to the provider. The configuration options are:

- `title` - the title of the blog - a default "SteamPress Blog" will be provided otherwise

- `description` - the description of the blog (or subtitle in atom) - a default "SteamPress is an open-source blogging engine written for Vapor in Swift" will be provided otherwise

- `copyright` - an optional copyright message to add to the feeds

- `imageURL` - an optional image/logo to add to the feeds. Note that for Atom this should a 2:1 landscape scaled image

## Search Support

SteamPress has a built in blog search. It will register a route, `/search`, under your blog path which you can send a query through to, with a key of `term` to search the blog.

# API

SteamPress also contains an API for accessing certain things that may be useful. The current endpoints are:

- `/<blog-path>/api/tags/` - returns all the tags that have been saved in JSON

We are working on exposing more endpoints. 
