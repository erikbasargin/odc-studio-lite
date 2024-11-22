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

/**
 An `AppShortcut` wraps an intent to make it automatically discoverable throughout the system. An `AppShortcutsProvider` manages the shortcuts the app
 makes available. The app can update the available shortcuts by calling `updateAppShortcutParameters()` as needed.
 */
class ODCLiteShortcuts: AppShortcutsProvider {
    
    /// The color the system uses to display the App Shortcuts in the Shortcuts app.
    static let shortcutTileColor = ShortcutTileColor.purple
    
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartCapturingMicrophone(), phrases: [
            "Start capturing microphone in \(.applicationName)",
            "Start capturing microphone",
            "Broadcast my voice",
            "Start broadcasting my voice",
        ],
        shortTitle: "Start capturing microphone",
        systemImageName: "speaker.fill")
        
        AppShortcut(intent: StopCapturingMicrophone(), phrases: [
            "Stop capturing microphone in \(.applicationName)",
            "Stop capturing microphone",
            "Do not capture microphone",
            "Stop broadcasting my voice",
        ],
        shortTitle: "Stop capturing microphone",
        systemImageName: "speaker.slash.fill")
    }
}
