import Vapor

extension Request {
    func filePath(for fileName: String) -> (String, String) {
        let publicDir = self.application.directory.publicDirectory
        var folderPath = publicDir + "Content"
        try? FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: false, attributes: nil)
        let calendarDate = Calendar.current.dateComponents([.year, .month], from: Date())
        if let year = calendarDate.year {
            folderPath.append(contentsOf: "/\(year)")
            try? FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: false, attributes: nil)
        }
        if let month = calendarDate.month {
            folderPath.append(contentsOf: "/\(month)")
            try? FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: false, attributes: nil)
        }
        folderPath.append(contentsOf: "/\(fileName)")
        if FileManager.default.fileExists(atPath: folderPath) {
            let newFileName = "\(UUID())-\(fileName)"
            folderPath = folderPath.replacingOccurrences(of: fileName, with: newFileName)
        }
        let fileURL = folderPath.replacingOccurrences(of: publicDir, with: "/")
        return (folderPath, fileURL)
    }
}
