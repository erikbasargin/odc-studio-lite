//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit
import Testing

@testable import AudioVideoKit

@Suite(.timeLimit(.minutes(1)))
struct CaptureEngineTests {
    
    @Test func streamStarts() async throws {
        let stream = MockSCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        let engine = makeEngine { _, _, _ in stream }
        
        try await confirmation { confirmation in
            stream.onStartCapture = {
                confirmation()
            }
            
            try await engine.start()
        }
    }
    
    @Test func startThrows() async throws {
        let stream = MockSCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        let engine = makeEngine { _, _, _ in stream }
        
        stream.onStartCapture = {
            throw MockSCStream.Error.test
        }
        
        await #expect(throws: MockSCStream.Error.test) {
            try await engine.start()
        }
    }
    
    @Test func streamStops() async throws {
        let stream = MockSCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        let engine = makeEngine { _, _, _ in stream }
        
        try await confirmation { confirmation in
            stream.onStopCapture = {
                confirmation()
            }
            
            try await engine.stop()
        }
    }
    
    @Test func stopThrows() async throws {
        let stream = MockSCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        let engine = makeEngine { _, _, _ in stream }
        
        stream.onStopCapture = {
            throw MockSCStream.Error.test
        }
        
        await #expect(throws: MockSCStream.Error.test) {
            try await engine.stop()
        }
    }
    
    @Test
    func captureStreamProducesPayloadOfRequestedScreenKind() async throws {
        let stream = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let sampleBuffer = try makeCMSampleBuffer()
        let audioSampleBuffer = try CaptureStreamHelper.makeAudioSampleBuffer()
        let engine = makeEngine { _, _, _ in stream }
        let captureStream = try engine.screenCaptureStream
        
        async let capturedPayloads = captureStream.prefix(1).reduce(into: []) { partialResult, payload in
            partialResult.append(payload)
        }
        
        await Task.megaYield()
        
        stream.stubOutputSampleBuffer(audioSampleBuffer, type: .audio)
        
        await Task.megaYield()
        
        stream.stubOutputSampleBuffer(sampleBuffer, type: .screen)
        
        await #expect(
            capturedPayloads.map(\.sampleBuffer) == [
                sampleBuffer
            ]
        )
    }
    
    @Test
    func captureStreamProducesPayloadOfRequestedAudioKind() async throws {
        let stream = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let sampleBuffer = try makeCMSampleBuffer()
        let audioSampleBuffer = try CaptureStreamHelper.makeAudioSampleBuffer()
        let engine = makeEngine { _, _, _ in stream }
        let captureStream = try engine.audioCaptureStream
        
        async let capturedPayloads = captureStream.prefix(1).reduce(into: []) { partialResult, payload in
            partialResult.append(payload)
        }
        
        await Task.megaYield()
        
        stream.stubOutputSampleBuffer(audioSampleBuffer, type: .microphone)
        
        await Task.megaYield()
        
        stream.stubOutputSampleBuffer(sampleBuffer, type: .audio)
        
        await #expect(
            capturedPayloads.map(\.sampleBuffer) == [
                sampleBuffer
            ]
        )
    }
    
    @Test
    func captureStreamProducesPayloadOfRequestedMicrophoneKind() async throws {
        let stream = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let sampleBuffer = try makeCMSampleBuffer()
        let audioSampleBuffer = try CaptureStreamHelper.makeAudioSampleBuffer()
        let engine = makeEngine { _, _, _ in stream }
        let captureStream = try engine.microphoneCaptureStream
        
        async let capturedPayloads = captureStream.prefix(1).reduce(into: []) { partialResult, payload in
            partialResult.append(payload)
        }
        
        await Task.megaYield()
        
        stream.stubOutputSampleBuffer(audioSampleBuffer, type: .audio)
        
        await Task.megaYield()
        
        stream.stubOutputSampleBuffer(sampleBuffer, type: .microphone)
        
        await #expect(
            capturedPayloads.map(\.sampleBuffer) == [
                sampleBuffer
            ]
        )
    }
    
    @Test func makeCaptureStreamThrowsWhenAddStreamOutputFails() async throws {
        let stream = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let engine = makeEngine { _, _, _ in stream }
        
        stream.onAddStreamOutput = {
            throw MockSCStream.Error.test
        }
        
        #expect(throws: MockSCStream.Error.test) {
            try engine.audioCaptureStream
        }
    }
    
    @Test(arguments: [
        ContentFilter(includeMenuBar: false, excludeCurrentApplication: false),
        ContentFilter(includeMenuBar: true, excludeCurrentApplication: false),
    ])
    func includeMenuBar(_ contentFilter: ContentFilter) async throws {
        let display = try MockDisplay.make(displayID: 1)
        let stream = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let shareableContentProvider = MockShareableContentProvider {
            .init(displays: [display], applications: [])
        }
        let engine = makeEngine(
            shareableContentProvider: shareableContentProvider,
            screenCaptureStreamFactory: { _, _, _ in stream }
        )
        
        try await confirmation { confirmation in
            stream.onUpdateContentFilter = { filter in
                #expect(filter.includeMenuBar == contentFilter.includeMenuBar)
                confirmation()
            }
            
            try await engine.updateContentFilter(contentFilter)
        }
    }
    
    @Test(arguments: [
        ContentFilter(includeMenuBar: false, excludeCurrentApplication: false),
        ContentFilter(includeMenuBar: false, excludeCurrentApplication: true),
    ])
    @available(macOS 15.2, *)
    func excludeCurrentApplication(_ contentFilter: ContentFilter) async throws {
        let expectedDisplay = try MockDisplay.make(displayID: 1)
        let application1 = try MockRunningApplication.make(bundleIdentifier: "1")
        let application2 = try MockRunningApplication.make(bundleIdentifier: "2")
        
        let stream = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let shareableContentProvider = MockShareableContentProvider {
            .init(displays: [expectedDisplay], applications: [application1, application2])
        }
        
        try await confirmation { confirmation in
            let contentFilterProvider = MockContentFilterProvider { display, excludingApplications, exceptingWindows in
                try? #require(display.displayID == expectedDisplay.displayID)
                if contentFilter.excludeCurrentApplication {
                    try? #require(excludingApplications.map(\.bundleIdentifier) == ["2"])
                } else {
                    try? #require(excludingApplications.isEmpty)
                }
                try? #require(exceptingWindows.isEmpty)
                
                confirmation()
            }
            
            let engine = makeEngine(
                bundleIdentifier: "2",
                shareableContentProvider: shareableContentProvider,
                contentFilterProvider: contentFilterProvider,
                screenCaptureStreamFactory: { _, _, _ in stream }
            )
            
            try await engine.updateContentFilter(contentFilter)
        }
    }
    
    @Test
    func shareableContentProviderThrows() async throws {
        let stream = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let shareableContentProvider = MockShareableContentProvider {
            throw MockSCStream.Error.test
        }
        let engine = makeEngine(
            shareableContentProvider: shareableContentProvider,
            screenCaptureStreamFactory: { _, _, _ in stream }
        )
        
        await #expect(throws: MockSCStream.Error.test) {
            try await engine.updateContentFilter(.init(includeMenuBar: true, excludeCurrentApplication: false))
        }
    }
    
    @Test
    func updateContentFilterThrows() async throws {
        let display = try MockDisplay.make(displayID: 1)
        let stream = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let shareableContentProvider = MockShareableContentProvider {
            .init(displays: [display], applications: [])
        }
        stream.onUpdateContentFilter = { _ in
            throw MockSCStream.Error.test
        }
        
        let engine = makeEngine(
            shareableContentProvider: shareableContentProvider,
            screenCaptureStreamFactory: { _, _, _ in stream }
        )
        
        await #expect(throws: MockSCStream.Error.test) {
            try await engine.updateContentFilter(.init(includeMenuBar: true, excludeCurrentApplication: false))
        }
    }
    
    @Test
    func multipleDisplays() async throws {
        let displayOne = try MockDisplay.make(displayID: 10)
        let displayTwo = try MockDisplay.make(displayID: 11)
        
        let stream = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let shareableContentProvider = MockShareableContentProvider {
            .init(displays: [displayOne, displayTwo], applications: [])
        }
        
        try await confirmation { confirmation in
            let contentFilterProvider = MockContentFilterProvider { display, _, _ in
                try? #require(display.displayID == displayOne.displayID)
                confirmation()
            }
            
            let engine = makeEngine(
                shareableContentProvider: shareableContentProvider,
                contentFilterProvider: contentFilterProvider,
                screenCaptureStreamFactory: { _, _, _ in stream }
            )
            
            try await engine.updateContentFilter(.init(includeMenuBar: false, excludeCurrentApplication: false))
        }
    }
}

extension CaptureEngineTests {
    
    func makeEngine(
        bundleIdentifier: String = "",
        shareableContentProvider: any ShareableContentProvider = MockShareableContentProvider(
            onInvoke: {
                .init(displays: [], applications: [])
            }
        ),
        contentFilterProvider: any SCContentFilterProvider = MockContentFilterProvider { _, _, _ in },
        screenCaptureStreamFactory: (SCContentFilter, SCStreamConfiguration, (any SCStreamDelegate)?) -> SCStream
    ) -> CaptureEngine {
        .init(
            bundleIdentifier: bundleIdentifier,
            shareableContentProvider: shareableContentProvider,
            contentFilterProvider: contentFilterProvider,
            screenCaptureStreamFactory: screenCaptureStreamFactory
        )
    }
    
    fileprivate func makeCMSampleBuffer() throws -> CMSampleBuffer {
        try CaptureStreamHelper.makeCMSampleBuffer(
            imageBuffer: try CaptureStreamHelper.makeCVImageBufferWithIOSurface()
        )
    }
}

private final class MockSCStream: SCStream {
    
    enum Error: LocalizedError, Equatable {
        case test
    }
    
    var onStartCapture: (() throws -> Void)?
    var onStopCapture: (() throws -> Void)?
    var onAddStreamOutput: (() throws -> Void)?
    var onUpdateContentFilter: ((SCContentFilter) throws -> Void)?
    
    private var currentStreamOutput: (any SCStreamOutput)?
    
    override func startCapture() async throws {
        try onStartCapture?()
    }
    
    override func stopCapture() async throws {
        try onStopCapture?()
    }
    
    override func addStreamOutput(
        _ output: any SCStreamOutput,
        type: SCStreamOutputType,
        sampleHandlerQueue: dispatch_queue_t?
    ) throws {
        try onAddStreamOutput?()
        currentStreamOutput = output
    }
    
    override func updateContentFilter(_ contentFilter: SCContentFilter) async throws {
        try onUpdateContentFilter?(contentFilter)
    }

    func stubOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer, type: SCStreamOutputType) {
        currentStreamOutput?.stream?(self, didOutputSampleBuffer: sampleBuffer, of: type)
    }
}

private struct MockShareableContentProvider: ShareableContentProvider {
    
    let onInvoke: () throws -> ShareableContentPayload
    
    func invoke() async throws -> ShareableContentPayload {
        try onInvoke()
    }
}

private struct MockContentFilterProvider: SCContentFilterProvider {
    
    let onInvoke: (
        _ display: SCDisplay,
        _ excludingApplications: [SCRunningApplication],
        _ exceptingWindows: [SCWindow]
    ) -> Void
    
    func invoke(
        display: SCDisplay,
        excludingApplications applications: [SCRunningApplication],
        exceptingWindows: [SCWindow]
    ) -> SCContentFilter {
        onInvoke(display, applications, exceptingWindows)
        return SCContentFilter()
    }
}

final class MockDisplay: SCDisplay {
    
    override var displayID: CGDirectDisplayID { stubDisplayID }
    override var width: Int { 0 }
    override var height: Int { 0 }
    override var frame: CGRect { .zero }
    
    private var stubDisplayID: CGDirectDisplayID = 0
    
    static func make(displayID: CGDirectDisplayID) throws -> MockDisplay {
        let display = try #require((MockDisplay.self as NSObject.Type).init() as? MockDisplay)
        display.stubDisplayID = displayID
        return display
    }
}

final class MockRunningApplication: SCRunningApplication {
    
    override var bundleIdentifier: String { stubBundleIdentifier }
    override var applicationName: String { "applicationName_\(stubBundleIdentifier)" }
    override var processID: pid_t { .zero }
    
    private var stubBundleIdentifier: String = "unknown"
    
    static func make(bundleIdentifier: String) throws -> MockRunningApplication {
        let application = try #require((MockRunningApplication.self as NSObject.Type).init() as? MockRunningApplication)
        application.stubBundleIdentifier = bundleIdentifier
        return application
    }
}
