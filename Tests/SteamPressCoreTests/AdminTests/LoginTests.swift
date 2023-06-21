import XCTest
import Vapor
import SteamPressCore
import Foundation

class LoginTests: XCTestCase {
    
    // MARK: - Properties
    
    private var testWorld: TestWorld!
    private var initialSessionCookie: HTTPCookies!
    private let blogIndexPath = "blog"
    private let owner = CreateOwnerData(name: "Steam Press Owner", password: "SP@Password", email: "admin@steampress.io")
    private let websiteURL = "https://www.steampress.io"
    
    var app: Application {
        testWorld.context.app
    }
    
    // MARK: - Overrides
    
    override func setUpWithError() throws {
        testWorld = try TestWorld.create(path: blogIndexPath, passwordHasherToUse: .real, url: websiteURL)
        initialSessionCookie = try createAndLoginOwner()
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }
    
    // MARK: - Tests
   
    func testLoginPageCanBeAccessed() throws {
        try app
            .describe("Login page can be accessed")
            .get(adminPath(for: "login"))
            .expect(.ok)
            .test()
    }
    
    func testLoginWarningShownIfRedirecting() throws {
        try app
            .describe("Login warning is shown if redirecting")
            .get(adminPath(for: "login?loginRequired=true"))
            .expect(.ok)
            .test()

        let loginWarning = try XCTUnwrap(CapturingAdminPresenter.loginWarning)
        XCTAssertTrue(loginWarning)
    }
    
    func testLoginWarningShownIfRedirectingFromAdminIndex() throws {
        try app
            .describe("Login warning is shown if redirecting from another page")
            .get(adminPath(for: ""))
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "login?loginRequired=true"))
            }
            .test()
    }
    
    func testPresenterGetsCorrectInformationForResetPasswordPage() throws {
        try app
            .describe("Presenter Gets The Correct Information for ResetPassword Page")
            .get(adminPath(for: "resetPassword"))
            .cookie(initialSessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNil(CapturingAdminPresenter.resetPasswordErrors)
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.loggedInUser?.name, owner.name)
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.loggedInUser?.email, owner.email)
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.currentPageURL, "\(websiteURL)\(adminPath(for: "resetPassword"))/")
    }
    
    
    func testLogin() throws {
        var cookie: HTTPCookies = HTTPCookies()
        let loginData = LoginData(email: owner.email, password: owner.password)
        
        try app
            .describe("Login Works and the Relevent Variables are Set")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = response.headers.setCookie!
            }
            .test()
        
        try app
            .describe("Can Access Admin Page with the Login Cookie")
            .get(adminPath(for: ""))
            .cookie(cookie)
            .expect(.ok)
            .test()
        
        try app
            .describe("Can Access Logout Page with the Login Cookie")
            .get(adminPath(for: "logout"))
            .cookie(cookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "login?loginRequired=true/"))
            }
            .test()
    }
    
    func testCannotLoginWithWrongEmail() throws {
        let loginData = LoginData(email: "wrong@email.com", password: owner.password)
        
        try app
            .describe("Cannot Login with Wrong Email")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.loginErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.loginErrors)
        XCTAssertTrue(errors.contains("Your email or password is incorrect"))
        XCTAssertEqual(CapturingAdminPresenter.loginEmail, loginData.email)
        XCTAssertNil(CapturingAdminPresenter.loginsite?.loggedInUser)
        XCTAssertEqual(CapturingAdminPresenter.loginsite?.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(CapturingAdminPresenter.loginsite?.currentPageURL, "\(websiteURL)\(adminPath(for: "login"))/")
    }
    
    func testCannotLoginWithWrongPassword() throws {
        let loginData = LoginData(email: owner.email, password: "wrongPassword")
        
        try app
            .describe("Cannot Login with Wrong Password")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.loginErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.loginErrors)
        XCTAssertTrue(errors.contains("Your email or password is incorrect"))
        XCTAssertEqual(CapturingAdminPresenter.loginEmail, loginData.email)
        XCTAssertNil(CapturingAdminPresenter.loginsite?.loggedInUser)
        XCTAssertEqual(CapturingAdminPresenter.loginsite?.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(CapturingAdminPresenter.loginsite?.currentPageURL, "\(websiteURL)\(adminPath(for: "login"))/")
    }
    
    func testUserCanResetPassword() throws {
        let newPassword = "NewSP@Password"
        let resetData = ResetPasswordData(password: newPassword, confirmPassword: newPassword)
        
        try app
            .describe("Can Reset Password")
            .post(adminPath(for: "resetPassword"))
            .body(resetData)
            .cookie(initialSessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
            }
            .test()
    }
    
    func testUserCannotResetPasswordWithMismatchingPasswords() throws {
        let resetData = ResetPasswordData(password: "NewSP@Password", confirmPassword: "AnotherNewSP@Password")
        
        try resetPasswordTest(
            description: "Cannot Reset Password With Mismatching Passwords",
            resetData: resetData,
            errorShouldContain: "Your passwords must match!"
        )
    }
    
    func testUserCannotResetPasswordWithoutPassword() throws {
        let resetData = ResetPasswordData(password: nil, confirmPassword: "AnotherNewSP@Password")
        
        try resetPasswordTest(
            description: "Cannot Reset Password Without a Password",
            resetData: resetData,
            errorShouldContain: "You must specify a password!"
        )
    }
    
    func testUserCannotResetPasswordWithoutConfirmPassword() throws {
        let resetData = ResetPasswordData(password: "NewSP@Password", confirmPassword: nil)
        
        try resetPasswordTest(
            description: "Cannot Reset Password Without a Confirm Password",
            resetData: resetData,
            errorShouldContain: "You must confirm your password!"
        )
    }
    
    func testUserCannotResetPasswordWithShortPassword() throws {
        let resetData = ResetPasswordData(password: "123", confirmPassword: "123")
        
        try resetPasswordTest(
            description: "Cannot Reset Password With Mismatching Passwords",
            resetData: resetData,
            errorShouldContain: "Your password must be at least 8 characters long!"
        )
    }
    
    func testThatAfterResettingPasswordUserIsNotAskedToResetPassword() throws {
        let newUser = CreateUserData(name: "q", username: "q", password: "q8characters", confirmPassword: "q8characters", email: "q@q.q")
        
        try app
            .describe("Can Create New member")
            .post(adminPath(for: "members/new"))
            .cookie(initialSessionCookie)
            .body(newUser)
            .expect(.seeOther)
            .test()
        
        var cookie: HTTPCookies = HTTPCookies()
        let loginData = LoginData(email: newUser.email, password: newUser.password!)
        
        try app
            .describe("Newly Created Member Can Login")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = response.headers.setCookie!
            }
            .test()
        
        try app
            .describe("Newly Created Member is Redirected to Reset Password Page")
            .get(adminPath(for: ""))
            .cookie(cookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: "resetPassword/"))
                XCTAssertNotNil(response.headers[.setCookie].first)
            }
            .test()
        
        let newPassword = "NewSP@Password"
        let resetData = ResetPasswordData(password: newPassword, confirmPassword: newPassword)
        
        try app
            .describe("Newly Created Member Can Reset Password")
            .post(adminPath(for: "resetPassword"))
            .body(resetData)
            .cookie(initialSessionCookie)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = response.headers.setCookie!
            }
            .test()
        
        try app
            .describe("Newly Created Member is NOT Redirected to Reset Password Page After Succesful Reset Password")
            .get(adminPath(for: ""))
            .cookie(cookie)
            .expect(.ok)
            .test()
    }
    
    func testLoginWithRememberMeSetsCookieExpiryDateTo1Year() throws {
        var cookie: HTTPCookies.Value = .init(string: "nil")
        let loginData = LoginData(email: owner.email, password: owner.password, rememberMe: true)
        
        try app
            .describe("Login Works and the Relevent Variables are Set")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = (response.headers.setCookie?.all["steampress-session"]!)!
            }
            .test()

        let oneYear: TimeInterval = 60 * 60 * 24 * 365
        let expires = try XCTUnwrap(cookie.expires)
        XCTAssertEqual(expires.timeIntervalSince1970, Date().addingTimeInterval(oneYear).timeIntervalSince1970, accuracy: 1)
    }
    
    func testLoginWithoutRememberMeDoesntSetCookieExpiryDate() throws {
        var cookie: HTTPCookies.Value = .init(string: "nil")
        let loginData = LoginData(email: owner.email, password: owner.password, rememberMe: nil)
        
        try app
            .describe("Login Works and the Relevent Variables are Set")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = (response.headers.setCookie?.all["steampress-session"]!)!
            }
            .test()
        
        XCTAssertNil(cookie.expires)
    }
    
    func testLoginWithRememberMeSetToFalseDoesntSetCookieExpiryDate() throws {
        var cookie: HTTPCookies.Value = .init(string: "nil")
        let loginData = LoginData(email: owner.email, password: owner.password, rememberMe: nil)
        
        try app
            .describe("Login Works and the Relevent Variables are Set")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = (response.headers.setCookie?.all["steampress-session"]!)!
            }
            .test()
        
        XCTAssertNil(cookie.expires)
    }
    
    func testLoginWithRememberMeThenLoginAgainWithItDisabledDoesntRememberMe() throws {
        var cookie: HTTPCookies.Value = .init(string: "nil")
        let loginData = LoginData(email: owner.email, password: owner.password, rememberMe: true)
        
        try app
            .describe("Login Works and the Relevent Variables are Set")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = (response.headers.setCookie?.all["steampress-session"]!)!
            }
            .test()
        
        var newCookie: HTTPCookies.Value = .init(string: "nil")
        let newLoginData = LoginData(email: owner.email, password: owner.password, rememberMe: nil)
        
        try app
            .describe("Login Works and the Relevent Variables are Set")
            .post(adminPath(for: "login"))
            .body(newLoginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                newCookie = (response.headers.setCookie?.all["steampress-session"]!)!
            }
            .test()
        
        let oneYear: TimeInterval = 60 * 60 * 24 * 365
        let expires = try XCTUnwrap(cookie.expires)
        XCTAssertEqual(expires.timeIntervalSince1970, Date().addingTimeInterval(oneYear).timeIntervalSince1970, accuracy: 2)
        XCTAssertNil(newCookie.expires)
    }
    
    func testRememberMeDateOnlySetOnceThenLoginAgainWithItRemembersMe() throws {
        var cookie: HTTPCookies = HTTPCookies()
        var cookieValue: HTTPCookies.Value = .init(string: "nil")
        let loginData = LoginData(email: owner.email, password: owner.password, rememberMe: true)
        
        try app
            .describe("Login Works and and the cookie is set with expiry")
            .post(adminPath(for: "login"))
            .body(loginData)
            .expect(.seeOther)
            .expect { response in
                XCTAssertEqual(response.headers[.location].first, self.adminPath(for: ""))
                XCTAssertNotNil(response.headers[.setCookie].first)
                cookie = response.headers.setCookie!
                cookieValue = (response.headers.setCookie?.all["steampress-session"]!)!
            }
            .test()
        
        var secondCookieValue: HTTPCookies.Value = .init(string: "nil")
        try app
            .describe("Accessing the Website Again Does Not Change the Expiry of the Cookie")
            .get(adminPath(for: ""))
            .cookie(cookie)
            .expect(.ok)
            .expect { response in
                XCTAssertNotNil(response.headers[.setCookie].first)
                secondCookieValue = (response.headers.setCookie?.all["steampress-session"]!)!
            }
            .test()
        
        XCTAssertEqual(cookieValue.expires, secondCookieValue.expires)
    }
    
    func testCorrectsiteForLogin() throws {
        try app
            .describe("Login page can be accessed and the required site info is Passed")
            .get(adminPath(for: "login"))
            .expect(.ok)
            .test()
        
        XCTAssertNil(CapturingAdminPresenter.loginsite?.disqusName)
        XCTAssertNil(CapturingAdminPresenter.loginsite?.googleAnalyticsIdentifier)
        XCTAssertNil(CapturingAdminPresenter.loginsite?.twitterHandle)
        XCTAssertNil(CapturingAdminPresenter.loginsite?.loggedInUser)
        XCTAssertEqual(CapturingAdminPresenter.loginsite?.currentPageURL, "\(websiteURL)\(adminPath(for: "login/"))")
        XCTAssertEqual(CapturingAdminPresenter.loginsite?.url, "\(websiteURL)/\(blogIndexPath)/")
    }
    
    func testSettingEnvVarsWithsiteForLoginPage() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        
        try app
            .describe("Login page can be accessed and the required site info is Passed")
            .get(adminPath(for: "login"))
            .expect(.ok)
            .test()
        
        XCTAssertEqual(CapturingAdminPresenter.loginsite?.disqusName, disqusName)
        XCTAssertEqual(CapturingAdminPresenter.loginsite?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(CapturingAdminPresenter.loginsite?.twitterHandle, twitterHandle)
    }
    
    // MARK: - Helpers
    
    func resetPasswordTest(description: String, resetData: ResetPasswordData, errorShouldContain errorText: String) throws {
        try app
            .describe(description)
            .post(adminPath(for: "resetPassword"))
            .body(resetData)
            .cookie(initialSessionCookie)
            .expect(.ok)
            .test()
        
        XCTAssertNotNil(CapturingAdminPresenter.resetPasswordErrors)
        let errors = try XCTUnwrap(CapturingAdminPresenter.resetPasswordErrors)
        XCTAssertTrue(errors.contains(errorText))
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.loggedInUser?.name, owner.name)
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.loggedInUser?.email, owner.email)
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.url, "\(websiteURL)/\(blogIndexPath)/")
        XCTAssertEqual(CapturingAdminPresenter.resetPasswordsite?.currentPageURL, "\(websiteURL)\(adminPath(for: "resetPassword"))/")
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
