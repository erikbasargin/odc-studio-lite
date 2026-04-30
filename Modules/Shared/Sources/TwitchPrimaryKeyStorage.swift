//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import Valet

@DependencyClient
public struct TwitchPrimaryKeyStorage: Sendable {
    public var load: @Sendable () throws -> String?
    public var save: @Sendable (_ primaryKey: String) throws -> Void
    public var remove: @Sendable () throws -> Void
}

extension TwitchPrimaryKeyStorage: TestDependencyKey {
    public static let testValue = Self()
}

extension TwitchPrimaryKeyStorage: DependencyKey {
    
    public static var liveValue: Self {
        let identifier = Identifier(nonEmpty: "com.odclite.twitch")!
        let valet = Valet.valet(with: identifier, accessibility: .whenUnlockedThisDeviceOnly)
        let key = "twitch-primary-stream-key"
        
        return Self(
            load: {
                try valet.string(forKey: key)
            },
            save: { primaryKey in
                try valet.setString(primaryKey, forKey: key)
            },
            remove: {
                try valet.removeObject(forKey: key)
            }
        )
    }
}

public extension DependencyValues {
    var twitchPrimaryKeyStorage: TwitchPrimaryKeyStorage {
        get { self[TwitchPrimaryKeyStorage.self] }
        set { self[TwitchPrimaryKeyStorage.self] = newValue }
    }
}
