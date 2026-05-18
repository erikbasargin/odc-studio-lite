import ComposableArchitecture
import Shared
import Synchronization
import Testing

@testable import SettingsFeature

@MainActor
struct SettingsFeatureTests {
    
    @Test func bootstrap() async {
        let probe = ContentSharingPickerClientProbe()
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.contentSharingPickerClient.setConfiguration = { configuration in
                await probe.recordConfiguration(configuration)
            }
            $0.contentSharingPickerClient.setIsActive = { isActive in
                await probe.recordIsActive(isActive)
            }
            $0.twitchPrimaryKeyStorage.load = { "abc123" }
        }
        
        await store.send(.bootstrap)
        await store.receive(.primaryStreamKeyLoaded("abc123")) {
            $0.primaryStreamKey = "abc123"
        }
        await store.finish()
        
        #expect(await probe.configurationCount() == 1)
        #expect(await probe.allowedPickerModes() == [.singleDisplay])
        #expect(await probe.allowsChangingSelectedContent() == true)
        #expect(await probe.recordedIsActiveValues() == [true])
    }
    
    @Test func primaryStreamKeyIsSavedToStorage_givenKeyIsChanged() async {
        let probe = TwitchPrimaryKeyStorageProbe()
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.twitchPrimaryKeyStorage.save = { primaryStreamKey in
                probe.recordSavedPrimaryStreamKey(primaryStreamKey)
            }
        }
        
        await store.send(.primaryStreamKeyChanged("abc123")) {
            $0.primaryStreamKey = "abc123"
        }
        await store.finish()
        
        #expect(probe.savedPrimaryStreamKeys() == ["abc123"])
    }
}

private actor ContentSharingPickerClientProbe {
    private var configurations = 0
    private var lastConfiguration: SettingsFeature.State.ContentSharingPickerConfiguration?
    private var isActiveValues: [Bool] = []
    
    func recordConfiguration(_ configuration: SettingsFeature.State.ContentSharingPickerConfiguration) {
        configurations += 1
        lastConfiguration = configuration
    }
    
    func recordIsActive(_ isActive: Bool) {
        isActiveValues.append(isActive)
    }
    
    func configurationCount() -> Int {
        configurations
    }
    
    func allowedPickerModes() -> SettingsFeature.State.ContentSharingPickerConfiguration.AllowedPickerModes {
        lastConfiguration?.allowedPickerModes ?? []
    }
    
    func allowsChangingSelectedContent() -> Bool {
        lastConfiguration?.allowsChangingSelectedContent ?? false
    }
    
    func recordedIsActiveValues() -> [Bool] {
        isActiveValues
    }
}

private struct TwitchPrimaryKeyStorageProbe: ~Copyable {
    
    private let primaryStreamKeys = Mutex([String]())
    
    func recordSavedPrimaryStreamKey(_ primaryStreamKey: String) {
        primaryStreamKeys.withLock {
            $0.append(primaryStreamKey)
        }
    }
    
    func savedPrimaryStreamKeys() -> [String] {
        primaryStreamKeys.withLock(\.self)
    }
}
