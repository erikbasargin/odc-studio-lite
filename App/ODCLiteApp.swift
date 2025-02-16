//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AppIntents
import ScreenCaptureKit
import SwiftUI
import os

#if DEBUG
import Logboard
import HaishinKit
#endif

@main
struct ODCLiteApp: App {
    
    private let broadcastManager: BroadcastManager
    
    init() {
        #if DEBUG
        LBLogger.with(kHaishinKitIdentifier).level = .trace
        #endif
        
        let broadcastManager = BroadcastManager()
        self.broadcastManager = broadcastManager
        
        AppDependencyManager.shared.add(dependency: broadcastManager)
        
        ODCLiteShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            LounchView()
                .environment(broadcastManager)
        }
        
        MenuBarExtra {
            MenuBarExtraContentView()
                .environment(broadcastManager)
        } label: {
            Image(.menuBarExtra)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, broadcastManager.isBroadcasting ? .green : .white)
        }
        
        Settings {
            GeneralSettingsView()
                .frame(width: 830)
                .environment(broadcastManager)
        }
        .windowResizability(.contentSize)
    }
}

private struct LounchView: View {
    
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LaunchView")
    
    @Environment(BroadcastManager.self) var broadcastManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Color.clear
            .task {
                Task.detached {
                    do {
                        try await broadcastManager.configureManager()
                        
                        var initialConfiguration = SCContentSharingPickerConfiguration()
                        initialConfiguration.allowedPickerModes = [.singleDisplay]
                        initialConfiguration.allowsChangingSelectedContent = true
                        SCContentSharingPicker.shared.configuration = initialConfiguration
                        SCContentSharingPicker.shared.isActive = true
                        
                        await broadcastManager.authorizeCamera()
                    } catch {
                        log.error("Failed to launch ODC Lite: \(error.localizedDescription)")
                    }
                }
                
                dismiss()
            }
    }
}
