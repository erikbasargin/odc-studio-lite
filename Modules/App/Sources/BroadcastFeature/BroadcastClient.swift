//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import OSLog

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastClient")

struct BroadcastClient: Sendable {
    var startBroadcast: @Sendable (
        String,
        @escaping @Sendable () async -> Void
    ) async throws -> Void
    var stopBroadcast: @Sendable () async -> Void
}

extension BroadcastClient: DependencyKey {
    static let liveValue = Self.unimplemented
    static let testValue = Self.unimplemented

    private static let unimplemented = Self(
        startBroadcast: { _, _ in },
        stopBroadcast: {}
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
        _ captureRuntime: CaptureRuntime,
        broadcastSessionBuilder: BroadcastSessionBuilder = .init()
    ) -> Self {
        let runtime = LiveBroadcastRuntime(
            captureRuntime: captureRuntime,
            broadcastSessionBuilder: broadcastSessionBuilder
        )

        return Self(
            startBroadcast: { primaryStreamKey, disconnected in
                try await runtime.startBroadcast(
                    primaryStreamKey: primaryStreamKey,
                    disconnected: disconnected
                )
            },
            stopBroadcast: {
                await runtime.stopBroadcast()
            }
        )
    }
}

private actor LiveBroadcastRuntime {

    private let captureRuntime: CaptureRuntime
    private let broadcastSessionBuilder: BroadcastSessionBuilder
    private var broadcastSession: BroadcastSession?

    init(
        captureRuntime: CaptureRuntime,
        broadcastSessionBuilder: BroadcastSessionBuilder
    ) {
        self.captureRuntime = captureRuntime
        self.broadcastSessionBuilder = broadcastSessionBuilder
    }

    func startBroadcast(
        primaryStreamKey: String,
        disconnected: @escaping @Sendable () async -> Void
    ) async throws {
        await stopBroadcast()

        do {
            await BroadcastSessionBuilder.configure()
            let session = try await broadcastSessionBuilder.makeBroadcastSession(
                primaryStreamKey: primaryStreamKey
            )
            broadcastSession = session

            let stream = await session.stream()
            try await captureRuntime.startBroadcast(stream: stream)
            try await session.connect { [weak self] in
                Task {
                    await self?.stopBroadcast()
                    await disconnected()
                }
            }
        } catch {
            log.error("\(error.localizedDescription)")
            await stopBroadcast()
            throw error
        }
    }

    func stopBroadcast() async {
        guard broadcastSession != nil else {
            return
        }

        await captureRuntime.stopBroadcast()

        do {
            try await broadcastSession?.close()
            broadcastSession = nil
        } catch {
            log.error("Error closing session: \(error.localizedDescription)")
            broadcastSession = nil
        }
    }
}
