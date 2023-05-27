import Vapor

class CapturingViewRenderer: ViewRenderer {
    var shouldCache = false
    var eventLoop: EventLoop

    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }
    
    func `for`(_ request: Request) -> ViewRenderer {
        return self
    }

    private(set) var capturedContext: Encodable?
    private(set) var templatePath: String?
    func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View> where E : Encodable {
        self.capturedContext = context
        self.templatePath = name
        
        let string = "Some HTML"
        var byteBuffer = ByteBufferAllocator().buffer(capacity: string.count)
        byteBuffer.writeString("Some HTML")
        let view = View(data: byteBuffer)
        return eventLoop.future(view)
    }

}
