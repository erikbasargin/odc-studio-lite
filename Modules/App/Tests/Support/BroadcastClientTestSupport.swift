import ComposableArchitecture
import AudioVideoKit
@testable import ODCLite

actor BroadcastClientProbe {
    private var bootstrapInvocationCount = 0
    private var bootstrapMicrophones: [CaptureDevice?] = []
    private var defaultMicrophone: CaptureDevice?
    private var selectedCameras: [CaptureDevice?] = []
    private var selectedMicrophones: [CaptureDevice?] = []
    private var startBroadcastRequests: [(primaryStreamKey: String, selectedMicrophone: CaptureDevice?)] = []
    private var stopBroadcastInvocationCount = 0

    func recordBootstrap(selectedMicrophone: CaptureDevice?) {
        bootstrapInvocationCount += 1
        bootstrapMicrophones.append(selectedMicrophone)
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

    func recordStartBroadcast(
        primaryStreamKey: String,
        selectedMicrophone: CaptureDevice?
    ) {
        startBroadcastRequests.append(
            (primaryStreamKey: primaryStreamKey, selectedMicrophone: selectedMicrophone)
        )
    }

    func recordStopBroadcast() {
        stopBroadcastInvocationCount += 1
    }

    func bootstrapCount() -> Int {
        bootstrapInvocationCount
    }

    func bootstrapSelectedMicrophones() -> [CaptureDevice?] {
        bootstrapMicrophones
    }

    func selectedCameraValues() -> [CaptureDevice?] {
        selectedCameras
    }

    func selectedMicrophoneValues() -> [CaptureDevice?] {
        selectedMicrophones
    }

    func startBroadcastValues() -> [(primaryStreamKey: String, selectedMicrophone: CaptureDevice?)] {
        startBroadcastRequests
    }

    func stopBroadcastCount() -> Int {
        stopBroadcastInvocationCount
    }
}

extension BroadcastClient {
    static func mock(
        bootstrap: @escaping @Sendable (CaptureDevice?) async throws -> Bool = { _ in false },
        defaultMicrophone: @escaping @Sendable () async -> CaptureDevice? = { nil },
        setSelectedCamera: @escaping @Sendable (CaptureDevice?) async -> Void = { _ in },
        setSelectedMicrophone: @escaping @Sendable (CaptureDevice?) async -> Void = { _ in },
        startBroadcast: @escaping @Sendable (
            String,
            CaptureDevice?,
            @escaping @Sendable () async -> Void
        ) async throws -> Void = { _, _, _ in },
        stopBroadcast: @escaping @Sendable () async -> Void = {}
    ) -> Self {
        Self(
            bootstrap: bootstrap,
            defaultMicrophone: defaultMicrophone,
            setSelectedCamera: setSelectedCamera,
            setSelectedMicrophone: setSelectedMicrophone,
            startBroadcast: startBroadcast,
            stopBroadcast: stopBroadcast
        )
    }
}
