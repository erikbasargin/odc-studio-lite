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
        let engine = CaptureEngine { _, _, _ in stream }
        
        try await confirmation { confirmation in
            stream.onStartCapture = {
                confirmation()
            }
            
            try await engine.start()
        }
    }
    
    @Test func startThrows() async throws {
        let stream = MockSCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        let engine = CaptureEngine { _, _, _ in stream }
        
        stream.onStartCapture = {
            throw MockSCStream.Error.test
        }
        
        await #expect(throws: MockSCStream.Error.test) {
            try await engine.start()
        }
    }
    
    @Test func streamStops() async throws {
        let stream = MockSCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        let engine = CaptureEngine { _, _, _ in stream }
        
        try await confirmation { confirmation in
            stream.onStopCapture = {
                confirmation()
            }
            
            try await engine.stop()
        }
    }
    
    @Test func stopThrows() async throws {
        let stream = MockSCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        let engine = CaptureEngine { _, _, _ in stream }
        
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
        let engine = CaptureEngine { _, _, _ in stream }
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
        let engine = CaptureEngine { _, _, _ in stream }
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
        let engine = CaptureEngine { _, _, _ in stream }
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
        let engine = CaptureEngine { _, _, _ in stream }
        
        stream.onAddStreamOutput = {
            throw MockSCStream.Error.test
        }
        
        #expect(throws: MockSCStream.Error.test) {
            try engine.audioCaptureStream
        }
    }
}

extension CaptureEngineTests {
    
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

    func stubOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer, type: SCStreamOutputType) {
        currentStreamOutput?.stream?(self, didOutputSampleBuffer: sampleBuffer, of: type)
    }
}
