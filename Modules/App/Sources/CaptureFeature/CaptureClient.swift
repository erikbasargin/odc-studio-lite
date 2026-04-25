//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

@preconcurrency import AVFoundation
import AppKit
import AudioVideoKit
import ComposableArchitecture
import Foundation
import HaishinKit
import OSLog
import ScreenCaptureKit

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CaptureClient")

struct CaptureClient: Sendable {
    var bootstrap: @Sendable (CaptureDevice?) async throws -> Bool
    var defaultMicrophone: @Sendable () async -> CaptureDevice?
    var setSelectedCamera: @Sendable (CaptureDevice?) async -> Void
    var setSelectedMicrophone: @Sendable (CaptureDevice?) async -> Void
    var startCaptureSession: @Sendable () async -> Void
    var stopCaptureSession: @Sendable () async -> Void
    var startBroadcast: @Sendable (BroadcastSession) async throws -> Void
}

extension CaptureClient: DependencyKey {
    static let liveValue = Self.unimplemented
    static let testValue = Self.unimplemented
    
    private static let unimplemented = Self(
        bootstrap: { _ in false },
        defaultMicrophone: { nil },
        setSelectedCamera: { _ in },
        setSelectedMicrophone: { _ in },
        startCaptureSession: {},
        stopCaptureSession: {},
        startBroadcast: { _ in }
    )
}

extension DependencyValues {
    var captureClient: CaptureClient {
        get { self[CaptureClient.self] }
        set { self[CaptureClient.self] = newValue }
    }
}

extension CaptureClient {
    static func initialConfiguration() -> BroadcastConfiguration {
        BroadcastConfiguration(
            selectedCamera: AVCaptureDevice.systemPreferredCamera.map {
                CaptureDevice(id: $0.uniqueID, name: $0.localizedName)
            }
        )
    }
    
    static func live(
        _ runtime: CaptureRuntime,
        cameraAuthorizationService: CameraAuthorizationService = .liveValue
    ) -> Self {
        Self(
            bootstrap: { selectedMicrophone in
                try await runtime.bootstrap(
                    selectedMicrophone: selectedMicrophone,
                    cameraAuthorizationService: cameraAuthorizationService
                )
            },
            defaultMicrophone: {
                await runtime.defaultMicrophone()
            },
            setSelectedCamera: { camera in
                await runtime.setSelectedCamera(camera)
            },
            setSelectedMicrophone: { microphone in
                await runtime.setSelectedMicrophone(microphone)
            },
            startCaptureSession: {
                await runtime.startCaptureSession()
            },
            stopCaptureSession: {
                await runtime.stopCaptureSession()
            },
            startBroadcast: { session in
                try await runtime.startBroadcast(session: session)
            }
        )
    }
}

actor CaptureRuntime {
    
    private var excludeAppFromStream = true
    private var selectedCameraDevice: CaptureDevice?
    private var cameraSessionIsRunning = false
    
    private let captureSystem = CaptureSystem()
    private let mediaMixer = MediaMixer()
    private let capturePipelineConsumer = CapturePipelineConsumer()
    private let cameraCaptureSession = AVCaptureSession()
    private let cameraDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .continuityCamera],
        mediaType: .video,
        position: .unspecified
    )
    
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    init() {
        self.selectedCameraDevice = AVCaptureDevice.systemPreferredCamera.map {
            CaptureDevice(id: $0.uniqueID, name: $0.localizedName)
        }
    }
    
    struct NoCameraDevice: Error {}
    struct CameraCaptureSessionError: Error {}
    
    func bootstrap(
        selectedMicrophone: CaptureDevice?,
        cameraAuthorizationService: CameraAuthorizationService
    ) async throws -> Bool {
        try await captureSystem.updateConfiguration(makeCaptureConfiguration(selectedMicrophone: selectedMicrophone))
        try await captureSystem.updateContentFilter(makeStreamContentFilter())
        try capturePipelineConsumer.startConsuming(from: captureSystem, on: mediaMixer)
        try await captureSystem.start()
        
        var initialConfiguration = SCContentSharingPickerConfiguration()
        initialConfiguration.allowedPickerModes = [.singleDisplay]
        initialConfiguration.allowsChangingSelectedContent = true
        SCContentSharingPicker.shared.configuration = initialConfiguration
        SCContentSharingPicker.shared.isActive = true
        
        return await cameraAuthorizationService.authorize()
    }
    
    func defaultMicrophone() -> CaptureDevice? {
        AVCaptureDevice.default(for: .audio).map { device in
            CaptureDevice(id: device.uniqueID, name: device.localizedName)
        }
    }
    
    func setSelectedCamera(_ camera: CaptureDevice?) {
        selectedCameraDevice = camera
        guard cameraSessionIsRunning else {
            return
        }
        
        if camera == nil {
            stopCaptureSession()
        } else {
            configureCameraSession()
            startCameraCaptureSession()
        }
    }
    
    func setSelectedMicrophone(_ microphone: CaptureDevice?) async {
        do {
            try await updateCaptureConfiguration(selectedMicrophone: microphone)
        } catch {
            log.error("Failed to update stream configuration: \(error.localizedDescription)")
        }
    }
    
    func startCaptureSession() {
        guard selectedCameraDevice != nil else {
            return
        }
        
        cameraSessionIsRunning = true
        configureCameraSession()
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraCaptureSession)
        startCameraCaptureSession()
    }
    
    func stopCaptureSession() {
        cameraSessionIsRunning = false
        cameraPreviewLayer = nil
        
        cameraCaptureSession.beginConfiguration()
        for input in cameraCaptureSession.inputs {
            cameraCaptureSession.removeInput(input)
        }
        cameraCaptureSession.commitConfiguration()
        
        stopCameraCaptureSession()
    }
    
    func startBroadcast(session: BroadcastSession) async throws {
        let stream = await session.stream()
        await mediaMixer.setSessionPreset(.high)
        try await mediaMixer.setFrameRate(60)
        await mediaMixer.addOutput(stream)
        await mediaMixer.startRunning()
    }
    
    private func makeCaptureConfiguration(selectedMicrophone: CaptureDevice?) -> CaptureConfiguration {
        let screenFrame = NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 1920, height: 1080)
        let scaleFactor = Int(NSScreen.main?.backingScaleFactor ?? 2)
        
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
    
    private func makeStreamContentFilter() -> ContentFilter {
        .init(includeMenuBar: false, excludeCurrentApplication: excludeAppFromStream)
    }
    
    private func updateCaptureConfiguration(selectedMicrophone: CaptureDevice?) async throws {
        try await captureSystem.updateConfiguration(
            makeCaptureConfiguration(selectedMicrophone: selectedMicrophone),
        )
    }
    
    private func configureCameraSession() {
        cameraCaptureSession.beginConfiguration()
        defer { cameraCaptureSession.commitConfiguration() }
        
        cameraCaptureSession.sessionPreset = .high
        for input in cameraCaptureSession.inputs {
            cameraCaptureSession.removeInput(input)
        }
        
        do {
            guard let selectedCameraDevice else {
                return
            }
            
            guard
                let device = cameraDiscoverySession.devices.first(where: {
                    selectedCameraDevice.id == $0.uniqueID
                })
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
    
    private func startCameraCaptureSession() {
        let captureSession = cameraCaptureSession
        Task.detached(priority: .userInitiated) {
            guard !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }
    
    private func stopCameraCaptureSession() {
        let captureSession = cameraCaptureSession
        Task.detached(priority: .userInitiated) {
            guard captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }
}
