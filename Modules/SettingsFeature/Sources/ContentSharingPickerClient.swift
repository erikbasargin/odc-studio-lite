//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import ScreenCaptureKit

public struct ContentSharingPickerClient: Sendable {
    public var setConfiguration: @Sendable (SettingsFeature.State.ContentSharingPickerConfiguration) async -> Void
    public var setIsActive: @Sendable (Bool) async -> Void
    
    public init(
        setConfiguration: @escaping @Sendable (SettingsFeature.State.ContentSharingPickerConfiguration) async -> Void,
        setIsActive: @escaping @Sendable (Bool) async -> Void
    ) {
        self.setConfiguration = setConfiguration
        self.setIsActive = setIsActive
    }
}

extension ContentSharingPickerClient: DependencyKey {
    public static let liveValue = Self(
        setConfiguration: { configuration in
            SCContentSharingPicker.shared.configuration = configuration.makeSystemConfiguration()
        },
        setIsActive: { isActive in
            SCContentSharingPicker.shared.isActive = isActive
        }
    )
    
    public static let testValue = Self(
        setConfiguration: { _ in },
        setIsActive: { _ in }
    )
}

extension DependencyValues {
    public var contentSharingPickerClient: ContentSharingPickerClient {
        get { self[ContentSharingPickerClient.self] }
        set { self[ContentSharingPickerClient.self] = newValue }
    }
}
