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
import Observation
import VideoToolbox
import Foundation

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastManager")

@MainActor
@Observable
final class BroadcastManager {

    @ObservationIgnored
    let streamConfiguration: StreamConfiguration

    var excludeAppFromStream = true {
        didSet {
            Task {
                await updateStreamContentFilter()
            }
        }
    }

    var captureMicrophone: Bool {
        get {
            streamConfiguration.selectedMicrophone != nil
        }
        set {
            guard newValue != captureMicrophone else {
                return
            }

            if newValue {
                streamConfiguration.selectedMicrophone = defaultMicrophoneDevice()
            } else {
                streamConfiguration.selectedMicrophone = nil
            }
        }
    }

    var bandwidthTestEnabled = false
    {
        didSet {
            notifyBroadcastStateDidChange()
        }
    }

    var primaryStreamKey = ""
    {
        didSet {
            notifyBroadcastStateDidChange()
        }
    }

    var cameraIsAuthorized = false {
        didSet {
            notifyBroadcastStateDidChange()
        }
    }

    var selectedCameraDevice: CaptureDevice? {
        get {
            streamConfiguration.selectedCamera
        }
        set {
            streamConfiguration.selectedCamera = newValue
        }
    }

    private(set) var isBroadcasting: Bool = false {
        didSet {
            notifyBroadcastStateDidChange()
        }
    }

    let cameraCaptureSession = AVCaptureSession()
    private let cameraDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .continuityCamera],
        mediaType: .video,
        position: .unspecified
    )
    
    private let mediaMixer = MediaMixer()
    private var rtmpConnectionStatusTask: Task<Void, Never>?
    private let captureSystem = CaptureSystem()
    private var session: (any Session)?
    
    @ObservationIgnored
    private var screenCaptureTask: Task<Void, Never>?
    @ObservationIgnored
    private var microphoneCaptureTask: Task<Void, Never>?
    
    @ObservationIgnored
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @ObservationIgnored
    private var broadcastStateContinuations: [UUID: AsyncStream<BroadcastStateSnapshot>.Continuation] = [:]
    
    private var scaleFactor: Int {
        Int(NSScreen.main?.backingScaleFactor ?? 2)
    }
    
    private var streamContentFilter: ContentFilter {
        .init(includeMenuBar: false, excludeCurrentApplication: excludeAppFromStream)
    }
    
    @ObservationIgnored
    private var captureConfiguration: CaptureConfiguration {
        let screenFrame = NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 1920, height: 1080)

        return .init(
            excludesCurrentProcessAudio: true,
            captureMicrophone: captureMicrophone,
            microphoneCaptureDeviceID: streamConfiguration.selectedMicrophone?.id,
            width: Int(screenFrame.width) * scaleFactor,
            height: Int(screenFrame.height) * scaleFactor,
            minimumFrameInterval: CMTime(value: 1, timescale: 60),
            queueDepth: 5
        )
    }

    init(streamConfiguration: StreamConfiguration = StreamConfiguration()) {
        self.streamConfiguration = streamConfiguration
        self.streamConfiguration.selectedCamera = AVCaptureDevice.systemPreferredCamera.map {
            CaptureDevice(id: $0.uniqueID, name: $0.localizedName)
        }
        observeStreamConfiguration()
    }

    deinit {
        screenCaptureTask?.cancel()
        microphoneCaptureTask?.cancel()
        for continuation in broadcastStateContinuations.values {
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
    
    func authorizeCamera() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            cameraIsAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        case .restricted, .denied:
            cameraIsAuthorized = false
        case .authorized:
            cameraIsAuthorized = true
        @unknown default:
            cameraIsAuthorized = false
        }
    }

    func updatePrimaryStreamKey(_ primaryStreamKey: String) {
        self.primaryStreamKey = primaryStreamKey
    }

    func updateBandwidthTestEnabled(_ bandwidthTestEnabled: Bool) {
        self.bandwidthTestEnabled = bandwidthTestEnabled
    }

    func updateSelectedCamera(_ camera: CaptureDevice?) {
        selectedCameraDevice = camera
        notifyBroadcastStateDidChange()
    }

    func updateSelectedMicrophone(_ microphone: CaptureDevice?) {
        streamConfiguration.selectedMicrophone = microphone
        notifyBroadcastStateDidChange()
    }

    func broadcastStateSnapshot() -> BroadcastStateSnapshot {
        BroadcastStateSnapshot(
            bandwidthTestEnabled: bandwidthTestEnabled,
            primaryStreamKey: primaryStreamKey,
            isBroadcasting: isBroadcasting,
            cameraIsAuthorized: cameraIsAuthorized,
            selectedCamera: selectedCameraDevice,
            selectedMicrophone: streamConfiguration.selectedMicrophone
        )
    }

    func broadcastStateUpdates() -> AsyncStream<BroadcastStateSnapshot> {
        let id = UUID()

        return AsyncStream { continuation in
            broadcastStateContinuations[id] = continuation
            continuation.yield(broadcastStateSnapshot())
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.broadcastStateContinuations.removeValue(forKey: id)
                }
            }
        }
    }
    
    func configureManager() async throws {
        await SessionBuilderFactory.shared.register(RTMPSessionFactory())

        try await captureSystem.updateConfiguration(captureConfiguration)
        try await captureSystem.updateContentFilter(streamContentFilter)
        try startConsumingCaptureStreams(from: captureSystem)

        try await captureSystem.start()
    }
    
    func toogleBroadcast() async {
        do {
            guard !isBroadcasting else {
                isBroadcasting = false
                await mediaMixer.stopRunning()
                
                try await session?.close()
                session = nil
                return
            }
            isBroadcasting = true
            
            await makeSession(primaryStreamKey: primaryStreamKey)
            
            guard let session else {
                log.error("Session is nil")
                return
            }
            
            let videoCodecSettings = VideoCodecSettings(
                videoSize: .init(width: 1920, height: 1080),
                bitRate: 6000 * 1000,
                profileLevel: kVTProfileLevel_H264_High_AutoLevel as String,
                bitRateMode: .constant,
                allowFrameReordering: false  // disable B frames
            )
            try await session.stream.setVideoSettings(videoCodecSettings)
            
            await mediaMixer.setSessionPreset(.high)
            try await mediaMixer.setFrameRate(Float64(captureConfiguration.minimumFrameInterval.timescale))
            
            await mediaMixer.addOutput(session.stream)
            await mediaMixer.startRunning()
            
            try await session.connect {
                Task { @MainActor in
                    self.isBroadcasting = false
                }
            }
        } catch RTMPConnection.Error.requestFailed {
            log.error("RTMP connection request failed")
            isBroadcasting = false
        } catch RTMPStream.Error.requestFailed {
            log.error("RTMP stream request failed")
            isBroadcasting = false
        } catch {
            log.error("\(error.localizedDescription)")
            isBroadcasting = false
        }
    }
    
    private func makeSession(primaryStreamKey: String) async {
        do {
            if session != nil {
                try await session?.close()
                session = nil
            }
            
            // TODO: - Add bandwidthtest
            guard let url = URL(string: "rtmps://ingest.global-contribute.live-video.net/app/\(primaryStreamKey)") else {
                fatalError("Broadcast URL is not valid")
            }
            
            session = try await SessionBuilderFactory.shared.make(url)
                .setMode(.publish)
                .build()
            
            await session?.setMaxRetryCount(0)
            
            guard let session else {
                fatalError("Session is not available")
            }
            
            rtmpConnectionStatusTask?.cancel()
            rtmpConnectionStatusTask = Task {
                for await readyState in await session.readyState {
                    let description = switch readyState {
                    case .connecting:
                        "Connecting..."
                    case .open:
                        "Open"
                    case .closing:
                        "Closing..."
                    case .closed:
                        "Closed"
                    }
                    
                    log.info("RTMP connection status: \(description)")
                }
            }
        } catch {
            session = nil
            log.error("Cannot create session: \(error.localizedDescription)")
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

    private func observeStreamConfiguration() {
        withObservationTracking {
            _ = streamConfiguration.selectedCamera
            _ = streamConfiguration.selectedMicrophone
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }

                configureCameraSession()
                await updateStreamConfiguration()
                notifyBroadcastStateDidChange()
                observeStreamConfiguration()
            }
        }
    }

    private func defaultMicrophoneDevice() -> CaptureDevice? {
        AVCaptureDevice.default(for: .audio).map { device in
            CaptureDevice(id: device.uniqueID, name: device.localizedName)
        }
    }

    private func notifyBroadcastStateDidChange() {
        let snapshot = broadcastStateSnapshot()
        for continuation in broadcastStateContinuations.values {
            continuation.yield(snapshot)
        }
    }
    
    private func startConsumingCaptureStreams(from captureSystem: CaptureSystem) throws {
        let screenCaptureStream = try captureSystem.screenCaptureStream
        let microphoneCaptureStream = try captureSystem.microphoneCaptureStream
        
        func listenVideoStream(stream: CaptureSystem.CaptureStream<CaptureSystem.Screen>, on mixer: isolated MediaMixer) async {
            for await payload in stream where mixer.isRunning {
                guard SCVideoMetadata(payload.sample)?.status == .complete else {
                    continue
                }
                
                payload.sample.withUnsafeSampleBuffer { sampleBuffer in
                    mixer.append(sampleBuffer, track: 0)
                }
            }
        }
        
        func listenMicrophone(stream: CaptureSystem.CaptureStream<CaptureSystem.Microphone>, on mixer: isolated MediaMixer) async {
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
