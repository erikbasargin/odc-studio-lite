//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import ScreenCaptureKit

import AudioVideoKit

struct BroadcastClient: Sendable {
    var bootstrap: @Sendable () async throws -> Void
    var snapshot: @Sendable () async -> BroadcastConfiguration
    var updates: @Sendable () async -> AsyncStream<BroadcastConfiguration>
    var setPrimaryStreamKey: @Sendable (String) async -> Void
    var setBandwidthTestEnabled: @Sendable (Bool) async -> Void
    var setCaptureMicrophone: @Sendable (Bool) async -> Void
    var setSelectedCamera: @Sendable (CaptureDevice?) async -> Void
    var setSelectedMicrophone: @Sendable (CaptureDevice?) async -> Void
    var toggleBroadcast: @Sendable () async -> Void
}

extension BroadcastClient: DependencyKey {
    static let liveValue = Self.unimplemented
    static let testValue = Self.unimplemented

    private static let unimplemented = Self(
        bootstrap: {},
        snapshot: { .init() },
        updates: { AsyncStream { _ in } },
        setPrimaryStreamKey: { _ in },
        setBandwidthTestEnabled: { _ in },
        setCaptureMicrophone: { _ in },
        setSelectedCamera: { _ in },
        setSelectedMicrophone: { _ in },
        toggleBroadcast: {}
    )
}

extension DependencyValues {
    var broadcastClient: BroadcastClient {
        get { self[BroadcastClient.self] }
        set { self[BroadcastClient.self] = newValue }
    }
}

extension BroadcastClient {
    static func live(
        _ broadcastManager: BroadcastManager,
        cameraAuthorizationService: CameraAuthorizationService = .liveValue,
        broadcastSessionBuilder: BroadcastSessionBuilder = .init()
    ) -> Self {
        Self(
            bootstrap: {
                try await broadcastManager.configureManager()
                await BroadcastSessionBuilder.configure()

                var initialConfiguration = SCContentSharingPickerConfiguration()
                initialConfiguration.allowedPickerModes = [.singleDisplay]
                initialConfiguration.allowsChangingSelectedContent = true
                SCContentSharingPicker.shared.configuration = initialConfiguration
                SCContentSharingPicker.shared.isActive = true

                let isAuthorized = await cameraAuthorizationService.authorize()
                await broadcastManager.updateCameraAuthorization(isAuthorized)
            },
            snapshot: {
                await broadcastManager.broadcastConfiguration()
            },
            updates: {
                await broadcastManager.broadcastConfigurationUpdates()
            },
            setPrimaryStreamKey: { primaryStreamKey in
                await broadcastManager.updatePrimaryStreamKey(primaryStreamKey)
            },
            setBandwidthTestEnabled: { bandwidthTestEnabled in
                await broadcastManager.updateBandwidthTestEnabled(bandwidthTestEnabled)
            },
            setCaptureMicrophone: { isEnabled in
                await broadcastManager.updateCaptureMicrophone(isEnabled)
            },
            setSelectedCamera: { camera in
                await broadcastManager.updateSelectedCamera(camera)
            },
            setSelectedMicrophone: { microphone in
                await broadcastManager.updateSelectedMicrophone(microphone)
            },
            toggleBroadcast: {
                let configuration = await broadcastManager.broadcastConfiguration()
                if configuration.isBroadcasting {
                    await broadcastManager.stopBroadcast()
                } else {
                    let session = try? await broadcastSessionBuilder.makeBroadcastSession(
                        primaryStreamKey: configuration.primaryStreamKey
                    )
                    await broadcastManager.startBroadcast(broadcastSession: session)
                }
            }
        )
    }
}
