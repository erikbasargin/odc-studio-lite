//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Capture
import HaishinKit
import OSLog
import Observation
@preconcurrency import ScreenCaptureKit
import VideoToolbox

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastManager")

struct Device: Identifiable, Hashable {
    let id: String
    let name: String
}

@MainActor
@Observable
final class BroadcastManager {
    
    var excludeAppFromStream = true {
        didSet {
            Task {
                await updateStreamContentFilter()
            }
        }
    }
    
    var captureMicrophone = false {
        didSet {
            Task {
                await updateStreamConfiguration()
            }
        }
    }
    
    var bandwidthTestEnabled = false
    
    var primaryStreamKey = ""
    
    var cameraIsAuthorized = false
    
    var selectedCameraDevice: Device? {
        didSet {
            configureCameraSession()
        }
    }
    
    private(set) var isBroadcasting: Bool = false
    private(set) var videoDevices: [Device] = []
    
    let cameraCaptureSession = AVCaptureSession()
    private let cameraDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .continuityCamera],
        mediaType: .video,
        position: .unspecified
    )
    
    private let streamDelegate: StreamDelegate
    private let screenStreamOutput: StreamOutput
    private let microphoneStreamOutput: StreamOutput
    
    private let rtmpConnection: RTMPConnection
    private let rtmpStream: RTMPStream
    private let mediaMixer: MediaMixer
    private var rtmpConnectionStatusTask: Task<Void, Never>!
    
    @ObservationIgnored
    private var stream: SCStream!
    
    @ObservationIgnored
    private var currentShareableContent: SCShareableContent!
    
    @ObservationIgnored
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var currentDisplay: SCDisplay {
        currentShareableContent.displays.first!
    }
    
    private var scaleFactor: Int {
        Int(NSScreen.main?.backingScaleFactor ?? 2)
    }
    
    private var streamContentFilter: SCContentFilter {
        get async throws {
            let excludingApplications: [SCRunningApplication] =
                if excludeAppFromStream {
                    currentShareableContent.applications.filter {
                        $0.bundleIdentifier == Bundle.main.bundleIdentifier
                    }
                } else {
                    []
                }

            return SCContentFilter(
                display: currentDisplay, excludingApplications: excludingApplications, exceptingWindows: [])
        }
    }
    
    @ObservationIgnored
    private var streamConfiguration: SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        
        configuration.excludesCurrentProcessAudio = true
        
        if configuration.captureMicrophone != captureMicrophone {
            configuration.captureMicrophone = captureMicrophone
            
            if captureMicrophone {
                configuration.microphoneCaptureDeviceID = AVCaptureDevice.default(for: .audio)?.uniqueID
            }
        }
        
        // Configure the display content width and height.
        configuration.width = currentDisplay.width * scaleFactor
        configuration.height = currentDisplay.height * scaleFactor
        
        // Set the capture interval at 60 fps.
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        configuration.queueDepth = 5
        
        return configuration
    }
    
    init() {
        rtmpConnection = RTMPConnection(requestTimeout: 5000)  // 5s
        rtmpStream = RTMPStream(connection: rtmpConnection)
        mediaMixer = MediaMixer()
        streamDelegate = StreamDelegate()
        screenStreamOutput = StreamOutput(type: .screen, rtmpSession: mediaMixer)
        microphoneStreamOutput = StreamOutput(type: .microphone, rtmpSession: mediaMixer)
        
        let task = Task {
            for await rtmpStatus in await rtmpConnection.status {
                let rtmpConnectionCode = RTMPConnection.Code(rawValue: rtmpStatus.code)
                if let rtmpConnectionCode {
                    if rtmpConnectionCode.level == "error" {
                        log.error("RTMP connection status: \(rtmpStatus.code)")
                    } else {
                        log.info("RTMP connection status: \(rtmpStatus.code)")
                    }
                } else {
                    if rtmpStatus.level == "error" {
                        log.error("RTMP connection status. Code: \(rtmpStatus.code); \(rtmpStatus.description)")
                    } else {
                        log.info("RTMP connection status. Code: \(rtmpStatus.code); \(rtmpStatus.description)")
                    }
                }
                
                guard rtmpStatus.level == "error" || rtmpConnectionCode != .connectSuccess else {
                    continue
                }
                
                isBroadcasting = false
            }
        }
        
        rtmpConnectionStatusTask = task
    }
    
    deinit {
        stream.stopCapture { error in
            if let error {
                log.error("Failed to stop stream capture: \(error.localizedDescription)")
            }
        }
    }
    
    func listenForVideoDevices() async {
        selectedCameraDevice = AVCaptureDevice.systemPreferredCamera.map { device in
            Device(id: device.uniqueID, name: device.localizedName)
        }
        
        for await devices in cameraDiscoverySession.publisher(for: \.devices).values {
            videoDevices = devices.map { device in
                Device(id: device.uniqueID, name: device.localizedName)
            }
        }
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
                cameraCaptureSession.inputs.forEach { input in
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
    
    func configureManager() async throws {
        currentShareableContent = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: false)
        
        stream = try await SCStream(
            filter: streamContentFilter, configuration: streamConfiguration, delegate: streamDelegate)
        
        try stream.addStreamOutput(screenStreamOutput)
        try stream.addStreamOutput(microphoneStreamOutput)  // use SCStreamConfiguration/captureMicrophone to switch it on/off
        
        await mediaMixer.addOutput(rtmpStream)
        
        try await stream.startCapture()
    }
    
    func toogleBroadcast() async {
        do {
            guard !isBroadcasting else {
                await mediaMixer.stopRunning()
                try await rtmpConnection.close()
                isBroadcasting = false
                return
            }
            isBroadcasting = true
            
            let connectResponse = try await rtmpConnection.connect("rtmps://lhr08.contribute.live-video.net/app/")
            log.info("Connection with Twitch RTMP server, status: \(connectResponse.status?.description ?? "unknown")")
            
            let videoCodecSettings = VideoCodecSettings(
                videoSize: .init(width: 1920, height: 1080),
                bitRate: 6000 * 1000,
                profileLevel: kVTProfileLevel_H264_High_AutoLevel as String,
                bitRateMode: .constant,
                allowFrameReordering: false  // disable B frames
            )
            
            await rtmpStream.setVideoSettings(videoCodecSettings)
            
            // TODO: - Check why it did not work with `bandwidthtest=false` set
            let publishName = bandwidthTestEnabled ? "\(primaryStreamKey)?bandwidthtest=true" : primaryStreamKey
            let publishResponse = try await rtmpStream.publish(publishName)
            log.info("Publishing to Twitch RTMP server, status: \(publishResponse.status?.description ?? "unknown")")
            
            await mediaMixer.setSessionPreset(.high)
            await mediaMixer.setFrameRate(Float64(streamConfiguration.minimumFrameInterval.timescale))
            await mediaMixer.startRunning()
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
    
    private func updateStreamContentFilter() async {
        do {
            try await stream.updateContentFilter(streamContentFilter)
        } catch {
            log.error(
                "Failed to update stream content filter: \(error.localizedDescription)"
            )
        }
    }
    
    private func updateStreamConfiguration() async {
        do {
            try await stream.updateConfiguration(streamConfiguration)
        } catch {
            log.error(
                "Failed to update stream configuration: \(error.localizedDescription)"
            )
        }
    }
}

private final class StreamDelegate: NSObject, SCStreamDelegate {
    
    func stream(_ stream: SCStream, didStopWithError error: any Error) {
        log.error("Stream stopped with error: \(error.localizedDescription)")
    }
}

private final class StreamOutput: NSObject, SCStreamOutput {
    
    let type: SCStreamOutputType
    let rtmpSession: MediaMixer
    let queue: DispatchQueue
    
    private let continuation: AsyncStream<CMSampleBuffer>.Continuation
    private let task: Task<Void, Never>
    
    init(type: SCStreamOutputType, rtmpSession: MediaMixer, track: UInt8 = 0) {
        self.type = type
        self.rtmpSession = rtmpSession
        queue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).BroadcastManager.streamOutputQueue.\(type)")
        let (sampleBuffers, continuation) = AsyncStream.makeStream(
            of: CMSampleBuffer.self, bufferingPolicy: .bufferingNewest(1))
        self.continuation = continuation
        
        func listenForSampleBuffers(stream: AsyncStream<CMSampleBuffer>, on mixer: isolated MediaMixer) async {
            for await sampleBuffer in stream where mixer.isRunning {
                mixer.append(sampleBuffer, track: track)
            }
        }
        
        task = Task {
            await listenForSampleBuffers(stream: sampleBuffers, on: rtmpSession)
        }
    }
    
    deinit {
        task.cancel()
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard sampleBuffer.isValid else {
            return
        }
        
        switch type {
        case .screen:
            guard SCVideoMetadata(sampleBuffer)?.status == .complete else {
                return
            }
            
            precondition(
                sampleBuffer.formatDescription?.isCompressed == false,
                "Compressed sample buffers are not supported"
            )
            
            continuation.yield(sampleBuffer)
        case .microphone:
            continuation.yield(sampleBuffer)
        case .audio:
            break
        @unknown default:
            break
        }
    }
}

extension SCStream {
    
    fileprivate func addStreamOutput(_ output: StreamOutput) throws {
        try addStreamOutput(output, type: output.type, sampleHandlerQueue: output.queue)
    }
    
    fileprivate func removeStreamOutput(_ output: StreamOutput) throws {
        try removeStreamOutput(output, type: output.type)
    }
}
