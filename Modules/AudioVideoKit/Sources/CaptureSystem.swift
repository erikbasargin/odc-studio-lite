//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit

public struct CapturedPayload: Sendable {
    nonisolated(unsafe) let sampleBuffer: CMSampleBuffer
}

public struct ContentFilter: Sendable {
    let includeMenuBar: Bool
    let excludeCurrentApplication: Bool
}

public struct CaptureSystem {
    
    public enum Screen {}
    public enum Audio {}
    public enum Microphone {}
    
    public struct CaptureStream<Type>: Sendable {
        fileprivate let stream: AsyncStream<CapturedPayload>
    }
    
    private let bundleIdentifier: String
    private let shareableContentProvider: any ShareableContentProvider
    private let contentFilterProvider: any SCContentFilterProvider
    private let stream: SCStream
    
    public var screenCaptureStream: CaptureStream<Screen> {
        get throws {
            try makeCaptureStream()
        }
    }
    
    public var audioCaptureStream: CaptureStream<Audio> {
        get throws {
            try makeCaptureStream()
        }
    }
    
    public var microphoneCaptureStream: CaptureStream<Microphone> {
        get throws {
            try makeCaptureStream()
        }
    }
    
    public init() {
        self.init(
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            shareableContentProvider: ShareableContentRequest(),
            contentFilterProvider: SCContentFilterRequest(),
            screenCaptureStreamFactory: { filter, configuration, delegate in
                SCStream(filter: filter, configuration: configuration, delegate: delegate)
            }
        )
    }
    
    init(
        bundleIdentifier: String,
        shareableContentProvider: any ShareableContentProvider,
        contentFilterProvider: any SCContentFilterProvider,
        screenCaptureStreamFactory: (SCContentFilter, SCStreamConfiguration, (any SCStreamDelegate)?) -> SCStream
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.shareableContentProvider = shareableContentProvider
        self.contentFilterProvider = contentFilterProvider
        self.stream = screenCaptureStreamFactory(SCContentFilter(), SCStreamConfiguration(), nil)
    }
    
    public func start() async throws {
        try await stream.startCapture()
    }
    
    public func stop() async throws {
        try await stream.stopCapture()
    }
    
    public func updateContentFilter(_ contentFilter: ContentFilter) async throws {
        let shareableContent = try await shareableContentProvider.invoke()
        
        guard let currentDisplay = shareableContent.displays.first else {
            preconditionFailure("No display available")
        }
        
        let currentApplication = shareableContent.applications.first { application in
            application.bundleIdentifier == bundleIdentifier
        }.flatMap {
            [$0]
        }
        
        let filter = contentFilterProvider.invoke(
            display: currentDisplay,
            excludingApplications: contentFilter.excludeCurrentApplication ? currentApplication ?? [] : [],
            exceptingWindows: []
        )
        filter.includeMenuBar = contentFilter.includeMenuBar
        try await stream.updateContentFilter(filter)
    }
}

private extension CaptureSystem {
    
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

extension CaptureSystem.CaptureStream: AsyncSequence {
    
    public func makeAsyncIterator() -> AsyncStream<CapturedPayload>.Iterator {
        stream.makeAsyncIterator()
    }
}

extension CaptureSystem.Screen: CaptureSystem.CaptureStreamKind {
    
    public static var streamOutputType: SCStreamOutputType {
        .screen
    }
}

extension CaptureSystem.Audio: CaptureSystem.CaptureStreamKind {
    
    public static var streamOutputType: SCStreamOutputType {
        .audio
    }
}

extension CaptureSystem.Microphone: CaptureSystem.CaptureStreamKind {
    
    public static var streamOutputType: SCStreamOutputType {
        .microphone
    }
}
