//
//  This source file is part of the ODCLite open source project
//
//  Copyright (c) 2024 Erik Basargin
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import VideoToolbox
import HaishinKit
import Observation
@preconcurrency import ScreenCaptureKit
import os

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastManager")

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

    var captureSystemAudio = true {
        didSet {
            Task {
                await updateStreamConfiguration()
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

    var excludeAppAudio = false {
        didSet {
            Task {
                await updateStreamConfiguration()
            }
        }
    }
    
    var bandwidthTestEnabled = false

    var primaryStreamKey = ""
    
    private(set) var isBroadcasting: Bool = false

    private let streamDelegate: StreamDelegate
    private let screenStreamOutput: StreamOutput
    private let audioStreamOutput: StreamOutput
    private let microphoneStreamOutput: StreamOutput
    
    private let rtmpConnection: RTMPConnection
    private let rtmpStream: RTMPStream
    private let mediaMixer: MediaMixer
    private var rtmpConnectionStatusTask: Task<Void, Never>!
    
    @ObservationIgnored
    private var stream: SCStream!
    
    @ObservationIgnored
    private var currentShareableContent: SCShareableContent!
    
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

            return SCContentFilter(display: currentDisplay, excludingApplications: excludingApplications, exceptingWindows: [])
        }
    }

    @ObservationIgnored
    private var streamConfiguration: SCStreamConfiguration {
        let configuration = SCStreamConfiguration()

        configuration.capturesAudio = captureSystemAudio
        configuration.excludesCurrentProcessAudio = excludeAppAudio

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
        rtmpConnection = RTMPConnection(requestTimeout: 5000) // 5s
        rtmpStream = RTMPStream(connection: rtmpConnection)
        mediaMixer = MediaMixer()
        streamDelegate = StreamDelegate()
        screenStreamOutput = StreamOutput(type: .screen, rtmpSession: mediaMixer)
        audioStreamOutput = StreamOutput(type: .audio, rtmpSession: mediaMixer)
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

    func configureManager() async throws {
        currentShareableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        
        stream = try await SCStream(filter: streamContentFilter, configuration: streamConfiguration, delegate: streamDelegate)

        try stream.addStreamOutput(screenStreamOutput)
        try stream.addStreamOutput(audioStreamOutput)  // use SCStreamConfiguration/capturesAudio to switch it on/off
        try stream.addStreamOutput(microphoneStreamOutput)  // use SCStreamConfiguration/captureMicrophone to switch it on/off

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
            
            let connectResponse = try await rtmpConnection.connect( "rtmps://lhr08.contribute.live-video.net/app/")
            log.info("Connection with Twitch RTMP server, status: \(connectResponse.status?.description ?? "unknown")")
            
            let videoCodecSettings = VideoCodecSettings(
                videoSize: .init(width: 1920, height: 1080),
                bitRate: 6000 * 1000,
                profileLevel: kVTProfileLevel_H264_High_AutoLevel as String,
                bitRateMode: .constant,
                allowFrameReordering: false // disable B frames
            )
            
            await rtmpStream.setVideoSettings(videoCodecSettings)
            
            let publishName = "\(primaryStreamKey)?bandwidthtest=\(bandwidthTestEnabled)"
            let publishResponse = try await rtmpStream.publish(publishName)
            log.info("Publishing to Twitch RTMP server, status: \(publishResponse.status?.description ?? "unknown")")
            
            await mediaMixer.setSessionPreset(.high)
            await mediaMixer.setFrameRate(Float64(streamConfiguration.minimumFrameInterval.timescale))
            await mediaMixer.addOutput(rtmpStream)
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

    init(type: SCStreamOutputType, rtmpSession: MediaMixer) {
        self.type = type
        self.rtmpSession = rtmpSession
        queue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).BroadcastManager.streamOutputQueue.\(type)")
        let (values, continuation) = AsyncStream.makeStream(of: CMSampleBuffer.self, bufferingPolicy: .bufferingNewest(1))
        self.continuation = continuation
        
        func listenForSampleBuffers(stream: AsyncStream<CMSampleBuffer>, on mixer: isolated MediaMixer) async {
            for await sampleBuffer in stream where mixer.isRunning {
                mixer.append(sampleBuffer)
            }
        }
        
        task = Task {
            await listenForSampleBuffers(stream: values, on: rtmpSession)
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
            guard sampleBuffer.videoMetadata?.status == .complete else {
                return
            }
            
            precondition(
                sampleBuffer.formatDescription?.isCompressed == false,
                "Compressed sample buffers are not supported"
            )
            
            continuation.yield(sampleBuffer)
        case .audio:
            break
        case .microphone:
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
