import ComposableArchitecture
@testable import ODCLite

actor BroadcastClientProbe {
    private var bootstrapInvocationCount = 0
    private var primaryStreamKeyValues: [String] = []
    private var bandwidthTestEnabledValues: [Bool] = []
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

    func toggleBroadcastCount() -> Int {
        toggleInvocationCount
    }
}

extension BroadcastClient {
    static func mock(
        bootstrap: @escaping @Sendable () async throws -> Void = {},
        snapshot: @escaping @Sendable () async -> BroadcastStateSnapshot = { .init() },
        updates: @escaping @Sendable () async -> AsyncStream<BroadcastStateSnapshot> = {
            AsyncStream { continuation in
                continuation.finish()
            }
        },
        setPrimaryStreamKey: @escaping @Sendable (String) async -> Void = { _ in },
        setBandwidthTestEnabled: @escaping @Sendable (Bool) async -> Void = { _ in },
        toggleBroadcast: @escaping @Sendable () async -> Void = {}
    ) -> Self {
        Self(
            bootstrap: bootstrap,
            snapshot: snapshot,
            updates: updates,
            setPrimaryStreamKey: setPrimaryStreamKey,
            setBandwidthTestEnabled: setBandwidthTestEnabled,
            toggleBroadcast: toggleBroadcast
        )
    }
}
