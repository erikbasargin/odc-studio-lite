//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
@preconcurrency import AVFoundation
import AppKit
import HaishinKit
import RTMPHaishinKit
import OSLog
import VideoToolbox
import Foundation

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastManager")

@MainActor
final class BroadcastManager {
    
    private var configuration: BroadcastConfiguration

    private var excludeAppFromStream = true {
        didSet {
            Task {
                await updateStreamContentFilter()
            }
        }
    }

    private var captureMicrophone: Bool {
        get {
            configuration.selectedMicrophone != nil
        }
        set {
            guard newValue != captureMicrophone else {
                return
            }

            if newValue {
                configuration.selectedMicrophone = defaultMicrophoneDevice()
            } else {
                configuration.selectedMicrophone = nil
            }
        }
    }

    private var selectedCameraDevice: CaptureDevice? {
        get {
            configuration.selectedCamera
        }
        set {
            configuration.selectedCamera = newValue
        }
    }

    private let cameraCaptureSession = AVCaptureSession()
    private let cameraDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .continuityCamera],
        mediaType: .video,
        position: .unspecified
    )
    
    private let mediaMixer = MediaMixer()
    private let captureSystem = CaptureSystem()
    private let capturePipelineConsumer = CapturePipelineConsumer()
    private var broadcastSession: BroadcastSession?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private var broadcastConfigurationContinuations: [UUID: AsyncStream<BroadcastConfiguration>.Continuation] = [:]
    
    private var scaleFactor: Int {
        Int(NSScreen.main?.backingScaleFactor ?? 2)
    }
    
    private var streamContentFilter: ContentFilter {
        .init(includeMenuBar: false, excludeCurrentApplication: excludeAppFromStream)
    }
    
    private var captureConfiguration: CaptureConfiguration {
        let screenFrame = NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 1920, height: 1080)

        return .init(
            excludesCurrentProcessAudio: true,
            captureMicrophone: captureMicrophone,
            microphoneCaptureDeviceID: configuration.selectedMicrophone?.id,
            width: Int(screenFrame.width) * scaleFactor,
            height: Int(screenFrame.height) * scaleFactor,
            minimumFrameInterval: CMTime(value: 1, timescale: 60),
            queueDepth: 5
        )
    }

    init(configuration: BroadcastConfiguration = BroadcastConfiguration()) {
        self.configuration = configuration
        self.configuration.selectedCamera = AVCaptureDevice.systemPreferredCamera.map {
            CaptureDevice(id: $0.uniqueID, name: $0.localizedName)
        }
    }

    deinit {
        for continuation in broadcastConfigurationContinuations.values {
            continuation.finish()
        }
//        let captureSystem = captureSystem
//        Task {
//            do {
//                try await captureSystem?.stop()
//            } catch {
//                log.error("Failed to stop stream capture: \(error.localizedDescription)")
//            }
//        }
    }
    
    struct NoCameraDevice: Error {}
    struct CameraCaptureSessionError: Error {}
    
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
            
            guard let device = cameraDiscoverySession.devices.first(where: { selectedCameraDevice.id == $0.uniqueID })
            else {
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
    
    func updateCameraAuthorization(_ isAuthorized: Bool) {
        configuration.cameraIsAuthorized = isAuthorized
        notifyBroadcastConfigurationDidChange()
    }

    func updatePrimaryStreamKey(_ primaryStreamKey: String) {
        configuration.primaryStreamKey = primaryStreamKey
        notifyBroadcastConfigurationDidChange()
    }

    func updateBandwidthTestEnabled(_ bandwidthTestEnabled: Bool) {
        configuration.bandwidthTestEnabled = bandwidthTestEnabled
        notifyBroadcastConfigurationDidChange()
    }

    func updateCaptureMicrophone(_ isEnabled: Bool) async {
        captureMicrophone = isEnabled
        await updateStreamConfiguration()
        notifyBroadcastConfigurationDidChange()
    }

    func updateSelectedCamera(_ camera: CaptureDevice?) async {
        selectedCameraDevice = camera
        configureCameraSession()
        await updateStreamConfiguration()
        notifyBroadcastConfigurationDidChange()
    }

    func updateSelectedMicrophone(_ microphone: CaptureDevice?) async {
        configuration.selectedMicrophone = microphone
        await updateStreamConfiguration()
        notifyBroadcastConfigurationDidChange()
    }

    func broadcastConfiguration() -> BroadcastConfiguration {
        BroadcastConfiguration(
            bandwidthTestEnabled: configuration.bandwidthTestEnabled,
            primaryStreamKey: configuration.primaryStreamKey,
            isBroadcasting: configuration.isBroadcasting,
            cameraIsAuthorized: configuration.cameraIsAuthorized,
            selectedCamera: selectedCameraDevice,
            selectedMicrophone: configuration.selectedMicrophone
        )
    }

    func broadcastConfigurationUpdates() -> AsyncStream<BroadcastConfiguration> {
        let id = UUID()

        return AsyncStream { continuation in
            broadcastConfigurationContinuations[id] = continuation
            continuation.yield(broadcastConfiguration())
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.broadcastConfigurationContinuations.removeValue(forKey: id)
                }
            }
        }
    }
    
    func configureManager() async throws {
        try await captureSystem.updateConfiguration(captureConfiguration)
        try await captureSystem.updateContentFilter(streamContentFilter)
        try capturePipelineConsumer.startConsuming(from: captureSystem, on: mediaMixer)

        try await captureSystem.start()
    }
    
    func stopBroadcast() async {
        guard configuration.isBroadcasting else {
            return
        }
        
        configuration.isBroadcasting = false
        notifyBroadcastConfigurationDidChange()
        await mediaMixer.stopRunning()
        
        do {
            try await broadcastSession?.close()
            broadcastSession = nil
        } catch {
            log.error("Error closing session: \(error.localizedDescription)")
        }
    }
    
    func startBroadcast(broadcastSession: BroadcastSession?) async {
        guard let broadcastSession else {
            log.error("Broadcast session is not available")
            return
        }
        await stopBroadcast()
        self.broadcastSession = broadcastSession
        
        do {
            configuration.isBroadcasting = true
            notifyBroadcastConfigurationDidChange()
            
            let stream = await broadcastSession.stream()
            
            let videoCodecSettings = VideoCodecSettings(
                videoSize: .init(width: 1920, height: 1080),
                bitRate: 6000 * 1000,
                profileLevel: kVTProfileLevel_H264_High_AutoLevel as String,
                bitRateMode: .constant,
                allowFrameReordering: false  // disable B frames
            )
            try await stream.setVideoSettings(videoCodecSettings)
            
            await mediaMixer.setSessionPreset(.high)
            try await mediaMixer.setFrameRate(Float64(captureConfiguration.minimumFrameInterval.timescale))
            
            await mediaMixer.addOutput(stream)
            await mediaMixer.startRunning()
            
            try await broadcastSession.connect {
                Task { @MainActor in
                    await self.stopBroadcast()
                }
            }
        } catch RTMPConnection.Error.requestFailed {
            log.error("RTMP connection request failed")
            configuration.isBroadcasting = false
            notifyBroadcastConfigurationDidChange()
        } catch RTMPStream.Error.requestFailed {
            log.error("RTMP stream request failed")
            configuration.isBroadcasting = false
            notifyBroadcastConfigurationDidChange()
        } catch {
            log.error("\(error.localizedDescription)")
            configuration.isBroadcasting = false
            notifyBroadcastConfigurationDidChange()
        }
    }
    
    private func updateStreamContentFilter() async {
        do {
            try await captureSystem.updateContentFilter(streamContentFilter)
        } catch {
            log.error(
                "Failed to update stream content filter: \(error.localizedDescription)"
            )
        }
    }
    
    private func updateStreamConfiguration() async {
        do {
            try await captureSystem.updateConfiguration(captureConfiguration)
        } catch {
            log.error(
                "Failed to update stream configuration: \(error.localizedDescription)"
            )
        }
    }

    private func defaultMicrophoneDevice() -> CaptureDevice? {
        AVCaptureDevice.default(for: .audio).map { device in
            CaptureDevice(id: device.uniqueID, name: device.localizedName)
        }
    }

    private func notifyBroadcastConfigurationDidChange() {
        let configuration = broadcastConfiguration()
        for continuation in broadcastConfigurationContinuations.values {
            continuation.yield(configuration)
        }
    }
    
}
