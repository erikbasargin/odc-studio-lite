//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
@preconcurrency import ScreenCaptureKit
import Shared

@Reducer
struct SettingsFeature {
    
    @ObservableState
    struct State: Equatable {
        struct ContentSharingPickerConfiguration: Equatable, Sendable {
            var allowedPickerModes: AllowedPickerModes = [.singleDisplay]
            var allowsChangingSelectedContent = true
            
            struct AllowedPickerModes: OptionSet, Equatable, Sendable {
                let rawValue: Int
                
                static let singleWindow = Self(rawValue: 1 << 0)
                static let singleApplication = Self(rawValue: 1 << 1)
                static let singleDisplay = Self(rawValue: 1 << 2)
            }
        }
        
        var primaryStreamKey = ""
        var contentSharingPickerConfiguration = ContentSharingPickerConfiguration()
        var contentSharingPickerIsActive = true
    }
    
    enum Action: Equatable {
        case bootstrap
        case primaryStreamKeyLoaded(String)
        case primaryStreamKeyChanged(String)
    }
    
    @Dependency(\.contentSharingPickerClient) private var contentSharingPickerClient
    @Dependency(\.twitchPrimaryKeyStorage) private var twitchPrimaryKeyStorage
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .bootstrap:
                let configuration = state.contentSharingPickerConfiguration
                let isActive = state.contentSharingPickerIsActive
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
