import XCTest
import Vapor

class DisabledBlogTagTests: XCTestCase {
    func testDisabledBlogTagsPath() throws {
        var testWorld = try TestWorld.create(enableTagPages: false)
        _ = try testWorld.createTag("Engineering")
        let tagResponse = try testWorld.getResponse(to: "/tags/Engineering")
        let allTagsResponse = try testWorld.getResponse(to: "/tags")

        XCTAssertEqual(.notFound, tagResponse.http.status)
        XCTAssertEqual(.notFound, allTagsResponse.http.status)
    }
}
