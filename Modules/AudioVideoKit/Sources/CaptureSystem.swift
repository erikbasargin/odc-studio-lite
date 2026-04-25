//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit

public struct CapturedPayload: Sendable {
    public let sample: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>
}

public struct ContentFilter: Sendable {
    public let includeMenuBar: Bool
    public let excludeCurrentApplication: Bool
    
    public init(
        includeMenuBar: Bool,
        excludeCurrentApplication: Bool
    ) {
        self.includeMenuBar = includeMenuBar
        self.excludeCurrentApplication = excludeCurrentApplication
    }
}

public struct CaptureConfiguration: Sendable {
    public let excludesCurrentProcessAudio: Bool
    public let captureMicrophone: Bool
    public let microphoneCaptureDeviceID: String?
    public let width: Int
    public let height: Int
    public let minimumFrameInterval: CMTime
    public let queueDepth: Int
    
    public init(
        excludesCurrentProcessAudio: Bool = true,
        captureMicrophone: Bool = false,
        microphoneCaptureDeviceID: String? = nil,
        width: Int,
        height: Int,
        minimumFrameInterval: CMTime,
        queueDepth: Int
    ) {
        self.excludesCurrentProcessAudio = excludesCurrentProcessAudio
        self.captureMicrophone = captureMicrophone
        self.microphoneCaptureDeviceID = microphoneCaptureDeviceID
        self.width = width
        self.height = height
        self.minimumFrameInterval = minimumFrameInterval
        self.queueDepth = queueDepth
    }
}

public struct CaptureSystem {
    
    public enum Screen {}
    public enum Audio {}
    public enum Microphone {}
    
    public struct CaptureStream<Type>: Sendable {
        fileprivate var stream: AsyncStream<CapturedPayload> {
            observer.stream
        }
        
        private let observer: CaptureSystem.Observer
        
        fileprivate init(observer: CaptureSystem.Observer) {
            self.observer = observer
        }
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
            configuration: .init(
                width: 1920,
                height: 1080,
                minimumFrameInterval: CMTime(value: 1, timescale: 60),
                queueDepth: 5
            )
        )
    }
    
    init(configuration: CaptureConfiguration) {
        self.init(
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            shareableContentProvider: ShareableContentRequest(),
            contentFilterProvider: SCContentFilterRequest(),
            configuration: configuration,
            screenCaptureStreamFactory: { filter, configuration, delegate in
                SCStream(filter: filter, configuration: configuration, delegate: delegate)
            }
        )
    }
    
    init(
        bundleIdentifier: String,
        shareableContentProvider: any ShareableContentProvider,
        contentFilterProvider: any SCContentFilterProvider,
        configuration: CaptureConfiguration,
        screenCaptureStreamFactory: (SCContentFilter, SCStreamConfiguration, (any SCStreamDelegate)?) -> SCStream
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.shareableContentProvider = shareableContentProvider
        self.contentFilterProvider = contentFilterProvider
        self.stream = screenCaptureStreamFactory(
            SCContentFilter(),
            Self.makeStreamConfiguration(configuration),
            nil
        )
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
    
    public func updateConfiguration(_ configuration: CaptureConfiguration) async throws {
        try await stream.updateConfiguration(Self.makeStreamConfiguration(configuration))
    }
}

private extension CaptureSystem {
    
    static func makeStreamConfiguration(_ configuration: CaptureConfiguration) -> SCStreamConfiguration {
        let streamConfiguration = SCStreamConfiguration()
        streamConfiguration.excludesCurrentProcessAudio = configuration.excludesCurrentProcessAudio
        streamConfiguration.captureMicrophone = configuration.captureMicrophone
        streamConfiguration.microphoneCaptureDeviceID =
            configuration.captureMicrophone
            ? configuration.microphoneCaptureDeviceID
            : nil
        streamConfiguration.width = configuration.width
        streamConfiguration.height = configuration.height
        streamConfiguration.minimumFrameInterval = configuration.minimumFrameInterval
        streamConfiguration.queueDepth = configuration.queueDepth
        return streamConfiguration
    }
    
    protocol CaptureStreamKind {
        static var streamOutputType: SCStreamOutputType { get }
    }
    
    final class Observer: NSObject, SCStreamOutput, Sendable {
        
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
            guard CMSampleBufferIsValid(sampleBuffer) else { return }
            guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
            
            nonisolated(unsafe) let unsafeBuffer = consume sampleBuffer
            let sample = CMReadySampleBuffer(unsafeBuffer: unsafeBuffer)
            
            continuation.yield(
                CapturedPayload(
                    sample: sample,
                )
            )
        }
    }
    
    func makeCaptureStream<T: CaptureStreamKind>(of kind: T.Type = T.self) throws -> CaptureStream<T> {
        let observer = Observer(type: kind.streamOutputType)
        let captureStream = CaptureStream<T>(observer: observer)
        
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
