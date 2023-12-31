import XCTest
import Vapor
@testable import SteamPressCore

class TagsCreateTests: XCTestCase {
    
    // MARK: - Properties
    
    private var testWorld: TestWorld!
    private var sessionCookie: HTTPCookies!
    private let blogIndexPath = "blog"
    private let owner = CreateOwnerData(name: "Steam Press Owner", password: "SP@Password", email: "admin@steampress.io")
    private let websiteURL = "https://www.steampress.io"
    
    var app: Application {
        testWorld.context.app
    }
    
    // MARK: - Overrides
    
    override func setUpWithError() throws {
        testWorld = try TestWorld.create(path: blogIndexPath, passwordHasherToUse: .real, url: websiteURL)
        sessionCookie = try createAndLoginOwner()
        CapturingAdminPresenter.resetValues()
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }
    
    // MARK: - Tag Create Tests
    
    func testTagCanBeCreatedSuccessfully() async throws {
        let createData = CreateTagData(name: "Events")
        
        try app
            .describe("New Tag Can be Created Successfully")
            .post(adminPath(for: "tags/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "tags/"))
            }
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        XCTAssertEqual(tags.count, 1)
        let tag = try XCTUnwrap(tags.first)
        XCTAssertEqual(tag.name, createData.name)
        XCTAssertEqual(tag.visibility, .public)
        XCTAssertNil(CapturingAdminPresenter.createCreateTagsViewErrors)
    }
    
    func testInternalTagCanBeCreatedSuccessfully() async throws {
        let createData = CreateTagData(name: "Events", visibility: .private)
        
        try app
            .describe("New Private/Internal Tag Can be Created Successfully")
            .post(adminPath(for: "tags/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "tags/"))
            }
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        XCTAssertEqual(tags.count, 1)
        let tag = try XCTUnwrap(tags.first)
        XCTAssertEqual(tag.name, createData.name)
        XCTAssertEqual(tag.visibility, .private)
        XCTAssertNil(CapturingAdminPresenter.createCreateTagsViewErrors)
    }
    
    func testTagCannotBeCreatedWithAnExistingName() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreateTagData(name: tag.name)
        
        try app
            .describe("Tag Cannot be Created With an An Existing Name")
            .post(adminPath(for: "tags/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        XCTAssertEqual(tags.count, 1) // already created 1
        XCTAssertNotNil(CapturingAdminPresenter.createCreateTagsViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateTagsViewErrors)
        XCTAssertTrue(errors.contains("Sorry that tag name already exists"))
    }
    
    func testTagCannotBeCreatedWithAnEmptyName() async throws {
        let createData = CreateTagData(name: "")
        
        try app
            .describe("Tag Cannot be Created With an Empty Name")
            .post(adminPath(for: "tags/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        XCTAssertEqual(tags.count, 0)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateTagsViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateTagsViewErrors)
        XCTAssertTrue(errors.contains("You must specify a tag name"))
    }
    
    func testTagCannotBeCreatedWithAWhitespaceName() async throws {
        let createData = CreateTagData(name: "     ")
        
        try app
            .describe("Tag Cannot be Created With a Whitespace Name")
            .post(adminPath(for: "tags/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        XCTAssertEqual(tags.count, 0)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateTagsViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateTagsViewErrors)
        XCTAssertTrue(errors.contains("You must specify a tag name"))
    }
    
    // MARK: - Update Tag Tests
    
    func testTagCanBeUpdatedSuccessfully() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreateTagData(name: "Nairobi Events", visibility: .private)
        
        try app
            .describe("Tag Can be Updated Successfully")
            .post(adminPath(for: "tags/\(tag.slugURL)"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "tags/"))
            }
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        XCTAssertEqual(tags.count, 1)
        let updatedTag = try XCTUnwrap(tags.first)
        XCTAssertEqual(updatedTag.name, createData.name)
        XCTAssertEqual(updatedTag.visibility, .private)
        XCTAssertNil(CapturingAdminPresenter.createCreateTagsViewErrors)
    }
    
    func testTagCannotBeUpdatedWithATagNameThatAlreadyExists() async throws {
        let tag1 = try await createAndReturnTag()
        let tag2 = try await createAndReturnTag("World News")
        let createData = CreateTagData(name: tag2.name)
        
        try app
            .describe("Tag Cannot Be Updated With a Tag Name That Already Exists")
            .post(adminPath(for: "tags/\(tag1.slugURL)"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        XCTAssertEqual(tags.count, 2)
        let updatedTag = try XCTUnwrap(tags.first)
        XCTAssertEqual(updatedTag.name, createData.name)
        XCTAssertEqual(updatedTag.visibility, .public)
        XCTAssertNotNil(CapturingAdminPresenter.createCreateTagsViewErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.createCreateTagsViewErrors)
        XCTAssertTrue(errors.contains("Sorry that tag name already exists"))
    }
    
    // MARK: - Delete Tag Tests
    
    func testTagCanBeDeletedSuccessfully() async throws {
        let tag = try await createAndReturnTag()
        
        try app
            .describe("Tag Can be Deleted Successfully")
            .get(adminPath(for: "tags/\(tag.slugURL)/delete"))
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "tags/"))
            }
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        XCTAssertEqual(tags.count, 0)
        XCTAssertNil(CapturingAdminPresenter.createCreateTagsViewErrors)
    }
    
    // MARK: - Helpers
    
    private func createAndReturnTag(_ name: String = "Events") async  throws -> BlogTag {
        let createData = CreateTagData(name: name)
        
        try app
            .describe("New Tag Can be Created Successfully")
            .post(adminPath(for: "tags/new"))
            .body(createData)
            .cookie(sessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "tags/"))
            }
            .test()
        
        let tags = try await testWorld.context.req.repositories.blogTag.getAllTags()
        
        let tag = try XCTUnwrap(tags.first)
        XCTAssertEqual(tag.name, createData.name)
        XCTAssertEqual(tag.visibility, .public)
        XCTAssertNil(CapturingAdminPresenter.createCreateTagsViewErrors)
        return tag
    }
    
    private func createAndLoginOwner() throws -> HTTPCookies {
        var cookie: HTTPCookies = HTTPCookies()
        try app
            .describe("App should create and log in user")
            .post(adminPath(for: "createOwner"))
            .body(owner)
            .expect(.seeOther)
            .expect { response in
                cookie = response.headers.setCookie!
            }
            .test()
        return cookie
    }
    
    private func adminPath(for path: String) -> String {
        return "/\(blogIndexPath)/steampress/\(path)"
    }
}
