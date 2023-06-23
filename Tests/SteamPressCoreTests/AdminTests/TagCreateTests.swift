import XCTest
import Vapor
@testable import SteamPressCore

class TagCreateTests: XCTestCase {
    
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
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }
    
    // MARK: - Tag Create Tests
    
    func testPresenterGetsCorrectValuesForMembersPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for Tags Page")
            .get(adminPath(for: "tags"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.createTagsViewTags)
        XCTAssertEqual(CapturingAdminPresenter.createTagsViewTags?.count, 0)
        XCTAssertEqual(CapturingAdminPresenter.createTagsViewUsersCount, 1)
        let site = try XCTUnwrap(CapturingAdminPresenter.createTagsViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "tags"))/")
    }
    
    func testPresenterGetsCorrectValuesForNewMembersPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for New Tags Page")
            .get(adminPath(for: "tags/new"))
            .cookie(sessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertEqual(CapturingAdminPresenter.createCreateTagsViewUsersCount, 1)
        let site = try XCTUnwrap(CapturingAdminPresenter.createCreateTagsViewSite)
        XCTAssertEqual(site.loggedInUser?.name, owner.name)
        XCTAssertEqual(site.loggedInUser?.email, owner.email)
        XCTAssertEqual(site.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(site.currentPageURL, "\(websiteURL)\(adminPath(for: "tags/new"))/")
    }
    
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
        XCTAssertTrue(errors.contains("Sorry that tag name has already been taken"))
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
    
    // MARK: - Update Tag
    
    func testTagCanBeUpdatedSuccessfully() async throws {
        let tag = try await createAndReturnTag()
        let createData = CreateTagData(name: "Events", visibility: .private)
        
        try app
            .describe("New Private/Internal Tag Can be Created Successfully")
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
    
    // MARK: - Helpers
    
    private func createAndReturnTag() async  throws -> BlogTag {
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
