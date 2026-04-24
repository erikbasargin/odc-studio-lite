//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import HaishinKit
import OSLog
import VideoToolbox

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastSession")

actor BroadcastSession: Equatable {

    struct PublishConfiguration {
        let videoSettings: VideoCodecSettings

        static let `default` = Self(
            videoSettings: VideoCodecSettings(
                videoSize: .init(width: 1920, height: 1080),
                bitRate: 6000 * 1000,
                profileLevel: kVTProfileLevel_H264_High_AutoLevel as String,
                bitRateMode: .constant,
                allowFrameReordering: false
            )
        )
    }

    struct InvalidBroadcastURLError: Error {}
    struct MissingSessionError: Error {}

    private let streamProvider: @Sendable () async -> any StreamConvertible
    private let connectHandler: @Sendable (@escaping @Sendable () -> Void) async throws -> Void
    private let closeHandler: @Sendable () async throws -> Void
    private let readyStateTask: Task<Void, Never>?

    init(
        primaryStreamKey: String,
        publishConfiguration: PublishConfiguration = .default
    ) async throws {
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
        let stream = await session.stream
        try await stream.setVideoSettings(publishConfiguration.videoSettings)

        let readyStateTask = Task {
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

        self.streamProvider = {
            await session.stream
        }
        self.connectHandler = { disconnected in
            try await session.connect(disconnected)
        }
        self.closeHandler = {
            try await session.close()
        }
        self.readyStateTask = readyStateTask
    }

    init(
        stream: @escaping @Sendable () async -> any StreamConvertible = {
            fatalError("Test BroadcastSession cannot provide a stream")
        },
        connect: @escaping @Sendable (@escaping @Sendable () -> Void) async throws -> Void = { _ in },
        close: @escaping @Sendable () async throws -> Void = {}
    ) {
        self.streamProvider = stream
        self.connectHandler = connect
        self.closeHandler = close
        self.readyStateTask = nil
    }

    func stream() async -> any StreamConvertible {
        await streamProvider()
    }

    func connect(disconnected: @Sendable @escaping () -> Void) async throws {
        try await connectHandler(disconnected)
    }

    func close() async throws {
        readyStateTask?.cancel()
        try await closeHandler()
    }

    nonisolated static func == (lhs: BroadcastSession, rhs: BroadcastSession) -> Bool {
        lhs === rhs
    }
}
