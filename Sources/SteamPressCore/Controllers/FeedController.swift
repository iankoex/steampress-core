import Vapor
import Foundation

struct FeedController: RouteCollection {
    
    // MARK: - Properties
    fileprivate let atomGenerator: AtomFeedGenerator
    fileprivate let rssGenerator: RSSFeedGenerator
    static var defaultTitle: String {
        return "SteamPress Blog"
    }
    static var defaultDescription: String {
        return "SteamPress is an open-source blogging engine written for and using Vapor in Swift"
    }
    
    // MARK: - Initialiser
    init(feedInformation: FeedInformation) {
        let feedTitle = feedInformation.title ?? FeedController.defaultTitle
        let feedDescription = feedInformation.description ?? FeedController.defaultDescription
        
        atomGenerator = AtomFeedGenerator(
            title: feedTitle,
            description: feedDescription,
            copyright: feedInformation.copyright,
            imageURL: feedInformation.imageURL
        )
        rssGenerator = RSSFeedGenerator(
            title: feedTitle,
            description: feedDescription,
            copyright: feedInformation.copyright,
            imageURL: feedInformation.imageURL
        )
    }
    
    // MARK: - Route Collection
    func boot(routes: RoutesBuilder) throws {
        routes.get("atom.xml", use: atomGenerator.feedHandler)
        routes.get("rss.xml", use: rssGenerator.feedHandler)
    }
}
