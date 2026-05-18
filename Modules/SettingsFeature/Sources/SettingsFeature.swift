//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
@preconcurrency import ScreenCaptureKit
import Shared

@Reducer
public struct SettingsFeature {
    
    @ObservableState
    public struct State: Equatable {
        public struct ContentSharingPickerConfiguration: Equatable, Sendable {
            public var allowedPickerModes: AllowedPickerModes = [.singleDisplay]
            public var allowsChangingSelectedContent = true
            
            public struct AllowedPickerModes: OptionSet, Equatable, Sendable {
                public let rawValue: Int
                
                public init(rawValue: Int) {
                    self.rawValue = rawValue
                }
                
                public static let singleWindow = Self(rawValue: 1 << 0)
                public static let singleApplication = Self(rawValue: 1 << 1)
                public static let singleDisplay = Self(rawValue: 1 << 2)
            }
            
            public init(
                allowedPickerModes: AllowedPickerModes = [.singleDisplay],
                allowsChangingSelectedContent: Bool = true
            ) {
                self.allowedPickerModes = allowedPickerModes
                self.allowsChangingSelectedContent = allowsChangingSelectedContent
            }
        }
        
        public var primaryStreamKey = ""
        public var contentSharingPickerConfiguration = ContentSharingPickerConfiguration()
        public var contentSharingPickerIsActive = true
        
        public init(
            primaryStreamKey: String = "",
            contentSharingPickerConfiguration: ContentSharingPickerConfiguration = ContentSharingPickerConfiguration(),
            contentSharingPickerIsActive: Bool = true
        ) {
            self.primaryStreamKey = primaryStreamKey
            self.contentSharingPickerConfiguration = contentSharingPickerConfiguration
            self.contentSharingPickerIsActive = contentSharingPickerIsActive
        }
    }
    
    public enum Action: Equatable {
        case bootstrap
        case primaryStreamKeyLoaded(String)
        case primaryStreamKeyChanged(String)
    }
    
    @Dependency(\.contentSharingPickerClient) private var contentSharingPickerClient
    @Dependency(\.twitchPrimaryKeyStorage) private var twitchPrimaryKeyStorage
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .bootstrap:
                let configuration = state.contentSharingPickerConfiguration
                let isActive = state.contentSharingPickerIsActive
                let contentSharingPickerClient = contentSharingPickerClient
                let twitchPrimaryKeyStorage = twitchPrimaryKeyStorage
                return .merge(
                    .run { _ in
                        await contentSharingPickerClient.setConfiguration(configuration)
                        await contentSharingPickerClient.setIsActive(isActive)
                    },
                    .run { send in
                        guard let primaryStreamKey = try twitchPrimaryKeyStorage.load() else {
                            return
                        }
                        await send(.primaryStreamKeyLoaded(primaryStreamKey))
                    }
                )

            case .primaryStreamKeyLoaded(let primaryStreamKey):
                state.primaryStreamKey = primaryStreamKey
                return .none

            case .primaryStreamKeyChanged(let primaryStreamKey):
                state.primaryStreamKey = primaryStreamKey
                let twitchPrimaryKeyStorage = twitchPrimaryKeyStorage
                return .run { _ in
                    try twitchPrimaryKeyStorage.save(primaryStreamKey)
                }
            }
        }
    }
}

extension SettingsFeature.State.ContentSharingPickerConfiguration {
    func makeSystemConfiguration() -> SCContentSharingPickerConfiguration {
        var configuration = SCContentSharingPickerConfiguration()
        configuration.allowedPickerModes = allowedPickerModes.makeSystemPickerModes()
        configuration.allowsChangingSelectedContent = allowsChangingSelectedContent
        return configuration
    }
}

private extension SettingsFeature.State.ContentSharingPickerConfiguration.AllowedPickerModes {
    func makeSystemPickerModes() -> SCContentSharingPickerMode {
        var modes: SCContentSharingPickerMode = []
        
        if contains(.singleWindow) {
            modes.insert(.singleWindow)
        }
        if contains(.singleApplication) {
            modes.insert(.singleApplication)
        }
        if contains(.singleDisplay) {
            modes.insert(.singleDisplay)
        }
        
        return modes
    }
}
