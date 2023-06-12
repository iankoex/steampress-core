import Vapor
import XCTest
import SteamPressCore

class AdminPageTests: XCTestCase {
    
    func testAdminPagePassesCorrectInformationToPresenter() throws {
        let testWorld  = try TestWorld.create(url: "/")
        let user = testWorld.createUser(username: "leia")
        let testData1 = try testWorld.createPost(author: user)
        let testData2 = try testWorld.createPost(title: "A second post", author: user)
        
        _ = try testWorld.getResponse(to: "/admin/", loggedInUser: user)
        
        let presenter = testWorld.context.blogAdminPresenter
        XCTAssertNil(presenter.adminViewErrors)
        XCTAssertEqual(presenter.adminViewPosts?.count, 2)
        XCTAssertEqual(presenter.adminViewPosts?.first?.title, testData2.post.title)
        XCTAssertEqual(presenter.adminViewPosts?.last?.title, testData1.post.title)
        XCTAssertEqual(presenter.adminViewUsers?.count, 1)
        XCTAssertEqual(presenter.adminViewUsers?.last?.username, user.username)
        
        XCTAssertEqual(presenter.adminViewsite?.loggedInUser.username, user.username)
        XCTAssertEqual(presenter.adminViewsite?.url.absoluteString, "/")
        XCTAssertEqual(presenter.adminViewsite?.currentPageURL.absoluteString, "/admin/")
        
        try testWorld.shutdown()
    }
}