import ComposableArchitecture
import AudioVideoKit
@testable import ODCLite

actor BroadcastClientProbe {
    private var bootstrapInvocationCount = 0
    private var primaryStreamKeyValues: [String] = []
    private var bandwidthTestEnabledValues: [Bool] = []
    private var microphoneCaptureRequests: [Bool] = []
    private var selectedCameras: [CaptureDevice?] = []
    private var selectedMicrophones: [CaptureDevice?] = []
    private var toggleInvocationCount = 0

    func recordBootstrap() {
        bootstrapInvocationCount += 1
    }

    func recordPrimaryStreamKey(_ primaryStreamKey: String) {
        primaryStreamKeyValues.append(primaryStreamKey)
    }

    func recordBandwidthTestEnabled(_ bandwidthTestEnabled: Bool) {
        bandwidthTestEnabledValues.append(bandwidthTestEnabled)
    }

    func recordCaptureMicrophone(_ isEnabled: Bool) {
        microphoneCaptureRequests.append(isEnabled)
    }

    func recordSelectedCamera(_ camera: CaptureDevice?) {
        selectedCameras.append(camera)
    }

    func recordSelectedMicrophone(_ microphone: CaptureDevice?) {
        selectedMicrophones.append(microphone)
    }

    func recordToggleBroadcast() {
        toggleInvocationCount += 1
    }

    func bootstrapCount() -> Int {
        bootstrapInvocationCount
    }

    func primaryStreamKeys() -> [String] {
        primaryStreamKeyValues
    }

    func bandwidthTestValues() -> [Bool] {
        bandwidthTestEnabledValues
    }

    func captureMicrophoneValues() -> [Bool] {
        microphoneCaptureRequests
    }

    func selectedCameraValues() -> [CaptureDevice?] {
        selectedCameras
    }

    func selectedMicrophoneValues() -> [CaptureDevice?] {
        selectedMicrophones
    }

    func toggleBroadcastCount() -> Int {
        toggleInvocationCount
    }
}

extension BroadcastClient {
    static func mock(
        bootstrap: @escaping @Sendable () async throws -> Void = {},
        snapshot: @escaping @Sendable () async -> BroadcastConfiguration = { .init() },
        updates: @escaping @Sendable () async -> AsyncStream<BroadcastConfiguration> = {
            AsyncStream { continuation in
                continuation.finish()
            }
        },
        setPrimaryStreamKey: @escaping @Sendable (String) async -> Void = { _ in },
        setBandwidthTestEnabled: @escaping @Sendable (Bool) async -> Void = { _ in },
        setCaptureMicrophone: @escaping @Sendable (Bool) async -> Void = { _ in },
        setSelectedCamera: @escaping @Sendable (CaptureDevice?) async -> Void = { _ in },
        setSelectedMicrophone: @escaping @Sendable (CaptureDevice?) async -> Void = { _ in },
        toggleBroadcast: @escaping @Sendable () async -> Void = {}
    ) -> Self {
        Self(
            bootstrap: bootstrap,
            snapshot: snapshot,
            updates: updates,
            setPrimaryStreamKey: setPrimaryStreamKey,
            setBandwidthTestEnabled: setBandwidthTestEnabled,
            setCaptureMicrophone: setCaptureMicrophone,
            setSelectedCamera: setSelectedCamera,
            setSelectedMicrophone: setSelectedMicrophone,
            toggleBroadcast: toggleBroadcast
        )
    }
}
