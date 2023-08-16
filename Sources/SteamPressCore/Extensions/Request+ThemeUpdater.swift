import Vapor
import ZIPFoundation

extension Request {
    
    func updateTheme(using zipFile: File) async throws -> [String] {
        var errors: [String] = []
        let zipFilePath = try await writeZipFilToDisk(zipFile)
        let workingAreaPath = try await extractZipFile(at: zipFilePath)
        let (themeFolderPath, theme, validationErrors) = try await validateTheme(at: workingAreaPath)
        if let validationErrors = validationErrors {
            errors.append(contentsOf: validationErrors)
            return errors
        }
        guard let theme = theme, !themeFolderPath.isEmpty else {
            return errors
        }
        try await updateDefaultThemeResources(using: theme, at: themeFolderPath)
        return errors
    }
    
    func updateDefaultThemeResources(using theme: Theme, at path: String) async throws {
        let themesDirectory = self.application.directory.viewsDirectory.appending("Themes")
        let defaultThemeFolderPath = themesDirectory.appending("/default")
        let backupPath = themesDirectory + "/backupOfDefaultTheme.zip"
        if FileManager.default.fileExists(atPath: backupPath) {
            try FileManager.default.removeItem(atPath: backupPath)
        }
        var destinationURL = URL(fileURLWithPath: backupPath)
        try FileManager.default.zipItem(at: URL(fileURLWithPath: defaultThemeFolderPath), to: destinationURL)
        // create the uploaded theme folder
        let uploadedThemeFolderName = "Themes/" + theme.urlSafeName
        let uploadedThemeFolderPath = self.application.directory.viewsDirectory.appending(uploadedThemeFolderName)
        if FileManager.default.fileExists(atPath: uploadedThemeFolderPath) {
            try FileManager.default.removeItem(atPath: uploadedThemeFolderPath)
        }
        try FileManager.default.copyItem(atPath: path, toPath: uploadedThemeFolderPath)
        try FileManager.default.removeItem(atPath: defaultThemeFolderPath)
        try FileManager.default.copyItem(atPath: path, toPath: defaultThemeFolderPath)
    }
}

fileprivate extension Request {
    
    func writeZipFilToDisk(_ zipFile: File) async throws -> String {
        let themeFolderPath = self.application.directory.viewsDirectory.appending("Themes")
        try? FileManager.default.createDirectory(atPath: themeFolderPath, withIntermediateDirectories: true, attributes: nil)
        let filePath = themeFolderPath.appending("/recentlyUploadedTheme.zip")
        if FileManager.default.fileExists(atPath: filePath) {
            try FileManager.default.removeItem(atPath: filePath)
        }
        let nioFileHandle = try await self.application.fileio.openFile(
            path: filePath,
            mode: .write,
            flags: .allowFileCreation(posixMode: .max),
            eventLoop: self.eventLoop
        ).get()
        try await self.application.fileio.write(
            fileHandle: nioFileHandle,
            buffer: zipFile.data,
            eventLoop: self.eventLoop
        ).get()
        try nioFileHandle.close()
        return filePath
    }
    
    func extractZipFile(at zipFilePath: String) async throws -> String {
        let fileURL = URL(fileURLWithPath: zipFilePath)
        let destinationPath = self.application.directory.viewsDirectory.appending("Themes/WorkingArea")
        try? FileManager.default.createDirectory(atPath: destinationPath, withIntermediateDirectories: true, attributes: nil)
        if FileManager.default.fileExists(atPath: destinationPath) {
            try FileManager.default.removeItem(atPath: destinationPath)
        }
        let destinationURL = URL(fileURLWithPath: destinationPath)
        try FileManager.default.unzipItem(at: fileURL, to: destinationURL)
        return destinationPath
    }
    
    func validateTheme(at workingAreaPath: String) async throws -> (String, Theme?, [String]?) {
        var errors: [String] = []
        guard let themeFolderPath = try await getThemeFolderPath(at: workingAreaPath) else {
            errors.append("Theme Folder may be Missing or Lacks a package.json file at the Root of the Folder")
            return ("", nil, errors)
        }
        let jsonURL = URL(fileURLWithPath: themeFolderPath + "/package.json")
        let themeData = try Data(contentsOf: jsonURL, options: .mappedIfSafe)
        let theme = try JSONDecoder().decode(Theme.self, from: themeData)
        for requiredFile in Theme.requiredFiles {
            let filePath = "/\(requiredFile).leaf"
            if !FileManager.default.fileExists(atPath: themeFolderPath + filePath) {
                errors.append("Required File at path: \(filePath) is missing.")
            }
        }
        return (themeFolderPath, theme, errors.isEmpty ? nil : errors)
    }
    
    func getThemeFolderPath(at workingAreaPath: String) async throws -> String? {
        var themeFolderPath: String? = nil
        let items = try FileManager.default.contentsOfDirectory(atPath: workingAreaPath)
        for item in items {
            let path = "/" + item + "/package.json"
            if FileManager.default.fileExists(atPath: workingAreaPath + path) {
                themeFolderPath = workingAreaPath + "/" + item
            }
        }
        return themeFolderPath
    }
}

struct Theme: Codable {
    var name: String
    var description: String
    var version: String
    var license: String
    var author: Author
    
    struct Author: Codable {
        var name: String
        var email: String
        var url: String
    }
}

extension Theme {
    static var requiredFiles: [String] {
        var adminFiles: [String] = ["admin/index", "admin/explore", "admin/pages", "admin/tags", "admin/tag", "admin/posts", "admin/post", "admin/members", "admin/member", "admin/login", "admin/resetPassword", "admin/settings"]
        var indexFiles: [String] = ["index", "tags", "tag", "authors", "author", "post", "search"]
        indexFiles.append(contentsOf: adminFiles)
        return indexFiles
    }
    
    var urlSafeName: String {
        let alphanumericsWithHyphenAndSpace = CharacterSet(charactersIn: " -0123456789abcdefghijklmnopqrstuvwxyz")
        let urlSafeName = name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: alphanumericsWithHyphenAndSpace.inverted).joined()
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
            .replacingOccurrences(of: " ", with: "-", options: .regularExpression)
        return urlSafeName
    }
}
