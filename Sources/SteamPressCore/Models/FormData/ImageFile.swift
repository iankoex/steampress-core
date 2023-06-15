import Vapor

struct ImageFile: Content {
    var image: File
}

struct ImageUploadResponse: Content {
    var success: Int
    var file: FileURL
    
    struct FileURL: Content {
        var url: String
    }
}
