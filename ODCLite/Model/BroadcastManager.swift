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
    
    var primaryStreamKey = ""
    
    private let streamDelegate = StreamDelegate()
    private let screenStreamOutput = StreamOutput(type: .screen)
    private let audioStreamOutput = StreamOutput(type: .audio)
    private let microphoneStreamOutput = StreamOutput(type: .microphone)
   
    @ObservationIgnored
    private var stream: SCStream!
    
    @ObservationIgnored
    private var streamContentFilter: SCContentFilter {
        get async throws {
            let shareableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            let display = shareableContent.displays.first!
            let excludingApplications: [SCRunningApplication] = if excludeAppFromStream {
                shareableContent.applications.filter { $0.bundleIdentifier == Bundle.main.bundleIdentifier }
            } else {
                []
            }
            
            return SCContentFilter(display: display, excludingApplications: excludingApplications, exceptingWindows: [])
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
        
        return configuration
    }
    
    deinit {
        stream.stopCapture { error in
            if let error {
                log.error("Failed to stop stream capture: \(error.localizedDescription)")
            }
        }
    }

    func configureManager() async throws {
        stream = try await SCStream(filter: streamContentFilter, configuration: streamConfiguration, delegate: streamDelegate)
        
        try stream.addStreamOutput(screenStreamOutput)
        try stream.addStreamOutput(audioStreamOutput) // use SCStreamConfiguration/capturesAudio to switch it on/off
        try stream.addStreamOutput(microphoneStreamOutput) // use SCStreamConfiguration/captureMicrophone to switch it on/off
        
        try await stream.startCapture()
    }
    
    func toogleBroadcast() {}
    
    private func updateStreamContentFilter() async {
        do {
            try await stream.updateContentFilter(streamContentFilter)
        } catch {
            log.error("Failed to update stream content filter: \(error.localizedDescription)")
        }
    }
    
    private func updateStreamConfiguration() async {
        do {
            try await stream.updateConfiguration(streamConfiguration)
        } catch {
            log.error("Failed to update stream configuration: \(error.localizedDescription)")
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
    let queue: DispatchQueue
    
    init(type: SCStreamOutputType) {
        self.type = type
        queue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).BroadcastManager.streamOutputQueue.\(type)")
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        
    }
}

private extension SCStream {
    
    func addStreamOutput(_ output: StreamOutput) throws {
        try addStreamOutput(output, type: output.type, sampleHandlerQueue: output.queue)
    }
    
    func removeStreamOutput(_ output: StreamOutput) throws {
        try removeStreamOutput(output, type: output.type)
    }
}
