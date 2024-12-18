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
import SwiftUI
import ScreenCaptureKit
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
