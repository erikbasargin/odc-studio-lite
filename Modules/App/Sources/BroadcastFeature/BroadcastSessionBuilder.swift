//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import HaishinKit
import RTMPHaishinKit

struct BroadcastSessionBuilder: Sendable {
    
    static func configure() async {
        await SessionBuilderFactory.shared.register(RTMPSessionFactory())
    }

    var makeBroadcastSession: @Sendable (String, BroadcastSession.PublishConfiguration) async throws -> BroadcastSession
}

extension BroadcastSessionBuilder: DependencyKey {
    
    static let liveValue = Self { primaryStreamKey, publishConfiguration in
        try await BroadcastSession(
            primaryStreamKey: primaryStreamKey,
            publishConfiguration: publishConfiguration
        )
    }
    
    static let testValue = Self { _, _ in
        BroadcastSession()
    }
}

extension DependencyValues {
    var broadcastSessionBuilder: BroadcastSessionBuilder {
        get { self[BroadcastSessionBuilder.self] }
        set { self[BroadcastSessionBuilder.self] = newValue }
    }
}

