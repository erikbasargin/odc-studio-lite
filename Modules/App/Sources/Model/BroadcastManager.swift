//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
@preconcurrency import AVFoundation
import AppKit
import Foundation
import OSLog

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastManager")

@MainActor
final class BroadcastManager {

    private var excludeAppFromStream = true
    private var selectedCameraDevice: CaptureDevice?

    private let cameraCaptureSession = AVCaptureSession()
    private let cameraDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .continuityCamera],
        mediaType: .video,
        position: .unspecified
    )

    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?

    private var scaleFactor: Int {
        Int(NSScreen.main?.backingScaleFactor ?? 2)
    }

    init() {
        self.selectedCameraDevice = AVCaptureDevice.systemPreferredCamera.map {
            CaptureDevice(id: $0.uniqueID, name: $0.localizedName)
        }
    }

    struct NoCameraDevice: Error {}
    struct CameraCaptureSessionError: Error {}

    func initialBroadcastConfiguration() -> BroadcastConfiguration {
        BroadcastConfiguration(selectedCamera: selectedCameraDevice)
    }

    func setSelectedCamera(_ camera: CaptureDevice?) {
        selectedCameraDevice = camera
        configureCameraSession()
    }

    func makeCaptureConfiguration(selectedMicrophone: CaptureDevice?) -> CaptureConfiguration {
        let screenFrame = NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 1920, height: 1080)

        return .init(
            excludesCurrentProcessAudio: true,
            captureMicrophone: selectedMicrophone != nil,
            microphoneCaptureDeviceID: selectedMicrophone?.id,
            width: Int(screenFrame.width) * scaleFactor,
            height: Int(screenFrame.height) * scaleFactor,
            minimumFrameInterval: CMTime(value: 1, timescale: 60),
            queueDepth: 5
        )
    }

    func makeStreamContentFilter() -> ContentFilter {
        .init(includeMenuBar: false, excludeCurrentApplication: excludeAppFromStream)
    }

    func defaultMicrophoneDevice() -> CaptureDevice? {
        AVCaptureDevice.default(for: .audio).map { device in
            CaptureDevice(id: device.uniqueID, name: device.localizedName)
        }
    }

    private func configureCameraSession() {
        cameraCaptureSession.beginConfiguration()
        defer {
            cameraCaptureSession.commitConfiguration()

            if selectedCameraDevice == nil {
                cameraPreviewLayer = nil
                Task.detached(priority: .userInitiated) { [weak self] in
                    guard let captureSession = await self?.cameraCaptureSession else { return }
                    captureSession.stopRunning()
                }
            } else {
                cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraCaptureSession)
                Task.detached(priority: .userInitiated) { [weak self] in
                    guard let captureSession = await self?.cameraCaptureSession else { return }
                    captureSession.startRunning()
                }
            }
        }

        cameraCaptureSession.sessionPreset = .high

        do {
            guard let selectedCameraDevice else {
                for input in cameraCaptureSession.inputs {
                    cameraCaptureSession.removeInput(input)
                }
                return
            }

            guard let device = cameraDiscoverySession.devices.first(where: {
                selectedCameraDevice.id == $0.uniqueID
            }) else {
                throw NoCameraDevice()
            }

            let input = try AVCaptureDeviceInput(device: device)
            if cameraCaptureSession.canAddInput(input) {
                cameraCaptureSession.addInput(input)
            } else {
                throw CameraCaptureSessionError()
            }

            AVCaptureDevice.userPreferredCamera = device
        } catch {
            log.error("\(error.localizedDescription)")
        }
    }
}
