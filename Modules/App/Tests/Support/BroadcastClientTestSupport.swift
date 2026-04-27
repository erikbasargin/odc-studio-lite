import AudioVideoKit
import BroadcastFeature
import ComposableArchitecture

@testable import ODCLite

actor AppClientProbe {
    private var bootstrapInvocationCount = 0
    private var defaultMicrophone: CaptureDevice?
    private var selectedCameras: [CaptureDevice?] = []
    private var selectedMicrophones: [CaptureDevice?] = []
    private var startCaptureSessionInvocationCount = 0
    private var stopCaptureSessionInvocationCount = 0
    private var startBroadcastRequests: [String] = []
    private var attachedBroadcastSessions: [BroadcastSession] = []
    private var stoppedBroadcastSessions: [BroadcastSession?] = []
    
    func recordBootstrap() {
        bootstrapInvocationCount += 1
    }
    
    func recordSelectedCamera(_ camera: CaptureDevice?) {
        selectedCameras.append(camera)
    }
    
    func recordSelectedMicrophone(_ microphone: CaptureDevice?) {
        selectedMicrophones.append(microphone)
    }
    
    func setDefaultMicrophone(_ microphone: CaptureDevice?) {
        defaultMicrophone = microphone
    }
    
    func resolveDefaultMicrophone() -> CaptureDevice? {
        defaultMicrophone
    }
    
    func recordStartBroadcast(primaryStreamKey: String) {
        startBroadcastRequests.append(primaryStreamKey)
    }
    
    func recordAttachedBroadcastSession(_ session: BroadcastSession) {
        attachedBroadcastSessions.append(session)
    }
    
    func recordStoppedBroadcastSession(_ session: BroadcastSession?) {
        stoppedBroadcastSessions.append(session)
    }
    
    func recordStartCaptureSession() {
        startCaptureSessionInvocationCount += 1
    }
    
    func recordStopCaptureSession() {
        stopCaptureSessionInvocationCount += 1
    }
    
    func bootstrapCount() -> Int {
        bootstrapInvocationCount
    }
    
    func selectedCameraValues() -> [CaptureDevice?] {
        selectedCameras
    }
    
    func selectedMicrophoneValues() -> [CaptureDevice?] {
        selectedMicrophones
    }
    
    func startBroadcastValues() -> [String] {
        startBroadcastRequests
    }
    
    func attachedBroadcastSessionCount() -> Int {
        attachedBroadcastSessions.count
    }
    
    func stoppedBroadcastSessionCount() -> Int {
        stoppedBroadcastSessions.count
    }
    
    func startCaptureSessionCount() -> Int {
        startCaptureSessionInvocationCount
    }
    
    func stopCaptureSessionCount() -> Int {
        stopCaptureSessionInvocationCount
    }
}

extension CaptureClient {
    static func mock(
        bootstrap: @escaping @Sendable () async throws -> Bool = { false },
        defaultMicrophone: @escaping @Sendable () async -> CaptureDevice? = { nil },
        setSelectedCamera: @escaping @Sendable (CaptureDevice?) async -> Void = { _ in },
        setSelectedMicrophone: @escaping @Sendable (CaptureDevice?) async -> Void = { _ in },
        startCaptureSession: @escaping @Sendable () async -> Void = {},
        stopCaptureSession: @escaping @Sendable () async -> Void = {},
        startBroadcast: @escaping @Sendable (BroadcastSession) async throws -> Void = { _ in }
    ) -> Self {
        Self(
            bootstrap: bootstrap,
            defaultMicrophone: defaultMicrophone,
            setSelectedCamera: setSelectedCamera,
            setSelectedMicrophone: setSelectedMicrophone,
            startCaptureSession: startCaptureSession,
            stopCaptureSession: stopCaptureSession,
            startBroadcast: startBroadcast
        )
    }
}
