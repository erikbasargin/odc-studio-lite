//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import ScreenCaptureKit

struct BroadcastClient: Sendable {
    var bootstrap: @Sendable () async throws -> Void
    var snapshot: @Sendable () async -> BroadcastStateSnapshot
    var updates: @Sendable () async -> AsyncStream<BroadcastStateSnapshot>
    var setPrimaryStreamKey: @Sendable (String) async -> Void
    var setBandwidthTestEnabled: @Sendable (Bool) async -> Void
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
    static func live(_ broadcastManager: BroadcastManager) -> Self {
        Self(
            bootstrap: {
                try await broadcastManager.configureManager()

                var initialConfiguration = SCContentSharingPickerConfiguration()
                initialConfiguration.allowedPickerModes = [.singleDisplay]
                initialConfiguration.allowsChangingSelectedContent = true
                SCContentSharingPicker.shared.configuration = initialConfiguration
                SCContentSharingPicker.shared.isActive = true

                await broadcastManager.authorizeCamera()
            },
            snapshot: {
                await broadcastManager.broadcastStateSnapshot()
            },
            updates: {
                await broadcastManager.broadcastStateUpdates()
            },
            setPrimaryStreamKey: { primaryStreamKey in
                await broadcastManager.updatePrimaryStreamKey(primaryStreamKey)
            },
            setBandwidthTestEnabled: { bandwidthTestEnabled in
                await broadcastManager.updateBandwidthTestEnabled(bandwidthTestEnabled)
            },
            toggleBroadcast: {
                await broadcastManager.toogleBroadcast()
            }
        )
    }
}
