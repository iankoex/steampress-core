import Vapor

struct ImageContainer: Content {
    var image: File
}

struct FileContainer: Content {
    var file: File
}

struct FileUploadResponse: Content {
    var success: Int
    var file: FileURL
    
    struct FileURL: Content {
        var url: String
    }
}
