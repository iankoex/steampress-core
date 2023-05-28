import Vapor

extension Array where Element: BlogUser {
    func getAuthorName(id: UUID) -> String {
        return self.filter { $0.id == id }.first?.name ?? ""
    }
    
    func getAuthorUsername(id: UUID) -> String {
        return self.filter { $0.id == id }.first?.username ?? ""
    }
}
