//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import HaishinKit
import RTMPHaishinKit

public struct BroadcastSessionBuilder: Sendable {
    
    static func configure() async {
        await SessionBuilderFactory.shared.register(RTMPSessionFactory())
    }
    
    public var makeBroadcastSession:
        @Sendable (String, BroadcastSession.PublishConfiguration) async throws -> BroadcastSession

    public init(
        makeBroadcastSession:
            @escaping @Sendable (String, BroadcastSession.PublishConfiguration) async throws -> BroadcastSession
    ) {
        self.makeBroadcastSession = makeBroadcastSession
    }
}

extension BroadcastSessionBuilder: DependencyKey {
    
    public static let liveValue = Self { primaryStreamKey, publishConfiguration in
        try await BroadcastSession(
            primaryStreamKey: primaryStreamKey,
            publishConfiguration: publishConfiguration
        )
    }
    
    public static let testValue = Self { _, _ in
        BroadcastSession()
    }
}

public extension DependencyValues {
    var broadcastSessionBuilder: BroadcastSessionBuilder {
        get { self[BroadcastSessionBuilder.self] }
        set { self[BroadcastSessionBuilder.self] = newValue }
    }
}
