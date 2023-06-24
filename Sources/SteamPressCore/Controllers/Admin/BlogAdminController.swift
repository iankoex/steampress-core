import Vapor

struct BlogAdminController: RouteCollection {

    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        let adminRoutes = routes.grouped("steampress")

        let redirectMiddleware = BlogLoginRedirectAuthMiddleware()
        let adminProtectedRoutes = adminRoutes.grouped(redirectMiddleware)
        adminProtectedRoutes.get(use: adminHandler)
        adminProtectedRoutes.get("explore", use: exploreHandler)
        adminProtectedRoutes.get("pages", use: pagesHandler)
        adminProtectedRoutes.post("uploadImage", use: imageUploadHandler)
        adminProtectedRoutes.post("uploadFile", use: fileUploadHandler)
        
        let loginController = LoginController()
        try adminRoutes.register(collection: loginController)
        let postsController = PostsAdminController()
        try adminProtectedRoutes.register(collection: postsController)
        let usersController = UsersAdminController()
        try adminProtectedRoutes.register(collection: usersController)
        let tagsController = TagsAdminController()
        try adminProtectedRoutes.register(collection: tagsController)
    }

    // MARK: Admin Handler
    func adminHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createIndexView(usersCount: usersCount, errors: nil, site: req.siteInformation())
    }
    
    func exploreHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createExploreView(usersCount: usersCount, errors: nil, site: req.siteInformation())
    }
    
    func pagesHandler(_ req: Request) async throws -> View {
        let usersCount = try await req.repositories.blogUser.getUsersCount()
        return try await req.presenters.admin.createPagesView(usersCount: usersCount, errors: nil, site: req.siteInformation())
    }
    
    func imageUploadHandler(_ req: Request) async throws -> FileUploadResponse {
        print(req.content)
        let imageFile = try req.content.decode(ImageContainer.self)
        
        let (filePath, fileURL) = req.filePath(for: imageFile.image.filename)
        let nioFileHandle = try await req.application.fileio.openFile(
            path: filePath,
            mode: .write,
            flags: .allowFileCreation(posixMode: .max),
            eventLoop: req.eventLoop
        ).get()
        try await req.application.fileio.write(
            fileHandle: nioFileHandle,
            buffer: imageFile.image.data,
            eventLoop: req.eventLoop
        ).get()
        try nioFileHandle.close()
        return FileUploadResponse(success: 1, file: .init(url: fileURL))
    }
    
    func fileUploadHandler(_ req: Request) async throws -> FileUploadResponse {
        let imageFile = try req.content.decode(FileContainer.self)
        
        let (filePath, fileURL) = req.filePath(for: imageFile.file.filename)
        let nioFileHandle = try await req.application.fileio.openFile(
            path: filePath,
            mode: .write,
            flags: .allowFileCreation(posixMode: .max),
            eventLoop: req.eventLoop
        ).get()
        try await req.application.fileio.write(
            fileHandle: nioFileHandle,
            buffer: imageFile.file.data,
            eventLoop: req.eventLoop
        ).get()
        try nioFileHandle.close()
        return FileUploadResponse(success: 1, file: .init(url: fileURL))
    }
}
