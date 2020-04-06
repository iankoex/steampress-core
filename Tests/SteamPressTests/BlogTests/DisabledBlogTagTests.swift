import XCTest
import Vapor

class DisabledBlogTagTests: XCTestCase {
    func testDisabledBlogTagsPath() throws {
        let testWorld = TestWorld.create(enableTagPages: false)
        _ = try testWorld.createTag("Engineering")
        var tagResponse: Response? = try testWorld.getResponse(to: "/tags/Engineering")
        var allTagsResponse: Response? = try testWorld.getResponse(to: "/tags")

        XCTAssertEqual(.notFound, tagResponse?.status)
        XCTAssertEqual(.notFound, allTagsResponse?.status)
        
        tagResponse = nil
        allTagsResponse = nil
        
        XCTAssertNoThrow(try testWorld.shutdown())
    }
}
