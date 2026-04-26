//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import ScreenCaptureKit

struct ContentSharingPickerClient: Sendable {
    var setConfiguration: @Sendable (SettingsFeature.State.ContentSharingPickerConfiguration) async -> Void
    var setIsActive: @Sendable (Bool) async -> Void
}

extension ContentSharingPickerClient: DependencyKey {
    static let liveValue = Self(
        setConfiguration: { configuration in
            SCContentSharingPicker.shared.configuration = configuration.makeSystemConfiguration()
        },
        setIsActive: { isActive in
            SCContentSharingPicker.shared.isActive = isActive
        }
    )
    
    static let testValue = Self(
        setConfiguration: { _ in },
        setIsActive: { _ in }
    )
}

extension DependencyValues {
    var contentSharingPickerClient: ContentSharingPickerClient {
        get { self[ContentSharingPickerClient.self] }
        set { self[ContentSharingPickerClient.self] = newValue }
    }
}
