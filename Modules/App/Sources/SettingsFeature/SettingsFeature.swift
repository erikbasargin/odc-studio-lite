//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
@preconcurrency import ScreenCaptureKit

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
        case primaryStreamKeyChanged(String)
    }
    
    @Dependency(\.contentSharingPickerClient) private var contentSharingPickerClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .bootstrap:
                let configuration = state.contentSharingPickerConfiguration
                let isActive = state.contentSharingPickerIsActive
                return .run { _ in
                    await contentSharingPickerClient.setConfiguration(configuration)
                    await contentSharingPickerClient.setIsActive(isActive)
                }

            case .primaryStreamKeyChanged(let primaryStreamKey):
                state.primaryStreamKey = primaryStreamKey
                return .none
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
