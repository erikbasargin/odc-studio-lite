//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import HaishinKit

@MainActor
final class MediaMixerController {

    private let mediaMixer = MediaMixer()
    private let capturePipelineConsumer = CapturePipelineConsumer()

    func bootstrapCapture(
        using captureSystem: CaptureSystem,
        configuration: CaptureConfiguration,
        contentFilter: ContentFilter
    ) async throws {
        try await captureSystem.updateConfiguration(configuration)
        try await captureSystem.updateContentFilter(contentFilter)
        try capturePipelineConsumer.startConsuming(from: captureSystem, on: mediaMixer)
        try await captureSystem.start()
    }

    func updateCaptureConfiguration(
        _ configuration: CaptureConfiguration,
        using captureSystem: CaptureSystem
    ) async throws {
        try await captureSystem.updateConfiguration(configuration)
    }

    func updateContentFilter(
        _ contentFilter: ContentFilter,
        using captureSystem: CaptureSystem
    ) async throws {
        try await captureSystem.updateContentFilter(contentFilter)
    }

    func startBroadcast(
        stream: any StreamConvertible,
        frameRate: Float64
    ) async throws {
        await mediaMixer.setSessionPreset(.high)
        try await mediaMixer.setFrameRate(frameRate)
        await mediaMixer.addOutput(stream)
        await mediaMixer.startRunning()
    }

    func stopBroadcast() async {
        await mediaMixer.stopRunning()
    }
}
