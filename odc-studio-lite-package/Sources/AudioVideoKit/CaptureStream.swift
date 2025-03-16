//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

@preconcurrency import ScreenCaptureKit

package struct CapturedPayload: Equatable, Sendable {
    
    private nonisolated(unsafe) let sampleBuffer: CMSampleBuffer
    
    init(sampleBuffer: CMSampleBuffer) {
        self.sampleBuffer = sampleBuffer
    }
}

package struct CaptureStream: AsyncSequence, Sendable {
    
    let source: SCStream
    let type: SCStreamOutputType
    
    package struct Iterator: AsyncIteratorProtocol {
        
        fileprivate let observer: Observer
        private var iterator: AsyncStream<CapturedPayload>.Iterator
        
        fileprivate init(observer: Observer) {
            self.observer = observer
            iterator = observer.makeAsyncIterator()
        }
        
        mutating package func next() async throws -> CapturedPayload? {
            try observer.prepareIfNeeded()
            return await iterator.next()
        }
    }
    
    init(source: SCStream, type: SCStreamOutputType) {
        self.source = source
        self.type = type
    }
    
    package func makeAsyncIterator() -> Iterator {
        Iterator(observer: Observer(source: source, type: type))
    }
}

private extension CaptureStream {
    
    final class Observer: NSObject, SCStreamOutput {
        
        private let source: SCStream
        private let type: SCStreamOutputType
        private let stream: AsyncStream<CapturedPayload>
        private let continuation: AsyncStream<CapturedPayload>.Continuation
        
        init(source: SCStream, type: SCStreamOutputType) {
            self.source = source
            self.type = type
            (stream, continuation) = AsyncStream.makeStream(of: CapturedPayload.self)
        }
        
        func prepareIfNeeded() throws {
            try source.addStreamOutput(self, type: type, sampleHandlerQueue: nil)
        }
        
        func makeAsyncIterator() -> AsyncStream<CapturedPayload>.Iterator {
            stream.makeAsyncIterator()
        }
        
        func stream(
            _ stream: SCStream,
            didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
            of type: SCStreamOutputType
        ) {
            continuation.yield(CapturedPayload(sampleBuffer: sampleBuffer))
        }
    }
}
