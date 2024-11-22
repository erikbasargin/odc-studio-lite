//
//  This source file is part of the ODCLite open source project
//
//  Copyright (c) 2024 Erik Basargin
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AppIntents

struct StartCapturingMicrophone: AppIntent {
    
    static let title: LocalizedStringResource = "Start capturing microphone"
    
    static let description = IntentDescription(
        "Start capturing microphone to broadcast you voice audio to the world",
        categoryName: "Audio control",
        searchKeywords: ["start", "capture", "capturing", "unmute", "audio", "microphone"]
    )
    
    @Dependency
    private var broadcastManager: BroadcastManager
    
    @MainActor
    func perform() async throws -> some IntentResult {
        broadcastManager.captureMicrophone = true
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
    
    @Dependency
    private var broadcastManager: BroadcastManager
    
    @MainActor
    func perform() async throws -> some IntentResult {
        broadcastManager.captureMicrophone = false
        return .result()
    }
}
