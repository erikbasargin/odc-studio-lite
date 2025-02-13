//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
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
