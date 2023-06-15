import Vapor
import Foundation

extension Request {
    func filePath(for fileName: String) -> (String, String) {
        let publicDir = self.application.directory.publicDirectory
        var folderPath = publicDir + "Content"
        try? FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: false, attributes: nil)
        let calendarDate = Calendar.current.dateComponents([.year, .month], from: Date())
        if let year = calendarDate.year {
            do {
                let temp = folderPath.appending("/\(year)")
                try FileManager.default.createDirectory(atPath: temp, withIntermediateDirectories: false, attributes: nil)
                folderPath = temp
            } catch {
                print(error.localizedDescription)
            }
        }
        if let month = calendarDate.month {
            do {
                let temp = folderPath.appending("/\(month)")
                try FileManager.default.createDirectory(atPath: temp, withIntermediateDirectories: false, attributes: nil)
                folderPath = temp
            } catch {
                print(error.localizedDescription)
            }
        }
        folderPath.append(contentsOf: "/\(fileName)")
        let fileURL = folderPath.replacingOccurrences(of: publicDir, with: "/")
        return (folderPath, fileURL)
    }
}
