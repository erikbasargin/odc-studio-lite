//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import HaishinKit
import OSLog

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastSession")

struct BroadcastSession {

    struct InvalidBroadcastURLError: Error {}
    struct MissingSessionError: Error {}

    private let session: any Session
    private let readyStateTask: Task<Void, Never>

    init(primaryStreamKey: String) async throws {
        guard let url = URL(string: "rtmps://ingest.global-contribute.live-video.net/app/\(primaryStreamKey)") else {
            throw InvalidBroadcastURLError()
        }

        guard let session = try await SessionBuilderFactory.shared.make(url)
            .setMode(.publish)
            .build()
        else {
            throw MissingSessionError()
        }

        await session.setMaxRetryCount(0)

        self.session = session
        self.readyStateTask = Task {
            for await readyState in await session.readyState {
                let description = switch readyState {
                case .connecting:
                    "Connecting..."
                case .open:
                    "Open"
                case .closing:
                    "Closing..."
                case .closed:
                    "Closed"
                }

                log.info("RTMP connection status: \(description)")
            }
        }
    }

    func stream() async -> any StreamConvertible {
        await session.stream
    }

    func connect(disconnected: @Sendable @escaping () -> Void) async throws {
        try await session.connect(disconnected)
    }

    func close() async throws {
        readyStateTask.cancel()
        try await session.close()
    }
}
