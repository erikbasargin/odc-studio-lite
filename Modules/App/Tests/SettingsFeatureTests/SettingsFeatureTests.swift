import ComposableArchitecture
import Testing

@testable import ODCLite

@Suite
struct SettingsFeatureTests {
    
    @Test
    @MainActor
    func bootstrapConfiguresAndActivatesContentSharingPicker() async {
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
        }
        
        await store.send(.bootstrap)
        await store.finish()
        
        #expect(await probe.configurationCount() == 1)
        #expect(await probe.allowedPickerModes() == [.singleDisplay])
        #expect(await probe.allowsChangingSelectedContent() == true)
        #expect(await probe.recordedIsActiveValues() == [true])
    }
    
    @Test
    @MainActor
    func primaryStreamKeyIsReducerOwned() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        
        await store.send(.primaryStreamKeyChanged("abc123")) {
            $0.primaryStreamKey = "abc123"
        }
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
