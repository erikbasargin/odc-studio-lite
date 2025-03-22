//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit

//package protocol ShareableContentSource: NSObject {
//    
//    associatedtype Content: ShareableContentSource
//    
//    static var current: Content { get async throws }
//}

package struct CapturedPayload: Sendable {
    nonisolated(unsafe) let sampleBuffer: CMSampleBuffer
}

package final class CaptureEngine {
    
    package enum Screen {}
    package enum Audio {}
    package enum Microphone {}
    
    package struct CaptureStream<Type>: Sendable {
        fileprivate let stream: AsyncStream<CapturedPayload>
    }
    
    private let stream: SCStream
    
    package var screenCaptureStream: CaptureStream<Screen> {
        get throws {
            try makeCaptureStream()
        }
    }
    
    package var audioCaptureStream: CaptureStream<Audio> {
        get throws {
            try makeCaptureStream()
        }
    }
    
    package var microphoneCaptureStream: CaptureStream<Microphone> {
        get throws {
            try makeCaptureStream()
        }
    }
    
    package convenience init() {
        self.init(screenCaptureStreamFactory: { filter, configuration, delegate in
            SCStream(filter: filter, configuration: configuration, delegate: delegate)
        })
    }
    
    init(
        screenCaptureStreamFactory: (SCContentFilter, SCStreamConfiguration, (any SCStreamDelegate)?) -> SCStream
    ) {
        self.stream = screenCaptureStreamFactory(SCContentFilter(), SCStreamConfiguration(), nil)
    }
    
    package func start() async throws {
        try await stream.startCapture()
    }
    
    package func stop() async throws {
        try await stream.stopCapture()
    }
}

//extension SCShareableContent: ShareableContentSource {}

private extension CaptureEngine {
    
    protocol CaptureStreamKind {
        static var streamOutputType: SCStreamOutputType { get }
    }
    
    final class Observer: NSObject, SCStreamOutput {
        
        let type: SCStreamOutputType
        let stream: AsyncStream<CapturedPayload>
        private let continuation: AsyncStream<CapturedPayload>.Continuation
        
        init(type: SCStreamOutputType) {
            self.type = type
            (stream, continuation) = AsyncStream.makeStream(of: CapturedPayload.self)
            super.init()
        }
        
        func stream(
            _ stream: SCStream,
            didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
            of type: SCStreamOutputType
        ) {
            guard type == self.type else { return }
            continuation.yield(CapturedPayload(sampleBuffer: sampleBuffer))
        }
    }
    
    func makeCaptureStream<T: CaptureStreamKind>(of kind: T.Type = T.self) throws -> CaptureStream<T> {
        let observer = Observer(type: kind.streamOutputType)
        let captureStream = CaptureStream<T>(stream: observer.stream)
        
        try stream.addStreamOutput(
            observer,
            type: kind.streamOutputType,
            sampleHandlerQueue: nil
        )
        
        return captureStream
    }
}

extension CaptureEngine.CaptureStream: AsyncSequence {
    
    package func makeAsyncIterator() -> AsyncStream<CapturedPayload>.Iterator {
        stream.makeAsyncIterator()
    }
}

extension CaptureEngine.Screen: CaptureEngine.CaptureStreamKind {
    
    package static var streamOutputType: SCStreamOutputType {
        .screen
    }
}

extension CaptureEngine.Audio: CaptureEngine.CaptureStreamKind {
    
    package static var streamOutputType: SCStreamOutputType {
        .audio
    }
}

extension CaptureEngine.Microphone: CaptureEngine.CaptureStreamKind {
    
    package static var streamOutputType: SCStreamOutputType {
        .microphone
    }
}
