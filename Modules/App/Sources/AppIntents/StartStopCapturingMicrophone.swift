//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AppIntents
import ComposableArchitecture

struct StartCapturingMicrophone: AppIntent {
    
    static let title: LocalizedStringResource = "Start capturing microphone"
    
    static let description = IntentDescription(
        "Start capturing microphone to broadcast you voice audio to the world",
        categoryName: "Audio control",
        searchKeywords: ["start", "capture", "capturing", "unmute", "audio", "microphone"]
    )
    
    @AppDependency
    private var store: StoreOf<AppFeature>
    
    @MainActor
    func perform() async throws -> some IntentResult {
        store.send(.microphoneCaptureRequested(true))
        return .result()
    }
}

struct StopCapturingMicrophone: AppIntent {
    
    static let title: LocalizedStringResource = "Stop capturing microphone"
    
    static let description = IntentDescription(
        "Stop capturing microphone to stop broadcasting you voice audio to the world",
        categoryName: "Audio control",
        searchKeywords: ["stop", "uncapture", "uncapturing", "mute", "audio", "microphone"]
    )
    
    @AppDependency
    private var store: StoreOf<AppFeature>
    
    @MainActor
    func perform() async throws -> some IntentResult {
        store.send(.microphoneCaptureRequested(false))
        return .result()
    }
}
