//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import HaishinKit
import RTMPHaishinKit

struct BroadcastSessionBuilder {

    static func configure() async {
        await SessionBuilderFactory.shared.register(RTMPSessionFactory())
    }

    func makeBroadcastSession(primaryStreamKey: String) async throws -> BroadcastSession {
        try await BroadcastSession(primaryStreamKey: primaryStreamKey)
    }
}
