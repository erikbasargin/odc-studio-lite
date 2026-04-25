//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import HaishinKit

final class CapturePipelineConsumer {
    
    private var screenCaptureTask: Task<Void, Never>?
    private var microphoneCaptureTask: Task<Void, Never>?
    
    deinit {
        screenCaptureTask?.cancel()
        microphoneCaptureTask?.cancel()
    }
    
    func startConsuming(
        from captureSystem: CaptureSystem,
        on mediaMixer: MediaMixer
    ) throws {
        let screenCaptureStream = try captureSystem.screenCaptureStream
        let microphoneCaptureStream = try captureSystem.microphoneCaptureStream
        
        func listenVideoStream(
            stream: CaptureSystem.CaptureStream<CaptureSystem.Screen>,
            on mixer: isolated MediaMixer
        ) async {
            for await payload in stream where mixer.isRunning {
                guard SCVideoMetadata(payload.sample)?.status == .complete else {
                    continue
                }
                
                payload.sample.withUnsafeSampleBuffer { sampleBuffer in
                    mixer.append(sampleBuffer, track: 0)
                }
            }
        }
        
        func listenMicrophone(
            stream: CaptureSystem.CaptureStream<CaptureSystem.Microphone>,
            on mixer: isolated MediaMixer
        ) async {
            for await payload in stream where mixer.isRunning {
                payload.sample.withUnsafeSampleBuffer { sampleBuffer in
                    mixer.append(sampleBuffer, track: 0)
                }
            }
        }
        
        screenCaptureTask?.cancel()
        screenCaptureTask = Task { [mediaMixer] in
            await listenVideoStream(stream: screenCaptureStream, on: mediaMixer)
        }
        
        microphoneCaptureTask?.cancel()
        microphoneCaptureTask = Task { [mediaMixer] in
            await listenMicrophone(stream: microphoneCaptureStream, on: mediaMixer)
        }
    }
}
